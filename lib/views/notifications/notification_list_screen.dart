import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/notification_controller.dart';
import 'package:app_remedio/models/notification_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Encontra o controller de notificações e o de tema
    final notificationController = Get.find<NotificationController>();
    
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notificações', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          // Botão para marcar todas como lidas
          Obx(() => notificationController.unreadCount.value > 0 ? IconButton(
            icon: Icon(Icons.mark_email_read_outlined, color: primaryColor),
            onPressed: () => _showMarkAllAsReadDialog(context, notificationController),
            tooltip: 'Marcar todas como lidas',
          ) : const SizedBox.shrink()),
          // Botão para limpar notificações antigas
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: primaryColor),
            onPressed: () => _showCleanOldDialog(context, notificationController),
            tooltip: 'Limpar',
          ),
        ],
      ),
      body: Obx(() {
        // Estado de carregamento
        if (notificationController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        // Estado de lista vazia
        if (notificationController.notifications.isEmpty) {
          return _buildEmptyState();
        }

        // Lista de notificações
        return RefreshIndicator(
          onRefresh: notificationController.loadNotifications,
          color: primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notificationController.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationController.notifications[index];
              return _buildNotificationCard(notification, notificationController);
            },
          ),
        );
      }),
    );
  }

  /// Constrói a tela de estado vazio, quando não há notificações.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma notificação por aqui',
            style: heading2Style.copyWith(
              color: textColor.withOpacity(0.8),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seus lembretes e alertas de medicamentos\naparecerão aqui quando forem enviados.',
            style: bodyTextStyle.copyWith(
              color: textColor.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói o card de uma notificação individual.
  Widget _buildNotificationCard(NotificationModel notification, NotificationController controller) {
    // Determina a cor e o ícone com base no título e se foi lida
    final bool isReminder = notification.titulo.toLowerCase().contains('lembrete');
    final IconData iconData = isReminder ? Icons.alarm : Icons.warning_amber_rounded;
    final Color iconColor = isReminder ? Colors.blueAccent : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        // Adiciona uma borda sutil se a notificação não foi lida
        border: notification.lida
            ? null
            : Border.all(color: primaryColor.withOpacity(0.5), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!notification.lida) {
            controller.markAsRead(notification.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Ícone da notificação
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.lida
                      ? textColor.withOpacity(0.1)
                      : iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  iconData,
                  color: notification.lida
                      ? textColor.withOpacity(0.4)
                      : iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Conteúdo (título, mensagem, data)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.titulo,
                      style: TextStyle(
                        fontWeight: notification.lida ? FontWeight.normal : FontWeight.bold,
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.mensagem,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd/MM/yyyy \'às\' HH:mm').format(notification.dataCriacao),
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Menu de opções (popup)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.6)),
                color: surfaceColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) => _handleMenuAction(value, notification, controller),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: notification.lida ? 'mark_unread' : 'mark_read',
                    child: Row(
                      children: [
                        Icon(
                          notification.lida ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
                          size: 20,
                          color: textColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          notification.lida ? 'Marcar como não lida' : 'Marcar como lida',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gerencia as ações do menu popup.
  void _handleMenuAction(String action, NotificationModel notification, NotificationController controller) {
    switch (action) {
      case 'mark_read':
        controller.markAsRead(notification.id);
        break;
      case 'mark_unread':
        controller.markAsUnread(notification.id);
        break;
      case 'delete':
        _showDeleteDialog(notification, controller);
        break;
    }
  }

  /// Mostra um dialog de confirmação para excluir uma notificação.
  void _showDeleteDialog(NotificationModel notification, NotificationController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Excluir Notificação', style: heading2Style),
        content: Text('Tem certeza que deseja excluir esta notificação?', style: bodyTextStyle),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Fecha o dialog
              controller.deleteNotification(notification.id);
              final context = Get.overlayContext;
              if (context != null) {
                ToastService.showSuccess(context, 'Notificação excluída');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Mostra um dialog para marcar todas as notificações como lidas.
  void _showMarkAllAsReadDialog(BuildContext context, NotificationController controller) {
    final unreadCount = controller.unreadCount.value;
    if (unreadCount == 0) return;

    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Marcar Todas como Lidas', style: heading2Style),
        content: Text('Deseja marcar todas as $unreadCount notificações como lidas?', style: bodyTextStyle),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.markAllAsRead();
              if (context.mounted) {
                ToastService.showSuccess(context, 'Todas as notificações foram marcadas como lidas');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Mostra um dialog para limpar notificações.
  void _showCleanOldDialog(BuildContext context, NotificationController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Limpar Notificações', style: heading2Style),
        content: Text('Deseja excluir todas as notificações?', style: bodyTextStyle),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.clearAllNotifications();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}