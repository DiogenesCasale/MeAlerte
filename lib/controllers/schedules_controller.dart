import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
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

    // Reduz o estoque do medicamento
    try {
      final medicationController = Get.find<MedicationController>();
      await medicationController.reduceStock(dose.idMedicamento, dose.dose);
    } catch (e) {
      print('Erro ao reduzir estoque: $e');
      // Continua mesmo se houver erro na redução do estoque
    }

    await fetchSchedulesForSelectedDate();
  }

  /// Desmarca uma dose como tomada (remove do registro)
  Future<void> unmarkDoseAsTaken(int takenDoseId) async {
    final db = await _dbController.database;

    // Busca os dados da dose tomada antes de deletar para restaurar o estoque
    final takenDoseResult = await db.rawQuery(
      '''
      SELECT td.idAgendamento, s.idMedicamento, s.dose
      FROM tblDosesTomadas td
      INNER JOIN tblMedicamentosAgendados s ON td.idAgendamento = s.id
      WHERE td.id = ? AND td.deletado = 0
    ''',
      [takenDoseId],
    );

    if (takenDoseResult.isNotEmpty) {
      final takenDoseData = takenDoseResult.first;
      final medicationId = takenDoseData['idMedicamento'] as int;
      final dose = takenDoseData['dose'] as double;

      // Restaura o estoque do medicamento
      try {
        final medicationController = Get.find<MedicationController>();
        await medicationController.restoreStock(medicationId, dose);
      } catch (e) {
        print('Erro ao restaurar estoque: $e');
        // Continua mesmo se houver erro na restauração do estoque
      }
    }

    await db.update(
      'tblDosesTomadas',
      {'deletado': 1, 'dataAtualizacao': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [takenDoseId],
    );
    await fetchSchedulesForSelectedDate();
  }

  /// Calcula o status de uma dose baseado no horário atual
  MedicationStatus _calculateDoseStatus(
    DateTime scheduledTime,
    bool hasTakenDose,
  ) {
    final now = DateTime.now();
    final scheduledDate = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
    );
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
    final result = await db.rawQuery(
      '''
      SELECT 
        s.id, s.idPerfil, s.hora, s.dose, s.intervalo, s.dias, s.dataInicio, s.dataFim, s.paraSempre, s.observacao, s.idMedicamento, s.dataCriacao, s.deletado,
        m.nome as medicationName, m.caminhoImagem as caminhoImagem
      FROM tblMedicamentosAgendados s
      INNER JOIN tblMedicamentos m ON s.idMedicamento = m.id
      WHERE s.deletado = 0 AND s.idPerfil = ?
      ORDER BY s.hora ASC
    ''',
      [profileController.currentProfile.value!.id],
    );
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

      // Busca todas as doses tomadas e excluídas para a data selecionada
      final selectedDateStr = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedDate.value);
      final takenDosesResult = await db.rawQuery(
        '''
        SELECT idAgendamento, horarioAgendado, id as takenDoseId, observacao, deletado
        FROM tblDosesTomadas 
        WHERE dataTomada = ? AND idPerfil = ?
      ''',
        [selectedDateStr, profileController.currentProfile.value!.id],
      );

      final takenDosesMap = <String, int>{};
      final excludedDosesSet = <String>{};

      for (var taken in takenDosesResult) {
        final key = '${taken['idAgendamento']}_${taken['horarioAgendado']}';
        final isDeleted = (taken['deletado'] as int) == 1;
        final observation = taken['observacao'] as String?;

        if (isDeleted && observation == 'DOSE_EXCLUIDA_INDIVIDUALMENTE') {
          // Esta dose foi excluída individualmente
          excludedDosesSet.add(key);
        } else if (!isDeleted) {
          // Esta dose foi tomada normalmente
          takenDosesMap[key] = taken['takenDoseId'] as int;
        }
      }

      //await _dbController.debugPrintTableData(db, 'tblMedicamentosAgendados');
      final result = await db.rawQuery(
        '''
        SELECT 
          s.id, s.idPerfil, s.hora, s.dose, s.intervalo, s.dias, s.dataInicio, s.dataFim, s.paraSempre, s.observacao, s.idMedicamento, s.dataCriacao, s.deletado,
          m.nome as medicationName, m.caminhoImagem as caminhoImagem
        FROM tblMedicamentosAgendados s
        INNER JOIN tblMedicamentos m ON s.idMedicamento = m.id
        WHERE s.deletado = 0 AND s.idPerfil = ?
      ''',
        [profileController.currentProfile.value!.id],
      );

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
          // Define a data de início e fim do tratamento
          final DateTime startDate = DateTime.parse(scheduled.dataInicio!);
          final DateTime? endDate = scheduled.paraSempre
              ? null
              : (scheduled.dataFim != null
                    ? DateTime.parse(scheduled.dataFim!)
                    : startDate.add(Duration(days: scheduled.dias)));

          // Ignora se o dia selecionado for antes do início do tratamento
          if (targetDateOnly.isBefore(
            DateTime(startDate.year, startDate.month, startDate.day),
          )) {
            continue;
          }

          // Ignora se o dia selecionado for depois do fim do tratamento
          if (endDate != null &&
              targetDateOnly.isAfter(
                DateTime(endDate.year, endDate.month, endDate.day),
              )) {
            continue;
          }

          // Calcula a hora da primeira dose
          final timeParts = scheduled.hora.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          DateTime doseTime = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
            hour,
            minute,
          );

          // Define o fim do dia alvo para o loop
          final targetDateEnd = targetDateOnly.add(const Duration(days: 1));

          // Loop para encontrar as doses que caem no dia selecionado
          while (doseTime.isBefore(targetDateEnd)) {
            // Verifica se a dose calculada está no dia alvo
            if (doseTime.year == targetDateOnly.year &&
                doseTime.month == targetDateOnly.month &&
                doseTime.day == targetDateOnly.day) {
              // A dose está no dia, então vamos adicioná-la
              final timeKey = DateFormat('HH:mm').format(doseTime);

              final takenKey = '${scheduled.id}_$timeKey';
              if (excludedDosesSet.contains(takenKey)) {
                // Pula esta dose, pois foi excluída individualmente
              } else {
                final takenDoseId = takenDosesMap[takenKey];
                final hasTakenDose = takenDoseId != null;
                final status = _calculateDoseStatus(doseTime, hasTakenDose);

                final todayDose = TodayDose(
                  scheduledMedicationId: scheduled.id!,
                  idMedicamento: scheduled.idMedicamento,
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
              }
            }

            // Prepara para a próxima iteração
            if (scheduled.intervalo <= 0) break; // Evita loop infinito
            doseTime = doseTime.add(Duration(hours: scheduled.intervalo));
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

  /// Exclui uma dose específica de um dia específico (cria uma exceção)
  Future<void> deleteSpecificDose(
    int scheduledMedicationId,
    DateTime doseDateTime,
  ) async {
    final db = await _dbController.database;

    final profileController = Get.find<ProfileController>();
    final currentProfile = profileController.currentProfile.value;

    if (currentProfile?.id == null) {
      throw Exception('Nenhum perfil selecionado');
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(doseDateTime);
    final timeStr = DateFormat('HH:mm').format(doseDateTime);

    // Verifica se já existe um registro de dose tomada para este horário
    final existingDose = await db.rawQuery(
      '''
      SELECT id FROM tblDosesTomadas 
      WHERE idAgendamento = ? AND dataTomada = ? AND horarioAgendado = ? AND deletado = 0
    ''',
      [scheduledMedicationId, dateStr, timeStr],
    );

    if (existingDose.isNotEmpty) {
      // Se existe, marca como deletado (significa que foi "pulada"/excluída)
      await db.update(
        'tblDosesTomadas',
        {
          'observacao': 'DOSE_EXCLUIDA_INDIVIDUALMENTE',
          'deletado': 1,
          'dataAtualizacao': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existingDose.first['id']],
      );
    } else {
      // Se não existe, cria um registro especial que marca esta dose como "pulada"
      await db.insert('tblDosesTomadas', {
        'idAgendamento': scheduledMedicationId,
        'dataTomada': dateStr,
        'horarioTomada': timeStr,
        'horarioAgendado': timeStr,
        'idPerfil': currentProfile!.id,
        'observacao': 'DOSE_EXCLUIDA_INDIVIDUALMENTE',
        'deletado': 1, // Marca como deletado/pulado
        'dataCriacao': DateTime.now().toIso8601String(),
        'dataAtualizacao': DateTime.now().toIso8601String(),
      });
    }

    await fetchSchedulesForSelectedDate();
  }

  /// Atualiza uma dose específica (dose, observação, etc.)
  Future<void> updateSpecificDose(
    TodayDose dose, {
    double? newDose,
    String? newObservacao,
    DateTime? newTime,
  }) async {
    final db = await _dbController.database;

    final profileController = Get.find<ProfileController>();
    final currentProfile = profileController.currentProfile.value;

    if (currentProfile?.id == null) {
      throw Exception('Nenhum perfil selecionado');
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(dose.scheduledTime);
    final originalTimeStr = DateFormat('HH:mm').format(dose.scheduledTime);
    final newTimeStr = newTime != null
        ? DateFormat('HH:mm').format(newTime)
        : originalTimeStr;

    // Primeiro, marcar a dose original como "excluída" para este dia específico
    await deleteSpecificDose(dose.scheduledMedicationId, dose.scheduledTime);

    // Depois, criar um registro de dose "tomada" com os novos valores
    // Isso substitui efetivamente a dose original para este dia específico
    await db.insert('tblDosesTomadas', {
      'idAgendamento': dose.scheduledMedicationId,
      'dataTomada': dateStr,
      'horarioTomada': newTimeStr,
      'horarioAgendado': originalTimeStr,
      'idPerfil': currentProfile!.id,
      'observacao':
          'DOSE_EDITADA: ${newDose ?? dose.dose} - ${newObservacao ?? dose.observacao ?? ''}',
      'deletado': 0, // Esta é uma dose "real" editada
      'dataCriacao': DateTime.now().toIso8601String(),
      'dataAtualizacao': DateTime.now().toIso8601String(),
    });

    await fetchSchedulesForSelectedDate();
  }

  /// Obtém detalhes de um agendamento específico
  Future<ScheduledMedication?> getScheduledMedicationById(int id) async {
    final db = await _dbController.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        s.id, s.idPerfil, s.hora, s.dose, s.intervalo, s.dias, s.dataInicio, s.dataFim, s.paraSempre, s.observacao, s.idMedicamento, s.dataCriacao, s.deletado,
        m.nome as medicationName, m.caminhoImagem as caminhoImagem
      FROM tblMedicamentosAgendados s
      INNER JOIN tblMedicamentos m ON s.idMedicamento = m.id
      WHERE s.id = ? AND s.deletado = 0
    ''',
      [id],
    );

    if (result.isNotEmpty) {
      return ScheduledMedication.fromMapWithMedication(result.first);
    }
    return null;
  }
}
