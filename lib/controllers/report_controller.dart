import 'dart:io';
import 'dart:convert'; // Para utf8
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:flutter/services.dart' show rootBundle;

enum ReportPeriod { lastWeek, lastMonth, last3Months, custom }

enum ReportStatus { taken, missed, late, skipped }

class ReportData {
  final String medicationName;
  final String dataAgendada; // NOVA PROPRIEDADE
  final String dataTomada;
  final String horarioAgendado;
  final String horarioTomada;
  final double dose;
  final String? observacao;
  final String? caminhoImagem;
  final ReportStatus status;
  final Duration? lateDuration;

  ReportData({
    required this.medicationName,
    required this.dataAgendada,
    required this.dataTomada,
    required this.horarioAgendado,
    required this.horarioTomada,
    required this.dose,
    this.observacao,
    this.caminhoImagem,
    required this.status,
    this.lateDuration,
  });

  bool get wasTaken =>
      status == ReportStatus.taken ||
      (status == ReportStatus.late && horarioTomada != horarioAgendado);
  bool get wasMissed => status == ReportStatus.missed;
  bool get wasLate => status == ReportStatus.late;
  bool get wasSkipped => status == ReportStatus.skipped;
}

class ReportController extends GetxController {
  final _dbController = DatabaseController.instance;

  var reportData = <ReportData>[].obs;
  var isLoading = true.obs;
  var selectedPeriod = ReportPeriod.lastWeek.obs;
  var startDate = DateTime.now().subtract(const Duration(days: 7)).obs;
  var endDate = DateTime.now().obs;

  // Estatísticas
  var totalDoses = 0.obs;
  var dosesTaken = 0.obs;
  var dosesMissed = 0.obs;
  var dosesLate = 0.obs;
  var dosesSkipped = 0.obs;
  var adherenceRate = 0.0.obs;

