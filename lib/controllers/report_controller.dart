import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';

enum ReportPeriod { lastWeek, lastMonth, last3Months, custom }

class ReportData {
  final String medicationName;
  final String dataTomada;
  final String horarioAgendado;
  final String horarioTomada;
  final double dose;
  final String? observacao;
  final String? caminhoImagem;
  final bool wasTaken;
  final bool wasMissed;

  ReportData({
    required this.medicationName,
    required this.dataTomada,
    required this.horarioAgendado,
    required this.horarioTomada,
    required this.dose,
    this.observacao,
    this.caminhoImagem,
    required this.wasTaken,
    required this.wasMissed,
  });
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
  var adherenceRate = 0.0.obs;

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
     AND td.observacao != 'DOSE_EXCLUIDA_INDIVIDUALMENTE'
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

          // doseTime.isBefore(now) já é garantido pelo 'break' acima

          if (isInPeriod) {
            final dateStr = DateFormat('yyyy-MM-dd').format(doseTime);
            final timeStr = DateFormat('HH:mm').format(doseTime);
            final key = '${medicationName}_${dateStr}_$timeStr';

            // Adiciona como dose esperada (inicialmente marcada como perdida)
            allExpectedDoses[key] = ReportData(
              medicationName: medicationName,
              dataTomada: dateStr,
              horarioAgendado: timeStr,
              horarioTomada: timeStr, // Padrão
              dose: scheduled['dose'] as double,
              observacao: 'Dose não tomada',
              caminhoImagem: scheduled['caminhoImagem'] as String?,
              wasTaken: false,
              wasMissed: true,
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

        // Se esta dose estava esperada, marca como tomada
        if (allExpectedDoses.containsKey(key)) {
          allExpectedDoses[key] = ReportData(
            medicationName: name,
            dataTomada: date,
            horarioAgendado: time,
            horarioTomada: taken['horarioTomada'] as String,
            dose: taken['dose'] as double,
            observacao: taken['observacao'] as String?,
            caminhoImagem: taken['caminhoImagem'] as String?,
            wasTaken: true,
            wasMissed: false,
          );
        } else {
          // Dose tomada que não estava no agendamento atual (pode ser de agendamento deletado)
          // Adiciona mesmo assim para mostrar no histórico
          allExpectedDoses[key] = ReportData(
            medicationName: name,
            dataTomada: date,
            horarioAgendado: time,
            horarioTomada: taken['horarioTomada'] as String,
            dose: taken['dose'] as double,
            observacao: taken['observacao'] as String?,
            caminhoImagem: taken['caminhoImagem'] as String?,
            wasTaken: true,
            wasMissed: false,
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
            allExpectedDoses.remove(key);
            print('🚫 Dose excluída: $key');
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
    dosesTaken.value = reportData.where((d) => d.wasTaken).length;
    dosesMissed.value = reportData.where((d) => d.wasMissed).length;

    if (totalDoses.value > 0) {
      adherenceRate.value = (dosesTaken.value / totalDoses.value) * 100;
    } else {
      adherenceRate.value = 0.0;
    }
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
