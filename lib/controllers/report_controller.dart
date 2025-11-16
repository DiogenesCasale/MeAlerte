import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';

enum ReportPeriod {
  lastWeek,
  lastMonth,
  last3Months,
  custom,
}

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
      
      while (profileController.currentProfile.value == null && attempts < maxAttempts) {
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

  /// Atualiza o período do relatório
  Future<void> changePeriod(ReportPeriod period) async {
    selectedPeriod.value = period;
    
    switch (period) {
      case ReportPeriod.lastWeek:
        startDate.value = DateTime.now().subtract(const Duration(days: 7));
        endDate.value = DateTime.now();
        break;
      case ReportPeriod.lastMonth:
        startDate.value = DateTime.now().subtract(const Duration(days: 30));
        endDate.value = DateTime.now();
        break;
      case ReportPeriod.last3Months:
        startDate.value = DateTime.now().subtract(const Duration(days: 90));
        endDate.value = DateTime.now();
        break;
      case ReportPeriod.custom:
        // As datas personalizadas são definidas pelo usuário
        break;
    }
    
    await fetchReport();
  }

  /// Define período personalizado
  Future<void> setCustomPeriod(DateTime start, DateTime end) async {
    selectedPeriod.value = ReportPeriod.custom;
    startDate.value = start;
    endDate.value = end;
    await fetchReport();
  }

  /// Busca dados do relatório do banco de dados
  Future<void> fetchReport() async {
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

      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate.value);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate.value);

      // Define o range de datas com hora completa (início do dia até fim do dia)
      final periodStart = DateTime(
        startDate.value.year,
        startDate.value.month,
        startDate.value.day,
        0,
        0,
        0,
      );
      final periodEnd = DateTime(
        endDate.value.year,
        endDate.value.month,
        endDate.value.day,
        23,
        59,
        59,
      );
      final now = DateTime.now();
      // Não processa doses futuras
      final effectiveEnd = periodEnd.isAfter(now) ? now : periodEnd;

      // Busca doses tomadas
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

      // Busca doses excluídas individualmente
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

      // Busca agendamentos para calcular doses perdidas
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
      // (expande cada agendamento em múltiplas doses baseado no intervalo)
      final Map<String, ReportData> allExpectedDoses = {};
      
      // Expande cada agendamento em múltiplas doses baseado no intervalo
      for (var scheduled in scheduledResult) {
        if (scheduled['dataInicio'] == null) continue;

        final startScheduleDate = DateTime.parse(scheduled['dataInicio'] as String);
        final medicationName = scheduled['medicationName'] as String;
        final interval = scheduled['intervalo'] as int;
        
        // Define até quando o agendamento é válido
        final endScheduleDate = scheduled['paraSempre'] == 1
            ? effectiveEnd
            : (scheduled['dataFim'] != null
                ? DateTime.parse(scheduled['dataFim'] as String)
                : startScheduleDate.add(const Duration(days: 365)));

        final timeParts = (scheduled['hora'] as String).split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // Começa do primeiro horário do agendamento
        DateTime doseTime = DateTime(
          startScheduleDate.year,
          startScheduleDate.month,
          startScheduleDate.day,
          hour,
          minute,
        );

        int iterations = 0;
        const maxIterations = 10000;
        
        // Gera todas as doses esperadas deste agendamento
        while (iterations < maxIterations) {
          iterations++;
          
          // Para se passou do fim do tratamento
          if (doseTime.isAfter(endScheduleDate)) break;
          
          // Para se passou do período efetivo do relatório
          if (doseTime.isAfter(effectiveEnd)) break;
          
          // Só adiciona doses que:
          // 1. Estão dentro do período do relatório (>= periodStart E <= effectiveEnd)
          // 2. JÁ PASSARAM (< now) - NUNCA adiciona doses futuras
          final isInPeriod = (doseTime.isAfter(periodStart) || doseTime.isAtSameMomentAs(periodStart)) &&
                            (doseTime.isBefore(effectiveEnd) || doseTime.isAtSameMomentAs(effectiveEnd));
          final isPast = doseTime.isBefore(now);
          
          if (isInPeriod && isPast) {
            final dateStr = DateFormat('yyyy-MM-dd').format(doseTime);
            final timeStr = DateFormat('HH:mm').format(doseTime);
            final key = '${medicationName}_${dateStr}_$timeStr';

            // Adiciona como dose esperada (inicialmente marcada como perdida)
            allExpectedDoses[key] = ReportData(
              medicationName: medicationName,
              dataTomada: dateStr,
              horarioAgendado: timeStr,
              horarioTomada: timeStr,
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

      // PASSO 2: Marca as doses que foram REALMENTE tomadas
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

      // Remove doses excluídas individualmente
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
          allExpectedDoses.remove(key);
          print('🚫 Dose excluída: $key');
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

