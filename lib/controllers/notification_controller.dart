import 'package:get/get.dart';
import 'package:app_remedio/models/notification_model.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/utils/toast_service.dart';

class NotificationController extends GetxController {
  final DatabaseController _dbController = DatabaseController.instance;

  // Observables
  var notifications = <NotificationModel>[].obs;
  var isLoading = false.obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    
    // --- ESTE É O PADRÃO REATIVO CORRETO ---
    // 1. Encontramos o ProfileController
    final profileController = Get.find<ProfileController>();

    // 2. Usamos 'ever' para "escutar" a variável currentProfile.
    //    Toda vez que o perfil mudar (de null para um perfil, ou de um para outro),
    //    a função loadNotifications() será chamada automaticamente.
    ever(profileController.currentProfile, (_) {
      print("🔔 Perfil alterado ou carregado. Recarregando notificações.");
      loadNotifications();
    });

    // 3. Chamamos uma vez no início para o caso de o perfil já estar carregado.
    //    Se ainda não estiver, o 'ever' cuidará disso quando carregar.
    loadNotifications();
  }

  /// Carrega todas as notificações do perfil atual
  Future<void> loadNotifications() async {
    try {
      isLoading.value = true;
      final db = await _dbController.database;
      final profileController = Get.find<ProfileController>();

      // Se não houver perfil selecionado, limpa a lista e encerra.
      if (profileController.currentProfile.value == null) {
        notifications.clear();
        unreadCount.value = 0;
        return; // Retorna aqui para evitar erros
      }

      final profileId = profileController.currentProfile.value!.id;
      final notificationsData = await db.query(
        'tblNotificacoes',
        where: 'idPerfil = ? AND deletado = 0',
        whereArgs: [profileId],
        orderBy: 'dataCriacao DESC',
      );

      notifications.value = notificationsData
          .map((data) => NotificationModel.fromMap(data))
          .toList();

      unreadCount.value = notifications.where((n) => !n.lida).length;

    } catch (e) {
      print('❌ Erro ao carregar notificações: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Salva uma notificação no banco de dados e atualiza a UI
  Future<int?> saveNotificationToDatabase({
    required int? idAgendamento,
    required String? horarioAgendado,
    required String titulo,
    required String mensagem,
  }) async {
    try {
      final db = await _dbController.database;
      final profileController = Get.find<ProfileController>();

      if (profileController.currentProfile.value == null) return null;

      int newId = await db.insert('tblNotificacoes', {
        'idPerfil': profileController.currentProfile.value!.id,
        'idAgendamento': idAgendamento,
        'horarioAgendado': horarioAgendado,
        'titulo': titulo,
        'mensagem': mensagem,
        'lida': 0,
        'deletado': 0,
        'dataCriacao': DateTime.now().toIso8601String(),
      });
      
      // Recarrega a lista para a nova notificação aparecer na tela
      await loadNotifications();
      return newId;
    } catch (e) {
      print('❌ Erro ao salvar notificação no banco: $e');
    }
  }

  /// Marca uma notificação como lida e atualiza a UI instantaneamente
  Future<void> markAsRead(int notificationId) async {
    try {
      final db = await _dbController.database;
      await db.update(
        'tblNotificacoes', {'lida': 1},
        where: 'id = ?', whereArgs: [notificationId]
      );

      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(lida: true);
        notifications.refresh(); // Notifica a UI da mudança
        unreadCount.value--;
      }
    } catch (e) {
      print('❌ Erro ao marcar notificação como lida: $e');
    }
  }

  /// Marca uma notificação como não lida e atualiza a UI instantaneamente
  Future<void> markAsUnread(int notificationId) async {
    try {
      final db = await _dbController.database;
      await db.update(
        'tblNotificacoes', {'lida': 0},
        where: 'id = ?', whereArgs: [notificationId]
      );
      
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(lida: false);
        notifications.refresh();
        unreadCount.value++;
      }
    } catch (e) {
      print('❌ Erro ao marcar como não lida: $e');
    }
  }

  /// Deleta uma notificação e atualiza a UI instantaneamente
  Future<void> deleteNotification(int notificationId) async {
    try {
      final db = await _dbController.database;
      await db.update(
        'tblNotificacoes', {'deletado': 1},
        where: 'id = ?', whereArgs: [notificationId]
      );

      // Remove da lista local para a UI atualizar na hora
      notifications.removeWhere((n) => n.id == notificationId);
      unreadCount.value = notifications.where((n) => !n.lida).length;
    } catch (e) {
      print('❌ Erro ao deletar notificação: $e');
    }
  }
  
  /// Marca todas como lidas e atualiza a UI instantaneamente
  Future<void> markAllAsRead() async {
    try {
      final db = await _dbController.database;
      final profileId = Get.find<ProfileController>().currentProfile.value?.id;
      if (profileId == null) return;
      
      await db.update(
        'tblNotificacoes', {'lida': 1},
        where: 'idPerfil = ? AND lida = 0', whereArgs: [profileId]
      );

      notifications.value = notifications.map((n) => n.copyWith(lida: true)).toList();
      unreadCount.value = 0;
    } catch (e) {
      print('❌ Erro ao marcar todas como lidas: $e');
    }
  }

  /// Limpa notificações antigas e atualiza a UI
  Future<void> cleanOldNotifications() async {
    try {
      final db = await _dbController.database;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      int count = await db.update(
        'tblNotificacoes', {'deletado': 1},
        where: 'dataCriacao < ?', whereArgs: [thirtyDaysAgo.toIso8601String()]
      );

      final context = Get.overlayContext;
      if (context != null) {
        if (count > 0) {
          ToastService.showSuccess(context, '$count notificações antigas foram limpas');
        } else {
          ToastService.showInfo(context, 'Não há notificações antigas para limpar');
        }
      }
      
      // Recarrega a lista para remover as antigas da UI
      await loadNotifications();
    } catch (e) {
      print('❌ Erro ao limpar notificações antigas: $e');
    }
  }

  // Limpa TODAS as notificações (soft delete). Útil para testes.
  Future<void> clearAllNotifications() async {
    try {
      final db = await _dbController.database;
      final profileId = Get.find<ProfileController>().currentProfile.value?.id;
      if (profileId == null) return;
      
      int count = await db.update(
        'tblNotificacoes', {'deletado': 1},
        where: 'idPerfil = ?', whereArgs: [profileId]
      );

      final context = Get.overlayContext;
      if (context != null) {
        if (count > 0) {
          ToastService.showSuccess(context, '$count notificações foram limpas');
        } else {
          ToastService.showInfo(context, 'Não há notificações para limpar');
        }
      }
      
      // Recarrega a lista para a UI ficar vazia
      await loadNotifications();
    } catch (e) {
      print('❌ Erro ao limpar todas as notificações: $e');
    }
  }

}