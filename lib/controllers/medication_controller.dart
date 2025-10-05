// ADICIONADO: Import para o TextEditingController
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/models/stock_history_model.dart';
import 'package:app_remedio/utils/profile_helper.dart';

class MedicationController extends GetxController {
  // Instância do controlador de banco de dados
  final _dbController = DatabaseController.instance;

  // Observables para o estado da UI
  var isLoading = true.obs;
  var allMedications = <Medication>[].obs;
  var filteredMedications = <Medication>[].obs;
  var groupedMedications = <String, List<Medication>>{}.obs;

  // ADICIONADO: O controller para o campo de texto da busca
  late TextEditingController searchController;

  // MANTIDO: Este observable já existia e será usado pela View
  var isSearchTextEmpty = true.obs;

  @override
  void onInit() {
    super.onInit();
    // ADICIONADO: Inicializa o searchController e adiciona um listener
    searchController = TextEditingController();
    searchController.addListener(() {
      // Atualiza a flag para mostrar/esconder o botão de limpar
      isSearchTextEmpty.value = searchController.text.isEmpty;
    });

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

  // ADICIONADO: Garante que o controller será descartado para evitar memory leaks
  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    // A lógica de isLoading foi movida para dentro do fetchAllMedications
    // para funcionar também em recarregamentos (após adicionar/editar)
    await fetchAllMedications();
  }

  // --- MÉTODOS DE CONTROLE DA UI ---

  /// Recarrega os medicamentos (útil quando o perfil muda)
  Future<void> reloadMedications() async {
    await fetchAllMedications();
  }

  // ADICIONADO: Método para ser chamado pelo botão 'X' da barra de busca
  void clearSearch() {
    searchController.clear();
    // Chama a busca com valor vazio para resetar a lista
    searchMedications('');
  }

  void searchMedications(String query) {
    if (query.isEmpty) {
      filteredMedications.assignAll(allMedications);
    } else {
      final filtered = allMedications
          .where((med) => med.nome.toLowerCase().contains(query.toLowerCase()))
          .toList();
      filteredMedications.assignAll(filtered);
    }
    _groupMedications(filteredMedications);
  }

  Future<void> fetchAllMedications() async {
    // ALTERADO: Gerenciamento do estado de loading
    isLoading.value = true;
    try {
      final db = await _dbController.database;
      final profileController = Get.find<ProfileController>();

      if (profileController.currentProfile.value == null) {
        print('Nenhum perfil selecionado');
        isLoading.value = false;
        return;
      }

      final result = await db.query(
        'tblMedicamentos',
        orderBy: 'nome ASC',
        where: 'deletado = 0 AND idPerfil = ?',
        whereArgs: [profileController.currentProfile.value!.id],
      );
      final medications = result
          .map((json) => Medication.fromMap(json))
          .toList();

      allMedications.assignAll(medications);
      // Chama a busca com o texto atual para manter o filtro se houver
      searchMedications(searchController.text);
    } catch (e) {
      print("Erro ao buscar medicamentos: $e");
      // Opcional: mostrar um toast de erro para o usuário
    } finally {
      // ALTERADO: Garante que o loading sempre terminará
      isLoading.value = false;
    }
  }

  /// Agrupa uma lista de medicamentos pela primeira letra do nome.
  void _groupMedications(List<Medication> meds) {
    meds.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    final Map<String, List<Medication>> grouped = {};
    for (var med in meds) {
      final firstLetter = med.nome[0].toUpperCase();
      if (grouped[firstLetter] == null) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(med);
    }
    groupedMedications.value = grouped;
  }

  Future<void> addNewMedication(Medication newMedication) async {
    final db = await _dbController.database;
    await db.insert('tblMedicamentos', newMedication.toMap());
    await fetchAllMedications();
  }

  Future<void> updateMedication(Medication updatedMedication) async {
    final db = await _dbController.database;
    await db.update(
      'tblMedicamentos',
      updatedMedication.toMap(),
      where: 'id = ?',
      whereArgs: [updatedMedication.id],
    );
    await fetchAllMedications();
  }

