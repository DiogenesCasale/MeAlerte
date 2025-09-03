import 'package:get/get.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';

class MedicationController extends GetxController {
  // Observables para o estado da UI
  var groupedDoses = <String, List<TodayDose>>{}.obs;
  var allMedications = <Medication>[].obs;
  var filteredMedications = <Medication>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await fetchAllMedications();
      await fetchTodayDoses();
    } catch (e) {
      print('Erro ao inicializar dados: $e');
      isLoading(false);
    }
  }

  // Busca as doses do dia
  Future<void> fetchTodayDoses() async {
    try {
      isLoading(true);
      final doses = await DatabaseController.instance.getTodayDoses();
      groupedDoses.value = doses;
    } finally {
      isLoading(false);
    }
  }

  // Busca todos os medicamentos para o dropdown
  Future<void> fetchAllMedications() async {
    final medications = await DatabaseController.instance.getAllMedications();
    allMedications.assignAll(medications);
    filteredMedications.assignAll(medications);
  }

  // Filtra medicamentos para o search
  void searchMedications(String query) {
    if (query.isEmpty) {
      filteredMedications.assignAll(allMedications);
    } else {
      final filtered = allMedications
          .where((med) => med.nome.toLowerCase().contains(query.toLowerCase()))
          .toList();
      filteredMedications.assignAll(filtered);
    }
  }

  // Adiciona um novo medicamento ao catálogo
  Future<void> addNewMedication(String name, int stock, String? observacao) async {
    final newMed = Medication(
      nome: name, 
      quantidade: stock,
      observacao: observacao,
    );
    await DatabaseController.instance.createMedication(newMed);
    await fetchAllMedications(); // Atualiza a lista para o dropdown
  }

  // Adiciona um novo medicamento agendado
  Future<void> addScheduledMedication(ScheduledMedication scheduledMedication) async {
    await DatabaseController.instance.createScheduledMedication(scheduledMedication);
    await fetchTodayDoses(); // Atualiza a lista de doses do dia
  }

  // Atualiza um medicamento agendado
  Future<void> updateScheduledMedication(ScheduledMedication scheduledMedication) async {
    await DatabaseController.instance.updateScheduledMedication(scheduledMedication);
    await fetchTodayDoses(); // Atualiza a lista de doses do dia
  }

  // Deleta um medicamento agendado
  Future<void> deleteScheduledMedication(int id) async {
    await DatabaseController.instance.deleteScheduledMedication(id);
    await fetchTodayDoses(); // Atualiza a lista de doses do dia
  }

  // Busca todos os medicamentos agendados do banco
  Future<List<ScheduledMedication>> getAllScheduledMedicationsFromDB() async {
    return await DatabaseController.instance.getAllScheduledMedications();
  }
}
