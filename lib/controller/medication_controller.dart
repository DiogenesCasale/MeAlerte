import 'package:flutter/foundation.dart';
import 'package:me_alerte/misc/database_connection.dart';
import 'package:me_alerte/model/medication_model.dart';
import 'package:me_alerte/repositories/medication_repository.dart';

/// The controller class that manages the state and business logic for medications.
/// It communicates with the MedicationRepository to perform CRUD operations
/// and uses a ValueNotifier to inform the UI about changes.
class MedicationController {
  /// A ValueNotifier that holds the list of medications.
  /// Widgets can listen to this notifier to rebuild when the list changes.
  final ValueNotifier<List<MedicationModel>> medications =
      ValueNotifier<List<MedicationModel>>([]);

  /// The repository that handles data operations with the database.
  late final MedicationRepository _repository;

  /// Constructor for the controller.
  /// It initializes the repository by getting a database instance.
  MedicationController() {
    _initialize();
  }

  /// Asynchronously initializes the repository.
  Future<void> _initialize() async {
    final db = await DatabaseConnection.instance.database;
    _repository = MedicationRepository(db: db);
    // Load the initial list of medications from the database.
    loadMedications();
  }

  /// Retrieves all medications from the repository and updates the state.
  Future<void> loadMedications() async {
    try {
      final medicationList = await _repository.listMedications();
      medications.value = medicationList;
    } catch (e) {
      // In a real app, you should handle this error more gracefully.
      // For example, by showing a message to the user.
      debugPrint("Error loading medications: $e");
    }
  }

  /// Adds a new medication and refreshes the list.
  Future<void> addMedication({
    required String name,
    required int quantity,
    String? description,
  }) async {
    try {
      final newMedication = MedicationModel(
        nome: name,
        quantidade: quantity,
        descricao: description,
      );
      await _repository.createMedication(newMedication);
      // After adding, reload the list to reflect the change in the UI.
      await loadMedications();
    } catch (e) {
      debugPrint("Error adding medication: $e");
    }
  }

  /// Updates an existing medication and refreshes the list.
  Future<void> updateMedication(MedicationModel medication) async {
    try {
      await _repository.updateMedication(medication);
      // After updating, reload the list.
      await loadMedications();
    } catch (e) {
      debugPrint("Error updating medication: $e");
    }
  }

  /// Deletes a medication by its ID and refreshes the list.
  Future<void> deleteMedication(int id) async {
    try {
      await _repository.deleteMedication(id);
      // After deleting, reload the list.
      await loadMedications();
    } catch (e) {
      debugPrint("Error deleting medication: $e");
    }
  }
}