  Future<int> deleteMedication(int id) async {
    final db = await _dbController.database;

    final scheduledMedications = await db.query(
      'tblMedicamentosAgendados',
      where: 'idMedicamento = ? AND deletado = 0',
      whereArgs: [id],
    );

    if (scheduledMedications.isNotEmpty) {
      return 1;
    }

    await db.update(
      'tblMedicamentos',
      {'deletado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchAllMedications();
    return 0;
  }

  Future<Medication?> getMedicationById(int id) async {
    final db = await _dbController.database;
    final result = await db.query(
      'tblMedicamentos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Medication.fromMap(result.first);
    }
    return null;
  }

  Future<void> addStock(int medicationId, int amountToAdd) async {
    final db = await _dbController.database;

    final medication = await getMedicationById(medicationId);
    if (medication == null) {
      throw Exception('Medicamento com ID $medicationId não encontrado.');
    }

    final newStock = medication.estoque + amountToAdd;

    // Atualiza o estoque na tabela principal
    await db.update(
      'tblMedicamentos',
      {
        'estoque': newStock,
        'dataAtualizacao': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [medicationId],
    );

    // NOVO: Cria um registro no histórico de estoque
    final historyEntry = StockHistory(
      medicationId: medicationId,
      profileId: ProfileHelper.currentProfileId,
      type: StockMovementType.entrada,
      quantity: amountToAdd,
      creationDate: DateTime.now(),
    );
    await db.insert('tblEstoqueMedicamento', historyEntry.toMap());

    await fetchAllMedications();
  }

  /// Reduz o estoque do medicamento pela dose tomada
  Future<void> reduceStock(
    int medicationId,
    double doseAmount,
    int takenDoseId,
  ) async {
    final db = await _dbController.database;

    // Busca o medicamento atual
    final medication = await getMedicationById(medicationId);
    if (medication == null) {
      throw Exception('Medicamento não encontrado');
    }

    // Calcula o novo estoque
    final newStock = medication.estoque - doseAmount.toInt();

    // Atualiza o estoque no banco
    await db.update(
      'tblMedicamentos',
      {
        'estoque': newStock,
        'dataAtualizacao': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [medicationId],
    );

    // NOVO: Cria um registro no histórico de estoque
    final historyEntry = StockHistory(
      medicationId: medicationId,
      profileId: ProfileHelper.currentProfileId,
      takenDoseId: takenDoseId, // Vincula à dose tomada
      type: StockMovementType.saida,
      quantity: doseAmount.toInt(),
      creationDate: DateTime.now(),
    );
    await db.insert('tblEstoqueMedicamento', historyEntry.toMap());

    // Atualiza a lista de medicamentos
    await fetchAllMedications();

    // Verifica se o estoque está baixo após a redução
    final isLow = await isLowStock(medicationId);
    if (isLow) {
      final daysRemaining = await getDaysRemaining(medicationId);
      final daysText = daysRemaining < 1
          ? "menos de 1 dia"
          : "${daysRemaining.toStringAsFixed(1)} dias";

      print(
        '⚠️ ALERTA: Estoque baixo do medicamento ${medication.nome}! Restam aproximadamente $daysText de uso.',
      );
    }
  }

  // ADICIONE ESTE NOVO MÉTODO PARA BUSCAR O HISTÓRICO:
  /// Busca o histórico de movimentações de estoque, com filtro opcional por medicamento.
  Future<List<StockHistory>> getStockHistory({int? medicationId}) async {
    final db = await _dbController.database;
    final profileId = ProfileHelper.currentProfileId;

    // Usamos uma query com JOIN para buscar o nome do medicamento junto com o histórico
    String query = '''
    SELECT h.*, m.nome as nomeMedicamento 
    FROM tblEstoqueMedicamento h
    JOIN tblMedicamentos m ON h.idMedicamento = m.id
    WHERE h.deletado = 0 AND h.idPerfil = ?
  ''';

    List<dynamic> args = [profileId];

    if (medicationId != null) {
      query += ' AND h.idMedicamento = ?';
      args.add(medicationId);
    }

    query += ' ORDER BY h.dataCriacao DESC';

    final result = await db.rawQuery(query, args);

    return result.map((map) => StockHistory.fromMap(map)).toList();
  }

  /// Reverte a redução do estoque (quando desmarcar como tomado)
  Future<void> restoreStock(
    int medicationId,
    double doseAmount,
    int takenDoseId,
  ) async {
    final db = await _dbController.database;

    // Busca o medicamento atual
    final medication = await getMedicationById(medicationId);
    if (medication == null) {
      throw Exception('Medicamento não encontrado');
    }

    // Calcula o novo estoque (restaura)
    final newStock = medication.estoque + doseAmount.toInt();

    // Atualiza o estoque no banco
    await db.update(
      'tblMedicamentos',
      {
        'estoque': newStock,
        'dataAtualizacao': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [medicationId],
    );

    await db.update(
      'tblEstoqueMedicamento',
      {'deletado': 1},
      where: 'idDoseTomada = ? AND tipo = ?',
      whereArgs: [takenDoseId, StockMovementType.saida.name],
    );

    // Atualiza a lista de medicamentos
    await fetchAllMedications();
  }

  /// Verifica se um medicamento está com estoque baixo baseado nos agendamentos
  Future<bool> isLowStock(int medicationId, {int daysThreshold = 7}) async {
    final db = await _dbController.database;

    // Busca o medicamento
    final medication = await getMedicationById(medicationId);
    if (medication == null) return false;

    // Busca todos os agendamentos ativos para este medicamento
    final schedulesResult = await db.rawQuery(
      '''
      SELECT dose, intervalo, dataInicio, dataFim, paraSempre
      FROM tblMedicamentosAgendados 
      WHERE idMedicamento = ? AND deletado = 0
    ''',
      [medicationId],
    );

    if (schedulesResult.isEmpty) return false;

    double totalDailyDose = 0;
    final now = DateTime.now();

    for (var schedule in schedulesResult) {
      final dose = schedule['dose'] as double;
      final interval = schedule['intervalo'] as int;
      final startDate = schedule['dataInicio'] != null
          ? DateTime.parse(schedule['dataInicio'] as String)
          : now;
      final endDate = schedule['dataFim'] != null
          ? DateTime.parse(schedule['dataFim'] as String)
          : null;
      final isForever = (schedule['paraSempre'] as int) == 1;

      // Verifica se o agendamento ainda está ativo
      bool isActive = startDate.isBefore(now.add(Duration(days: 1)));
      if (!isForever && endDate != null && endDate.isBefore(now)) {
        isActive = false;
      }

      if (isActive && interval > 0) {
        // Calcula quantas doses por dia
        final dosesPerDay = 24 / interval;
        totalDailyDose += dose * dosesPerDay;
      }
    }

    // Se não há consumo diário, não há risco de acabar
    if (totalDailyDose <= 0) return false;

    // Calcula quantos dias o estoque atual durará
    final daysRemaining = medication.estoque / totalDailyDose;

    return daysRemaining <= daysThreshold;
  }

  /// Calcula quantos dias restam de medicamento baseado no uso atual
  Future<double> getDaysRemaining(int medicationId) async {
    final db = await _dbController.database;

    final medication = await getMedicationById(medicationId);
    if (medication == null) return 0;

    final schedulesResult = await db.rawQuery(
      '''
      SELECT dose, intervalo, dataInicio, dataFim, paraSempre
      FROM tblMedicamentosAgendados 
      WHERE idMedicamento = ? AND deletado = 0
    ''',
      [medicationId],
    );

    if (schedulesResult.isEmpty) return double.infinity;

    double totalDailyDose = 0;
    final now = DateTime.now();

    for (var schedule in schedulesResult) {
      final dose = schedule['dose'] as double;
      final interval = schedule['intervalo'] as int;
      final startDate = schedule['dataInicio'] != null
          ? DateTime.parse(schedule['dataInicio'] as String)
          : now;
      final endDate = schedule['dataFim'] != null
          ? DateTime.parse(schedule['dataFim'] as String)
          : null;
      final isForever = (schedule['paraSempre'] as int) == 1;

      bool isActive = startDate.isBefore(now.add(Duration(days: 1)));
      if (!isForever && endDate != null && endDate.isBefore(now)) {
        isActive = false;
      }

      if (isActive && interval > 0) {
        final dosesPerDay = 24 / interval;
        totalDailyDose += dose * dosesPerDay;
      }
    }

    if (totalDailyDose <= 0) return double.infinity;
    return medication.estoque / totalDailyDose;
  }
}
