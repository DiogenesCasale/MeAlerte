import 'package:get/get.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/models/treatment_model.dart';

class MedicationController extends GetxController {
  // Observables para o estado da UI
  var groupedDoses = <String, List<ScheduledDose>>{}.obs;
  var allMedications = <Medication>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchScheduledDoses();
    fetchAllMedications();
  }

  // Busca os agendamentos do dia
  Future<void> fetchScheduledDoses() async {
    try {
      isLoading(true);
      final doses = await DatabaseController.instance.getGroupedScheduledDosesForToday();
      groupedDoses.value = doses;
    } finally {
      isLoading(false);
    }
  }

  // Busca todos os medicamentos para o dropdown
  Future<void> fetchAllMedications() async {
    allMedications.value = await DatabaseController.instance.getAllMedications();
  }

  // Adiciona um novo medicamento ao catálogo
  Future<void> addNewMedication(String name, int stock) async {
    final newMed = Medication(nome: name, quantidadeEstoque: stock);
    await DatabaseController.instance.createMedication(newMed);
    await fetchAllMedications(); // Atualiza a lista para o dropdown
  }

  // Adiciona um novo tratamento
  Future<void> addTreatment(Treatment treatment) async {
    await DatabaseController.instance.createTreatment(treatment);
    await fetchScheduledDoses(); // Atualiza a lista de agendamentos
  }

  // Marca uma dose como tomada
  Future<void> markDoseAsTaken(int treatmentId, DateTime scheduledTime) async {
    await DatabaseController.instance.markDoseAsTaken(treatmentId, scheduledTime);
    await fetchScheduledDoses(); // Atualiza a UI
  }
}
