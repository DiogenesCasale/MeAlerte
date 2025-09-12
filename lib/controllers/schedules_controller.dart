import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:app_remedio/models/taken_dose_model.dart';
import 'package:app_remedio/controllers/profile_controller.dart';

class SchedulesController extends GetxController {
  // Instância do controlador de banco de dados
  final _dbController = DatabaseController.instance;

  // Observables para o estado da UI
  var groupedDoses = <String, List<TodayDose>>{}.obs;
  var allMedications = <Medication>[].obs;
  var filteredMedications = <Medication>[].obs;
  var isLoading = true.obs;
  var selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    // CORREÇÃO: Aguarda o perfil estar carregado antes de inicializar dados
    _waitForProfileAndInitialize();
  }

  /// Aguarda o perfil estar disponível antes de carregar os dados
  Future<void> _waitForProfileAndInitialize() async {
    try {
      // Aguarda o ProfileController estar disponível
      ProfileController? profileController;
      int attempts = 0;
      const maxAttempts = 50; // 5 segundos máximo
      
      while (profileController == null && attempts < maxAttempts) {
        try {
          profileController = Get.find<ProfileController>();
        } catch (e) {
          // Controller ainda não está disponível, aguarda um pouco
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
      }
      
      if (profileController == null) {
        print('ProfileController não encontrado após aguardar');
        return;
      }
      
      // Aguarda até o ProfileController terminar de carregar
      while (profileController.isLoading.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Se há perfil disponível, carrega os dados
      if (profileController.currentProfile.value != null) {
        await _initializeData();
      }
      // Se não há perfil, os dados serão carregados quando um perfil for selecionado
    } catch (e) {
      print('Erro ao aguardar ProfileController: $e');
    }
  }

  Future<void> _initializeData() async {
    try {
      await fetchSchedulesForSelectedDate();
    } catch (e) {
      print('Erro ao inicializar dados: $e');
    }
  }

  // --- MÉTODOS DE CONTROLE DA UI ---

  /// Recarrega os agendamentos (útil quando o perfil muda)
  Future<void> reloadSchedules() async {
    await fetchSchedulesForSelectedDate();
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = date;
    await fetchSchedulesForSelectedDate();
  }

  // --- MÉTODOS DE MANIPULAÇÃO DE DADOS (LÓGICA MOVIDA PARA CÁ) ---

  Future<void> addNewScheduled(ScheduledMedication scheduledMedication) async {
    final db = await _dbController.database;
    await db.insert('tblMedicamentosAgendados', scheduledMedication.toMap());
    await fetchSchedulesForSelectedDate();
  }

  /// Marca uma dose como tomada
  Future<void> markDoseAsTaken(TodayDose dose, {String? observacao}) async {
    final db = await _dbController.database;
    final now = DateTime.now();
    
    final takenDose = TakenDose(
      idAgendamento: dose.scheduledMedicationId,
      dataTomada: DateFormat('yyyy-MM-dd').format(dose.scheduledTime),
      horarioTomada: DateFormat('HH:mm').format(now),
      horarioAgendado: DateFormat('HH:mm').format(dose.scheduledTime),
      idPerfil: dose.idPerfil,
      observacao: observacao,
    );

    await db.insert('tblDosesTomadas', takenDose.toMap());
    await fetchSchedulesForSelectedDate();
  }

  /// Desmarca uma dose como tomada (remove do registro)
  Future<void> unmarkDoseAsTaken(int takenDoseId) async {
    final db = await _dbController.database;
    await db.update(
      'tblDosesTomadas',
      {'deletado': 1, 'dataAtualizacao': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [takenDoseId],
    );
    await fetchSchedulesForSelectedDate();
  }

  /// Calcula o status de uma dose baseado no horário atual
  MedicationStatus _calculateDoseStatus(DateTime scheduledTime, bool hasTakenDose) {
    final now = DateTime.now();
    final scheduledDate = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
    final today = DateTime(now.year, now.month, now.day);
    
    // Se já foi tomada
    if (hasTakenDose) {
      return MedicationStatus.taken;
    }
    
    // Se é de um dia anterior e não foi tomada
    if (scheduledDate.isBefore(today)) {
      return MedicationStatus.missed;
    }
    
    // Se é de hoje
    if (scheduledDate.isAtSameMomentAs(today)) {
      final minutesUntilDose = scheduledTime.difference(now).inMinutes;
      
      // Se já passou do horário (mais de 30 minutos de atraso)
      if (minutesUntilDose < -30) {
        return MedicationStatus.late;
      }
      // Se está próximo (até 30 minutos antes)
      else if (minutesUntilDose <= 30 && minutesUntilDose >= -30) {
        return MedicationStatus.upcoming;
      }
      // Se ainda falta tempo
      else {
        return MedicationStatus.notTaken;
      }
    }
    
    // Se é de um dia futuro
    return MedicationStatus.notTaken;
  }

  Future<void> updateScheduled(ScheduledMedication scheduledMedication) async {
    final db = await _dbController.database;
    await db.update(
      'tblMedicamentosAgendados',
      scheduledMedication.toMap(),
      where: 'id = ?',
      whereArgs: [scheduledMedication.id],
    );
    await fetchSchedulesForSelectedDate();
  }

  Future<void> deleteScheduled(int id) async {
    final db = await _dbController.database;
    await db.update(
      'tblMedicamentosAgendados',
      {'deletado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchSchedulesForSelectedDate(); // Atualiza para a data selecionada
  }

  Future<List<ScheduledMedication>> getAllScheduledFromDB() async {
    final db = await _dbController.database;

    final profileController = Get.find<ProfileController>();


      if (profileController.currentProfile.value == null) {
        print('Nenhum perfil selecionado');
        isLoading.value = false;
        return [];
      }

    //await _dbController.debugPrintTableData(db, 'tblMedicamentosAgendados');
    final result = await db.rawQuery('''
      SELECT 
        s.id, s.idPerfil, s.hora, s.dose, s.intervalo, s.dias, s.dataInicio, s.dataFim, s.paraSempre, s.observacao, s.idMedicamento, s.dataCriacao, s.deletado,
        m.nome as medicationName, m.caminhoImagem as caminhoImagem
      FROM tblMedicamentosAgendados s
      INNER JOIN tblMedicamentos m ON s.idMedicamento = m.id
      WHERE s.deletado = 0 AND s.idPerfil = ?
      ORDER BY s.hora ASC
    ''', [profileController.currentProfile.value!.id]);
    return result
        .map((json) => ScheduledMedication.fromMapWithMedication(json))
        .toList();
  }

  Future<void> fetchSchedulesForSelectedDate() async {
    try {
      isLoading(true);
      final db = await _dbController.database;

      final profileController = Get.find<ProfileController>();

      if (profileController.currentProfile.value == null) {
        print('Nenhum perfil selecionado');
        isLoading.value = false;
        return;
      }

      // Busca todas as doses tomadas para a data selecionada
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final takenDosesResult = await db.rawQuery('''
        SELECT idAgendamento, horarioAgendado, id as takenDoseId
        FROM tblDosesTomadas 
        WHERE dataTomada = ? AND idPerfil = ? AND deletado = 0
      ''', [selectedDateStr, profileController.currentProfile.value!.id]);

      final takenDosesMap = <String, int>{};
      for (var taken in takenDosesResult) {
        final key = '${taken['idAgendamento']}_${taken['horarioAgendado']}';
        takenDosesMap[key] = taken['takenDoseId'] as int;
      }
      
      //await _dbController.debugPrintTableData(db, 'tblMedicamentosAgendados');
      final result = await db.rawQuery('''
        SELECT 
          s.id, s.idPerfil, s.hora, s.dose, s.intervalo, s.dias, s.dataInicio, s.dataFim, s.paraSempre, s.observacao, s.idMedicamento, s.dataCriacao, s.deletado,
          m.nome as medicationName, m.caminhoImagem as caminhoImagem
        FROM tblMedicamentosAgendados s
        INNER JOIN tblMedicamentos m ON s.idMedicamento = m.id
        WHERE s.deletado = 0 AND s.idPerfil = ?
      ''', [profileController.currentProfile.value!.id]);

      final scheduledMedications = result
          .map((json) => ScheduledMedication.fromMapWithMedication(json))
          .toList();
      final generatedDoses = <String, List<TodayDose>>{};
      final targetDateOnly = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
      );

      for (var scheduled in scheduledMedications) {
        // --- Lógica de cálculo das doses (responsabilidade do controller) ---
        try {
          // 1. VERIFICAÇÃO E CORREÇÃO AUTOMÁTICA
          if (scheduled.dataInicio == null) {
            // Se dataInicio for nulo, usa dataCriacao como fallback
            if (scheduled.dataCriacao != null) {
              print(
                '⚠️ Corrigindo dataInicio nula para o agendamento ID: ${scheduled.id}. Usando data de criação.',
              );

              // Passo A: Atualiza o registro no banco de dados
              await db.update(
                'tblMedicamentosAgendados',
                {
                  'dataInicio': scheduled.dataCriacao,
                }, // Define dataInicio = dataCriacao
                where: 'id = ?',
                whereArgs: [scheduled.id],
              );

              // Passo B: Atualiza o objeto local para que o resto do código funcione
              scheduled = scheduled.copyWith(dataInicio: scheduled.dataCriacao);
            } else {
              // Se até a data de criação for nula, não há o que fazer. Pula o registro.
              print(
                '❌ Impossível processar agendamento ID: ${scheduled.id}. dataInicio e dataCriacao são nulos.',
              );
              continue;
            }
          }

          // 2. LÓGICA ORIGINAL (agora mais segura)
          // Neste ponto, temos a garantia de que `scheduled.dataInicio` não é mais nulo.
          final DateTime startDate = DateTime.parse(scheduled.dataInicio!);
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );

          if (targetDateOnly.isBefore(startDateOnly)) {
            continue; // Tratamento ainda não começou
          }

          bool isActive = true;
          if (!scheduled.paraSempre) {
            DateTime endDate;
            if (scheduled.dataFim != null) {
              endDate = DateTime.parse(scheduled.dataFim!);
            } else {
              endDate = startDate.add(Duration(days: scheduled.dias));
            }
            final endDateOnly = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
            );
            if (targetDateOnly.isAfter(endDateOnly)) {
              isActive = false; // Tratamento já terminou
            }
          }

          if (isActive) {
            final timeParts = scheduled.hora.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);

            // Codigo antigo
            // DateTime firstDoseTime = startDateOnly.add(
            //   Duration(hours: hour, minutes: minute),
            // );

            int hoursDifference = targetDateOnly
                .difference(startDateOnly)
                .inHours;

            if (hoursDifference >= 0 &&
                hoursDifference % scheduled.intervalo == 0) {
              // Gera as doses para o dia alvo
              DateTime doseTime = targetDateOnly.add(
                Duration(hours: hour, minutes: minute),
              );
              while (doseTime.day == targetDateOnly.day) {
                final timeKey = DateFormat('HH:mm').format(doseTime);
                
                // Verifica se esta dose foi tomada
                final takenKey = '${scheduled.id}_$timeKey';
                final takenDoseId = takenDosesMap[takenKey];
                final hasTakenDose = takenDoseId != null;
                
                // Calcula o status da dose
                final status = _calculateDoseStatus(doseTime, hasTakenDose);
                
                final todayDose = TodayDose(
                  scheduledMedicationId: scheduled.id!,
                  medicationName: scheduled.medicationName!,
                  dose: scheduled.dose,
                  scheduledTime: doseTime,
                  observacao: scheduled.observacao,
                  idPerfil: scheduled.idPerfil,
                  caminhoImagem: scheduled.caminhoImagem,
                  status: status,
                  takenDoseId: takenDoseId,
                );
                generatedDoses.putIfAbsent(timeKey, () => []).add(todayDose);

                if (scheduled.intervalo == 0) break; // Evita loop infinito
                doseTime = doseTime.add(Duration(hours: scheduled.intervalo));
              }
            }
          }
        } catch (e) {
          print('Erro ao processar medicamento agendado ${scheduled.id}: $e');
        }
      }

      final sortedKeys = generatedDoses.keys.toList()..sort();
      final sortedMap = {for (var k in sortedKeys) k: generatedDoses[k]!};
      groupedDoses.value = sortedMap;
    } finally {
      isLoading(false);
    }
  }
}