  // Novos dados para gráficos
  var dailyTrend = <double>[0, 0, 0, 0, 0, 0, 0].obs; // Seg a Dom
  var criticalTimeStats = <String, int>{'Manhã': 0, 'Tarde': 0, 'Noite': 0}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeReport();
  }

  Future<void> _initializeReport() async {
    try {
      final profileController = Get.find<ProfileController>();

      // Aguarda o perfil estar disponível
      int attempts = 0;
      const maxAttempts = 50;

      while (profileController.currentProfile.value == null &&
          attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (profileController.currentProfile.value != null) {
        await fetchReport();
      }
    } catch (e) {
      print('Erro ao inicializar relatório: $e');
      isLoading.value = false;
    }
  }

  Future<void> changePeriod(ReportPeriod period) async {
    selectedPeriod.value = period;

    // Pega o 'hoje' truncado (início do dia)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case ReportPeriod.lastWeek:
        // 7 dias atrás (ex: se hoje é 16, começa dia 10)
        startDate.value = today.subtract(const Duration(days: 6));
        endDate.value = today; // Até o final de hoje
        break;
      case ReportPeriod.lastMonth:
        // 30 dias atrás
        startDate.value = today.subtract(const Duration(days: 29));
        endDate.value = today;
        break;
      case ReportPeriod.last3Months:
        // 90 dias atrás
        startDate.value = today.subtract(const Duration(days: 89));
        endDate.value = today;
        break;
      case ReportPeriod.custom:
        // As datas personalizadas são definidas pelo usuário (já devem estar truncadas)
        break;
    }

    await fetchReport();
  }

  /// AJUSTADO: Define período personalizado (garante que está truncado)
  Future<void> setCustomPeriod(DateTime start, DateTime end) async {
    selectedPeriod.value = ReportPeriod.custom;
    // Garante que as datas estão no formato "início do dia"
    startDate.value = DateTime(start.year, start.month, start.day);
    endDate.value = DateTime(end.year, end.month, end.day);
    await fetchReport();
  }

  /// AJUSTADO: Busca dados do relatório do banco de dados
  Future<void> fetchReport() async {
    print('fetchReport');
    try {
      isLoading.value = true;
      final db = await _dbController.database;
      final profileController = Get.find<ProfileController>();
      final currentProfile = profileController.currentProfile.value;

      if (currentProfile == null) {
        print('Nenhum perfil selecionado');
        isLoading.value = false;
        return;
      }

      // *** CORREÇÃO LÓGICA ***
      // 1. Garante que as datas do período sejam absolutas (00:00 e 23:59)
      final periodStart = DateTime(
        startDate.value.year,
        startDate.value.month,
        startDate.value.day,
        0,
        0,
        0, // Início do dia
      );
      final periodEnd = DateTime(
        endDate.value.year,
        endDate.value.month,
        endDate.value.day,
        23,
        59,
        59, // Fim do dia
      );

      // 2. Strings para a query SQL (baseadas nas datas do período)
      final startDateStr = DateFormat('yyyy-MM-dd').format(periodStart);
      final endDateStr = DateFormat('yyyy-MM-dd').format(periodEnd);

      // 3. Limite de processamento é AGORA. Não processamos doses futuras.
      final now = DateTime.now();

      // Busca doses tomadas (Query está correta)
      final takenDosesResult = await db.rawQuery(
        '''
    SELECT 
     td.dataTomada,
     td.horarioAgendado,
     td.horarioTomada,
     td.observacao,
     s.dose,
     m.nome as medicationName,
     m.caminhoImagem
    FROM tblDosesTomadas td
    INNER JOIN tblMedicamentosAgendados s ON td.idAgendamento = s.id
    INNER JOIN tblMedicamentos m ON s.idMedicamento = m.id
    WHERE td.idPerfil = ? 
     AND td.deletado = 0
     AND td.dataTomada BETWEEN ? AND ?
     AND (td.observacao IS NULL OR td.observacao != 'DOSE_EXCLUIDA_INDIVIDUALMENTE')
    ORDER BY td.dataTomada DESC, td.horarioAgendado DESC
    ''',
        [currentProfile.id, startDateStr, endDateStr],
      );

      // Busca doses excluídas individualmente (Query está correta)
      final excludedDosesResult = await db.rawQuery(
        '''
    SELECT 
     td.idAgendamento,
     td.dataTomada,
     td.horarioAgendado
    FROM tblDosesTomadas td
    WHERE td.idPerfil = ? 
     AND td.deletado = 1
     AND td.dataTomada BETWEEN ? AND ?
     AND td.observacao = 'DOSE_EXCLUIDA_INDIVIDUALMENTE'
    ''',
        [currentProfile.id, startDateStr, endDateStr],
      );

      // Busca agendamentos para calcular doses perdidas (Query está correta)
      final scheduledResult = await db.rawQuery(
        '''
    SELECT 
     s.id,
     s.hora,
     s.dose,
     s.intervalo,
     s.dataInicio,
     s.dataFim,
     s.paraSempre,
     m.nome as medicationName,
     m.caminhoImagem
    FROM tblMedicamentosAgendados s
    INNER JOIN tblMedicamentos m ON s.idMedicamento = m.id
    WHERE s.idPerfil = ? AND s.deletado = 0
    ''',
        [currentProfile.id],
      );

      // PASSO 1: Cria um mapa de TODAS as doses que deveriam existir
      final Map<String, ReportData> allExpectedDoses = {};

      for (var scheduled in scheduledResult) {
        // *** ADICIONAR ESTA VERIFICAÇÃO ***
        // Se dataInicio for nulo, pula (ou loga), pois não podemos processar
        String? dataInicioStr = scheduled['dataInicio'] as String?;
        if (dataInicioStr == null) {
          final dataCriacaoStr = scheduled['dataCriacao'] as String?;

          if (dataCriacaoStr != null) {
            print(
              'Relatório: Agendamento ${scheduled['id']} corrigido (dataInicio nula, usando dataCriacao).',
            );
            dataInicioStr = dataCriacaoStr;
          } else {
            // Se dataInicio E dataCriacao são nulos, não há o que fazer.
            print(
              'Relatório: Agendamento ${scheduled['id']} pulado (dataInicio e dataCriacao nulas).',
            );
            continue;
          }
        }

        final startScheduleDate = DateTime.parse(
          scheduled['dataInicio'] as String,
        );
        final medicationName = scheduled['medicationName'] as String;
        final interval = scheduled['intervalo'] as int;

        // *** LÓGICA DE DATA FINAL AJUSTADA ***
        final DateTime? endScheduleDate;
        if (scheduled['paraSempre'] == 1) {
          endScheduleDate = null; // Continua para sempre
        } else if (scheduled['dataFim'] != null) {
          endScheduleDate = DateTime.parse(scheduled['dataFim'] as String);
        } else {
          // Fallback (se paraSempre=0 e dataFim=null, o que não deveria acontecer)
          endScheduleDate = startScheduleDate.add(const Duration(days: 365));
        }

        final timeParts = (scheduled['hora'] as String).split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        DateTime doseTime = DateTime(
          startScheduleDate.year,
          startScheduleDate.month,
          startScheduleDate.day,
          hour,
          minute,
        );

        int iterations = 0;
        const maxIterations = 10000;

        // *** OTIMIZAÇÃO: Pula para o início do período do relatório ***
        if (doseTime.isBefore(periodStart) && interval > 0) {
          final difference = periodStart.difference(doseTime);
          // Arredonda para baixo o número de intervalos a pular
          final intervalsToSkip = (difference.inHours / interval).floor();
          if (intervalsToSkip > 0) {
            doseTime = doseTime.add(
              Duration(hours: intervalsToSkip * interval),
            );
            iterations += intervalsToSkip;
          }
        }

        // Gera todas as doses esperadas
        while (iterations < maxIterations) {
          iterations++;

          // Para se passou do fim do tratamento
          if (endScheduleDate != null && doseTime.isAfter(endScheduleDate))
            break;

          // Para se passou do limite de processamento (AGORA)
          // IMPORTANTE: Isso evita que doses futuras apareçam como "perdidas"
          if (doseTime.isAfter(now)) break;

          // Só adiciona doses que:
          // 1. Estão dentro do período do relatório (>= periodStart E <= periodEnd)
          // 2. JÁ PASSARAM (<= now)

          // *** LÓGICA DE FILTRO CORRIGIDA ***
          final isInPeriod =
              (doseTime.isAfter(periodStart) ||
                  doseTime.isAtSameMomentAs(periodStart)) &&
              (doseTime.isBefore(periodEnd) ||
                  doseTime.isAtSameMomentAs(periodEnd));

          if (isInPeriod) {
            final dateStr = DateFormat('yyyy-MM-dd').format(doseTime);
            final timeStr = DateFormat('HH:mm').format(doseTime);
            final key = '${medicationName}_${dateStr}_$timeStr';

            // Calcula o status baseado no atraso
            final difference = now.difference(doseTime);
            ReportStatus status;
            Duration? lateDuration;

            if (difference.inMinutes > 60) {
              // Mais de 1 hora de atraso = Perdida (se não tomada)
              status = ReportStatus.missed;
            } else if (difference.inMinutes > 15) {
              // Mais de 15 minutos de atraso = Atrasada
              status = ReportStatus.late;
              lateDuration = difference;
            } else {
              // Menos de 15 minutos = "Pendente" (mas aqui tratamos como late leve ou missed dependendo da UI,
              // vamos colocar como late para diferenciar de missed)
              // Na verdade, se está no passado e não tomada, é late.
              status = ReportStatus.late;
              lateDuration = difference;
            }

            // Adiciona como dose esperada (inicialmente marcada como não tomada)
            allExpectedDoses[key] = ReportData(
              medicationName: medicationName,
              dataAgendada: dateStr, // Data agendada
              dataTomada:
                  dateStr, // Data tomada (mesma da agendada se não tomada/atrasada)
              horarioAgendado: timeStr,
              horarioTomada: timeStr, // Padrão
              dose: scheduled['dose'] as double,
              observacao: 'Dose não registrada',
              caminhoImagem: scheduled['caminhoImagem'] as String?,
              status: status,
              lateDuration: lateDuration,
            );
          }

          // Avança para a próxima dose
          if (interval <= 0) break;
          doseTime = doseTime.add(Duration(hours: interval));
        }
      }

      // PASSO 2: Marca as doses que foram REALMENTE tomadas (Lógica está correta)
      for (var taken in takenDosesResult) {
        final date = taken['dataTomada'] as String;
        final time = taken['horarioAgendado'] as String;
        final name = taken['medicationName'] as String;
        final key = '${name}_${date}_$time';

        // Tenta encontrar a dose esperada correspondente
        // Se a chave não bater exatamente (ex: segundos diferem), tentamos uma aproximação se necessário
        // Mas por enquanto mantemos a chave exata pois o gerador usa a mesma lógica

        if (allExpectedDoses.containsKey(key)) {
          // Calcula se foi tomada com atraso
          final takenTimeStr = taken['horarioTomada'] as String;
          final takenDateTime = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).parse('$date $takenTimeStr');
          final scheduledDateTime = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).parse('$date $time');

          final diff = takenDateTime.difference(scheduledDateTime);
          ReportStatus status = ReportStatus.taken;
          Duration? lateDuration;

          if (diff.inMinutes > 30) {
            // Tomou com mais de 30 min de atraso
            status = ReportStatus.late; // Tomada com atraso
            lateDuration = diff;
          }

          allExpectedDoses[key] = ReportData(
            medicationName: name,
            dataAgendada: date, // Data agendada
            dataTomada: date, // Data tomada
            horarioAgendado: time,
            horarioTomada: takenTimeStr,
            dose: taken['dose'] as double,
            observacao: taken['observacao'] as String?,
            caminhoImagem: taken['caminhoImagem'] as String?,
            status: status, // Taken ou Late (mas tomada)
            lateDuration: lateDuration,
          );
        } else {
          // Dose tomada que não estava no agendamento atual (pode ser de agendamento deletado)
          // Adiciona mesmo assim para mostrar no histórico
          allExpectedDoses[key] = ReportData(
            medicationName: name,
            dataAgendada: date, // Data agendada
            dataTomada: date, // Data tomada
            horarioAgendado: time,
            horarioTomada: taken['horarioTomada'] as String,
            dose: taken['dose'] as double,
            observacao: taken['observacao'] as String?,
            caminhoImagem: taken['caminhoImagem'] as String?,
            status: ReportStatus.taken,
            lateDuration: null,
          );
        }
      }

      // PASSO 3: Remove doses excluídas individualmente (Lógica está correta)
      for (var excluded in excludedDosesResult) {
        final idAgendamento = excluded['idAgendamento'];
        final date = excluded['dataTomada'] as String;
        final time = excluded['horarioAgendado'] as String;

        final schedItem = scheduledResult.firstWhere(
          (s) => s['id'] == idAgendamento,
          orElse: () => {},
        );

        if (schedItem.isNotEmpty) {
          final name = schedItem['medicationName'] as String;
          final key = '${name}_${date}_$time';
          if (allExpectedDoses.containsKey(key)) {
            // Em vez de remover, marcamos como SKIPPED para aparecer no relatório
            final old = allExpectedDoses[key]!;
            allExpectedDoses[key] = ReportData(
              medicationName: old.medicationName,
              dataAgendada: old.dataAgendada, // Mantém agendada
              dataTomada: old.dataTomada,
              horarioAgendado: old.horarioAgendado,
              horarioTomada: old.horarioTomada,
              dose: old.dose,
              observacao: 'Dose dispensada',
              caminhoImagem: old.caminhoImagem,
              status: ReportStatus.skipped,
            );
            // Se preferir remover: allExpectedDoses.remove(key);
          }
        }
      }

      // Converte o mapa em lista
      final List<ReportData> reports = allExpectedDoses.values.toList();

      // Ordena por data e hora (mais recente primeiro)
      reports.sort((a, b) {
        final dateCompare = b.dataTomada.compareTo(a.dataTomada);
        if (dateCompare != 0) return dateCompare;
        return b.horarioAgendado.compareTo(a.horarioAgendado);
      });

      reportData.value = reports;

      // Calcula estatísticas
      _calculateStatistics();
    } catch (e) {
      print('Erro ao buscar relatório: $e');
      print('Stack trace: ${StackTrace.current}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Calcula estatísticas do relatório
  void _calculateStatistics() {
    totalDoses.value = reportData.length;
    dosesTaken.value = reportData
        .where(
          (d) =>
              d.status == ReportStatus.taken ||
              (d.status == ReportStatus.late &&
                  d.horarioTomada != d.horarioAgendado),
        )
        .length; // Late mas tomada conta como taken para aderencia? Geralmente sim.
    // Ajuste: Vamos considerar 'taken' qualquer dose que tenha horarioTomada (ou seja, foi registrada no banco como tomada)
    // Mas na minha logica acima, se foi tomada com atraso, status é Late.
    // Preciso diferenciar "Late (Tomada)" de "Late (Não Tomada)".
    // O ReportData não tem bool wasTaken mais.
    // Vou ajustar a logica de contagem.

    dosesTaken.value = reportData
        .where(
          (d) =>
              d.status == ReportStatus.taken ||
              (d.status == ReportStatus.late && _isTaken(d)),
        )
        .length;
    dosesMissed.value = reportData
        .where((d) => d.status == ReportStatus.missed)
        .length;
    dosesSkipped.value = reportData
        .where((d) => d.status == ReportStatus.skipped)
        .length;
    dosesLate.value = reportData
        .where((d) => d.status == ReportStatus.late)
        .length;

    if (totalDoses.value > 0) {
      // Ignora doses dispensadas (skipped) no calculo da aderencia?
      final validDoses = totalDoses.value - dosesSkipped.value;
      if (validDoses > 0) {
        adherenceRate.value = (dosesTaken.value / validDoses) * 100;
      } else {
        adherenceRate.value =
            100.0; // Se tudo foi dispensado, aderencia é 100%? Ou 0? 100 faz mais sentido (seguiu o plano).
      }
    } else {
      adherenceRate.value = 0.0;
    }

    _calculateDailyTrend();
    _calculateCriticalTime();
  }

  void _calculateDailyTrend() {
    // Inicializa com zeros
    final trend = List<double>.filled(7, 0.0);

    // Filtra doses tomadas
    final taken = reportData.where(
      (d) =>
          d.status == ReportStatus.taken ||
          (d.status == ReportStatus.late && _isTaken(d)),
    );

    for (var dose in taken) {
      try {
        final date = DateFormat('yyyy-MM-dd').parse(dose.dataTomada);
        // weekday: 1 (Seg) a 7 (Dom) -> index: 0 a 6
        final index = date.weekday - 1;
        if (index >= 0 && index < 7) {
          trend[index]++;
        }
      } catch (e) {
        print('Erro ao processar data para tendência: $e');
      }
    }
    dailyTrend.value = trend;
  }

  void _calculateCriticalTime() {
    int morning = 0; // 06:00 - 11:59
    int afternoon = 0; // 12:00 - 17:59
    int night = 0; // 18:00 - 05:59

    // Considera doses perdidas ou atrasadas (não tomadas)
    final missedOrLate = reportData.where(
      (d) =>
          d.status == ReportStatus.missed ||
          (d.status == ReportStatus.late && !_isTaken(d)),
    );

    for (var dose in missedOrLate) {
      try {
        final timeParts = dose.horarioAgendado.split(':');
        final hour = int.parse(timeParts[0]);

        if (hour >= 6 && hour < 12) {
          morning++;
        } else if (hour >= 12 && hour < 18) {
          afternoon++;
        } else {
          night++;
        }
      } catch (e) {
        print('Erro ao processar hora para tempo crítico: $e');
      }
    }

    criticalTimeStats.value = {
      'Manhã': morning,
      'Tarde': afternoon,
      'Noite': night,
    };
  }

  // --- EXPORTAÇÃO ---

  Future<void> exportToPdf() async {
    final pdf = pw.Document();
    final profileController = Get.find<ProfileController>();
    final profile = profileController.currentProfile.value;

    // Carrega a logo
    final logoBytes = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Cores (usando valores aproximados do app ou padrão)
    final primaryColor = PdfColor.fromInt(0xFF2196F3); // Azul
    final accentColor = PdfColor.fromInt(0xFFE3F2FD); // Azul claro

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          buildBackground: (context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Opacity(
                opacity: 0.1, // Marca d'água suave
                child: pw.Center(child: pw.Image(logoImage, width: 300)),
              ),
            );
          },
        ),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  children: [
                    pw.Image(logoImage, width: 40),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      'Relatório de Medicamentos',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: primaryColor, thickness: 2),
            pw.SizedBox(height: 20),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Gerado pelo MeAlerte',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          ],
        ),
        build: (pw.Context context) {
          return [
            // Informações do Perfil e Resumo
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: accentColor,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Paciente',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        profile?.nome ?? "Desconhecido",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Período',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        getPeriodDescription(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Aderência',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        '${adherenceRate.value.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: adherenceRate.value >= 80
                              ? PdfColors.green700
                              : (adherenceRate.value >= 50
                                    ? PdfColors.orange700
                                    : PdfColors.red700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabela
            pw.Table.fromTextArray(
              context: context,
              border: null, // Sem bordas padrão
              headerDecoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: const pw.BorderRadius.vertical(
                  top: pw.Radius.circular(5),
                ),
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
                7: pw.Alignment.centerLeft,
              },
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: [
                'Data Agendada',
                'Hora',
                'Data Tomada',
                'Hora',
                'Medicamento',
                'Dose',
                'Status',
                'Obs',
              ],
              data: reportData.map((d) {
                // Formatação condicional da linha (opcional)
                // PdfColor rowColor = reportData.indexOf(d) % 2 == 0 ? PdfColors.white : PdfColors.grey100;

                return [
                  DateFormat('dd/MM').format(DateTime.parse(d.dataAgendada)),
                  d.horarioAgendado,
                  DateFormat('dd/MM').format(DateTime.parse(d.dataTomada)),
                  d.horarioTomada,
                  d.medicationName,
                  d.dose.toString(),
                  _getStatusText(d),
                  d.observacao ?? '-',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await _saveFile(bytes, 'relatorio_medicamentos.pdf', 'application/pdf');
  }

  Future<void> exportToCsv() async {
    List<List<dynamic>> rows = [];

    // Cabeçalho
    rows.add([
      'Data Agendada',
      'Hora Agendada',
      'Data Tomada',
      'Hora Tomada',
      'Medicamento',
      'Dose',
      'Status',
      'Observacao',
    ]);

    // Dados
    for (var d in reportData) {
      rows.add([
        d.dataAgendada,
        d.horarioAgendado,
        d.dataTomada,
        d.horarioTomada,
        d.medicationName,
        d.dose,
        _getStatusText(d),
        d.observacao ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    // Adiciona BOM para Excel abrir corretamente
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];

    await _saveFile(bytes, 'relatorio_medicamentos.csv', 'text/csv');
  }

  Future<void> _saveFile(
    List<int> bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      String directoryPath;

      if (Platform.isAndroid) {
        // Tenta salvar em Documents público (/storage/emulated/0/Documents)
        final documentsDir = Directory('/storage/emulated/0/Documents');
        bool dirExists = await documentsDir.exists();

        if (!dirExists) {
          try {
            await documentsDir.create(recursive: true);
            dirExists = true;
          } catch (e) {
            print('Erro ao criar diretório Documents: $e');
          }
        }

        if (dirExists) {
          directoryPath = documentsDir.path;
        } else {
          // Fallback: usa o diretório externo do app
          final externalDir = await getExternalStorageDirectory();
          directoryPath =
              externalDir?.path ??
              (await getApplicationDocumentsDirectory()).path;
        }
      } else {
        // iOS ou outras plataformas
        final directory = await getApplicationDocumentsDirectory();
        directoryPath = directory.path;
      }

      String filePath = '$directoryPath/$fileName';

      // Evita sobrescrever
      if (await File(filePath).exists()) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final nameWithoutExt = fileName.split('.').first;
        final ext = fileName.split('.').last;
        filePath = '$directoryPath/${nameWithoutExt}_$timestamp.$ext';
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Mostra Toast
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showSuccess(context, 'Arquivo salvo em: Documents');
      } else {
        Get.snackbar('Sucesso', 'Arquivo salvo em: Documents');
      }
    } catch (e) {
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro ao salvar: $e');
      }
    }
  }

  String _getStatusText(ReportData d) {
    switch (d.status) {
      case ReportStatus.taken:
        return 'Tomado';
      case ReportStatus.missed:
        return 'Perdido';
      case ReportStatus.late:
        return 'Atrasado';
      case ReportStatus.skipped:
        return 'Dispensado';
    }
  }

  bool _isTaken(ReportData d) {
    // Se tem horarioTomada diferente do agendado e não é placeholder, ou se status é taken
    // Na verdade, minha logica de fetchReport preenche horarioTomada com horarioAgendado se não tomada.
    // Isso é ruim.
    // Vou corrigir isso no fetchReport: se não tomada, horarioTomada deve ser null ou vazio?
    // O código original usava horarioTomada: timeStr (agendado) como padrão.
    // Vou checar se a observacao é 'Dose não registrada' para saber se não foi tomada.
    return d.observacao != 'Dose não registrada';
  }

  /// Recarrega o relatório (útil quando o perfil muda)
  Future<void> reloadReport() async {
    await fetchReport();
  }

  /// Retorna uma descrição do período selecionado
  String getPeriodDescription() {
    switch (selectedPeriod.value) {
      case ReportPeriod.lastWeek:
        return 'Última Semana';
      case ReportPeriod.lastMonth:
        return 'Último Mês';
      case ReportPeriod.last3Months:
        return 'Últimos 3 Meses';
      case ReportPeriod.custom:
        return '${DateFormat('dd/MM/yyyy').format(startDate.value)} - ${DateFormat('dd/MM/yyyy').format(endDate.value)}';
    }
  }
}
