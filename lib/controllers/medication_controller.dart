// ADICIONADO: Import para o TextEditingController
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/controllers/profile_controller.dart';

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

      final result = await db.query('tblMedicamentos', orderBy: 'nome ASC', where: 'deletado = 0 AND idPerfil = ?', whereArgs: [profileController.currentProfile.value!.id]);
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

  Future<void> deleteMedication(int id) async {
    final db = await _dbController.database;

    final scheduledMedications = await db.query(
      'tblMedicamentosAgendados',
      where: 'idMedicamento = ? AND deletado = 0',
      whereArgs: [id],
    );

    if (scheduledMedications.isNotEmpty) {
      throw Exception(
        'Não é possível excluir este medicamento pois existem agendamentos vinculados a ele. Exclua ou finalize os agendamentos primeiro.',
      );
    }

    await db.update(
      'tblMedicamentos',
      {'deletado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchAllMedications();
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
}
