import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:app_remedio/models/taken_dose_model.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/utils/notification_service.dart';
import 'package:app_remedio/controllers/notification_controller.dart';
import 'package:app_remedio/controllers/settings_controller.dart';

class SchedulesController extends GetxController {
  // Instância do controlador de banco de dados
  final _dbController = DatabaseController.instance;
  final _notificationService = NotificationService();

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
      backfillMissedNotifications();
      await fetchSchedulesForSelectedDate();
    } catch (e) {
      print('Erro ao inicializar dados: $e');
    }
  }

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
    rescheduleAllNotifications();
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

    final takenId = await db.insert('tblDosesTomadas', takenDose.toMap());

    // Reduz o estoque do medicamento
    try {
      final medicationController = Get.find<MedicationController>();
      await medicationController.reduceStock(
        dose.idMedicamento,
        dose.dose,
        takenId,
      );
    } catch (e) {
      print('Erro ao reduzir estoque: $e');
      // Continua mesmo se houver erro na redução do estoque
    }

    await fetchSchedulesForSelectedDate();
    rescheduleNotificationsTaken(dose);
  }

  // Metodo auxiliar para reagendar e cancelar notificações quando for marcado como tomado
  Future<void> rescheduleNotificationsTaken(dose) async {
    await rescheduleAllNotifications(); // Reagenda todas as notificações para garantir consistência que sempre terá notificações
    await _notificationService.cancelMedicationNotifications(
      dose,
    ); // Cancela as notificações específicas deste medicamento que já foi tomado
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
        await medicationController.restoreStock(
          medicationId,
          dose,
          takenDoseId,
        );
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
    rescheduleAllNotifications();
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
    rescheduleAllNotifications();
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
    rescheduleAllNotifications();
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
        s.id, s.idPerfil, s.hora, s.dose, s.intervalo, s.dias, s.dataInicio, s.dataFim, s.paraSempre, s.observacao, s.idMedicamento, s.dataCriacao, s.deletado, s.idAgendamentoPai,
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

          final targetDateEnd = targetDateOnly.add(const Duration(days: 1));

          while (doseTime.isBefore(targetDateEnd)) {
            if (doseTime.year == targetDateOnly.year &&
                doseTime.month == targetDateOnly.month &&
                doseTime.day == targetDateOnly.day) {
              final timeKey = DateFormat('HH:mm').format(doseTime);

              final takenKey = '${scheduled.id}_$timeKey';
              if (excludedDosesSet.contains(takenKey)) {
                // Pula esta dose
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

            if (scheduled.intervalo <= 0) break;
            doseTime = doseTime.add(Duration(hours: scheduled.intervalo));
          }
        } catch (e) {
          print('Erro ao processar medicamento agendado ${scheduled.id}: $e');
        }
      }

      // --- MUDANÇA PRINCIPAL AQUI ---

      // 1. Pega as chaves de horário (ex: "08:00") e ordena com uma lógica customizada
      final sortedKeys = generatedDoses.keys.toList();

      sortedKeys.sort((keyA, keyB) {
        final dosesA = generatedDoses[keyA]!;
        final dosesB = generatedDoses[keyB]!;

        // Um grupo é considerado "concluído" se TODAS as suas doses foram tomadas
        final bool isGroupADone = dosesA.every(
          (d) => d.status == MedicationStatus.taken,
        );
        final bool isGroupBDone = dosesB.every(
          (d) => d.status == MedicationStatus.taken,
        );

        // Critério primário: move os grupos concluídos para o final
        if (isGroupADone && !isGroupBDone) {
          return 1; // Grupo A (concluído) vem DEPOIS do Grupo B
        }
        if (!isGroupADone && isGroupBDone) {
          return -1; // Grupo A (não concluído) vem ANTES do Grupo B
        }

        // Critério secundário: se o status for o mesmo, ordena por horário
        return keyA.compareTo(keyB);
      });

      final sortedMap = <String, List<TodayDose>>{};

      // 2. Itera sobre os horários já na ordem correta
      for (var key in sortedKeys) {
        final dosesForTime = generatedDoses[key]!;

        // 3. Ordena a lista de doses DENTRO de cada horário (para consistência)
        dosesForTime.sort((a, b) {
          final isATaken = a.status == MedicationStatus.taken;
          final isBTaken = b.status == MedicationStatus.taken;

          if (isATaken && !isBTaken) {
            return 1; // 'a' (tomado) vai para o fim
          } else if (!isATaken && isBTaken) {
            return -1; // 'a' (não tomado) vem primeiro
          } else {
            // Se ambos tiverem o mesmo status, ordena por nome
            return a.medicationName.compareTo(b.medicationName);
          }
        });

        sortedMap[key] = dosesForTime;
      }

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
    rescheduleAllNotifications();
  }

  /// Atualiza uma dose específica (dose, observação, etc.)
  Future<void> updateSpecificDose(
    TodayDose originalDose, {
    required double newDose,
    required String? newObservacao,
    required DateTime newDateTime,
  }) async {
    final db = await _dbController.database;
    final profileController = Get.find<ProfileController>();
    final currentProfile = profileController.currentProfile.value;

    if (currentProfile?.id == null) {
      throw Exception('Nenhum perfil selecionado');
    }

    // --- PASSO A: Marcar a dose original como excluída para este dia ---
    // Esta parte já funciona e está correta.
    await deleteSpecificDose(
      originalDose.scheduledMedicationId,
      originalDose.scheduledTime,
    );

    // --- PASSO B: Criar um novo agendamento que representa a exceção ---
    final newScheduleForException = ScheduledMedication(
      idPerfil: originalDose.idPerfil,
      idMedicamento: originalDose.idMedicamento,
      // A hora do novo agendamento é a hora editada
      hora: DateFormat('HH:mm').format(newDateTime),
      dose: newDose,
      // Intervalo 0 para não repetir
      intervalo: 0,
      // Data de início e fim no mesmo dia da exceção
      dataInicio: DateFormat('yyyy-MM-dd').format(newDateTime),
      dataFim: DateFormat('yyyy-MM-dd').format(newDateTime),
      paraSempre: false,
      observacao: newObservacao,
      idAgendamentoPai: originalDose.scheduledMedicationId,
    );

    // Insere o novo agendamento de exceção no banco
    await db.insert(
      'tblMedicamentosAgendados',
      newScheduleForException.toMap(),
    );

    // Atualiza a UI para refletir as mudanças
    await fetchSchedulesForSelectedDate();
    rescheduleAllNotifications();
  }

  /// Obtém detalhes de um agendamento específico
  Future<ScheduledMedication?> getScheduledMedicationById(int id) async {
    final db = await _dbController.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        s.id, s.idPerfil, s.hora, s.dose, s.intervalo, s.dias, s.dataInicio, s.dataFim, s.paraSempre, s.observacao, s.idMedicamento, s.dataCriacao, s.deletado, s.idAgendamentoPai,
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

  /// Cancela TODAS as notificações pendentes e reagenda tudo com base no banco de dados.
  /// Esta é a fonte da verdade para as notificações.
  Future<void> rescheduleAllNotifications() async {
    print('🔄 Iniciando reagendamento global de notificações...');

    // 1. Cancela absolutamente todas as notificações agendadas para começar do zero.
    await _notificationService.cancelAllNotifications();

    // 2. Busca todos os agendamentos ativos no banco de dados.
    final allSchedules = await getAllScheduledFromDB();
    final now = DateTime.now();

    // 3. Itera sobre cada agendamento para calcular e agendar suas doses futuras.
    for (var schedule in allSchedules) {
      // Define um limite para não agendar notificações para sempre (ex: próximos 3 dias)
      final scheduleLimit = now.add(
        const Duration(days: 3),
      ); // Usei 3 dias para evitar estourar o limite de notificações do Android (500 por app)

      // Validações de data (essencial para evitar bugs)
      if (schedule.dataInicio == null) continue;
      final startDate = DateTime.parse(schedule.dataInicio!);
      final endDate = schedule.paraSempre || schedule.dataFim == null
          ? null
          : DateTime.parse(schedule.dataFim!);

      // Calcula a hora da primeira dose do agendamento
      final timeParts = schedule.hora.split(':');
      DateTime nextDoseTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      // Avança a `nextDoseTime` para a primeira ocorrência a partir de AGORA
      while (nextDoseTime.isBefore(now)) {
        if (schedule.intervalo <= 0) break; // Evita loop infinito
        nextDoseTime = nextDoseTime.add(Duration(hours: schedule.intervalo));
      }

      // 4. Agenda as doses futuras até o limite definido
      while (nextDoseTime.isBefore(scheduleLimit)) {
        // Verifica se a dose está dentro do período de tratamento
        if (endDate != null && nextDoseTime.isAfter(endDate)) {
          break; // Interrompe se já passou da data final do tratamento
        }

        // Cria um objeto `TodayDose` para o serviço de notificação
        final futureDose = TodayDose(
          scheduledMedicationId: schedule.id!,
          idMedicamento: schedule.idMedicamento,
          medicationName: schedule.medicationName!,
          dose: schedule.dose,
          scheduledTime: nextDoseTime,
          idPerfil: schedule.idPerfil,
          // O resto dos campos não são essenciais para agendar a notificação
        );

        // Agenda a notificação para esta dose futura
        await _notificationService.scheduleMedicationNotifications(futureDose);

        if (schedule.intervalo <= 0) break; // Evita loop infinito
        nextDoseTime = nextDoseTime.add(Duration(hours: schedule.intervalo));
      }
    }
    print('✅ Reagendamento global de notificações concluído.');
  }

  /// Verifica e salva no banco notificações que foram exibidas mas não tocadas pelo usuário.
  Future<void> backfillMissedNotifications() async {
    print('🔄 Verificando notificações perdidas (backfill)...');
    try {
      final db = await _dbController.database;
      final notificationController = Get.find<NotificationController>();

      // 1. Busca todos os agendamentos ativos
      final allSchedules = await getAllScheduledFromDB();
      if (allSchedules.isEmpty) {
        print('Nenhum agendamento ativo, nenhuma notificação a verificar.');
        return;
      }

      // 2. Pega a lista de notificações que JÁ ESTÃO no banco
      final existingNotifications = await db.query(
        'tblNotificacoes',
        where: 'deletado = 0',
      );

      // 3. Monta um "set" para busca rápida (ex: 'idAgendamento_horarioAgendado')
      final existingKeys = <String>{};
      for (var notif in existingNotifications) {
        existingKeys.add(
          '${notif['idAgendamento']}_${notif['horarioAgendado']}',
        );
      }

      final now = DateTime.now();

      // 4. Itera em cada agendamento para calcular suas doses passadas
      for (var schedule in allSchedules) {
        if (schedule.dataInicio == null) continue;

        final startDate = DateTime.parse(schedule.dataInicio!);
        final timeParts = schedule.hora.split(':');
        DateTime doseTime = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        // Itera sobre os horários das doses desde o início do tratamento ATÉ AGORA
        while (doseTime.isBefore(now)) {
          final horarioAgendado = DateFormat('HH:mm').format(doseTime);
          final key = '${schedule.id}_$horarioAgendado';

          // 5. Se a chave NÃO EXISTE no banco, significa que a notificação foi perdida
          if (!existingKeys.contains(key)) {
            print(
              'INFO: Notificação perdida encontrada para ${schedule.medicationName} às $horarioAgendado. Salvando...',
            );

            final profileController = Get.find<ProfileController>();
            final profile = await profileController.getProfileById(
              schedule.idPerfil,
            );

            // Cria os dados para o lembrete
            final settings = Get.find<SettingsController>();
            final reminderTime = doseTime.subtract(
              Duration(minutes: settings.timeBefore.value),
            );
            if (reminderTime.isBefore(now)) {
              await notificationController.saveNotificationToDatabase(
                idAgendamento: schedule.id,
                horarioAgendado: horarioAgendado,
                titulo: 'Lembrete de Medicamento',
                mensagem:
                    'Olá, ${profile?.nome ?? 'Usuário'}! Está na hora de tomar seu medicamento! Tomar ${schedule.medicationName} (${schedule.dose}) às $horarioAgendado}.',
                idPerfil: schedule.idPerfil,
              );
            }

            // Cria os dados para o alerta de atraso
            final lateTime = doseTime.add(
              Duration(minutes: settings.timeAfter.value),
            );
            if (lateTime.isBefore(now)) {
              await notificationController.saveNotificationToDatabase(
                idAgendamento: schedule.id,
                horarioAgendado: horarioAgendado,
                titulo: 'Medicamento Atrasado',
                mensagem:
                    'Olá, ${profile?.nome ?? 'Usuário'}! Você já tomou seu ${schedule.medicationName} das $horarioAgendado?',
                idPerfil: schedule.idPerfil,
              );
            }
          }

          if (schedule.intervalo <= 0) break;
          doseTime = doseTime.add(Duration(hours: schedule.intervalo));
        }
      }
      print('✅ Verificação de notificações perdidas concluída.');
    } catch (e) {
      print('❌ Erro durante o backfill de notificações: $e');
    }
  }
}
