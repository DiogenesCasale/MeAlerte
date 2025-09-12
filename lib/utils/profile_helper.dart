import 'package:get/get.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';
import 'package:app_remedio/models/profile_model.dart';

/// Helper class para gerenciar automaticamente o ID do perfil ativo
/// e garantir que todas as operações usem o perfil correto
class ProfileHelper {
  static ProfileController get _profileController => Get.find<ProfileController>();

  /// Retorna o ID do perfil atualmente ativo
  /// Lança uma exceção se nenhum perfil estiver selecionado
  static int get currentProfileId {
    final currentProfile = _profileController.currentProfile.value;
    if (currentProfile?.id == null) {
      throw Exception('Nenhum perfil ativo encontrado. É necessário selecionar um perfil primeiro.');
    }
    return currentProfile!.id!;
  }

  /// Verifica se existe um perfil ativo
  static bool get hasActiveProfile {
    final currentProfile = _profileController.currentProfile.value;
    return currentProfile?.id != null;
  }

  /// Retorna o perfil ativo atual
  static Profile? get currentProfile {
    return _profileController.currentProfile.value;
  }

  /// Força a atualização dos dados quando o perfil muda
  static void notifyProfileChanged() {
    // Aqui podemos adicionar lógica para notificar outros controllers
    // quando o perfil muda, forçando a recarga dos dados
    _notifyMedicationController();
    _notifySchedulesController();
  }

  /// Notifica o MedicationController sobre a mudança de perfil
  static void _notifyMedicationController() {
    try {
      final medicationController = Get.find<MedicationController>();
      medicationController.reloadMedications();
    } catch (e) {
      // Controller não inicializado ainda
    }
  }

  /// Notifica o SchedulesController sobre a mudança de perfil
  static void _notifySchedulesController() {
    try {
      final schedulesController = Get.find<SchedulesController>();
      schedulesController.reloadSchedules();
    } catch (e) {
      // Controller não inicializado ainda
    }
  }

  /// Executa uma ação apenas se houver um perfil ativo
  /// Mostra um erro se não houver perfil
  static T? executeWithProfile<T>(T Function() action) {
    if (!hasActiveProfile) {
      Get.snackbar(
        'Erro',
        'É necessário selecionar um perfil primeiro.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
    return action();
  }

  /// Wrapper para criar medicamentos com o perfil correto
  static Future<T?> createWithProfile<T>(Future<T> Function(int profileId) createFunction) async {
    if (!hasActiveProfile) {
      Get.snackbar(
        'Erro',
        'É necessário selecionar um perfil primeiro.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
    return await createFunction(currentProfileId);
  }
}
