import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/controllers/notification_controller.dart';
import 'package:app_remedio/views/notifications/notification_list_screen.dart';
import 'package:app_remedio/widgets/profile_selector_widget.dart';

class AppHeaderWidget extends StatelessWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  
  const AppHeaderWidget({
    super.key,
    this.title,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Força rebuild quando perfil ou tema mudam
      final profileController = Get.find<ProfileController>();
      final themeController = Get.find<ThemeController>();
      final notificationController = Get.find<NotificationController>();
      
      // Observa mudanças no perfil e tema
      profileController.currentProfile.value;
      profileController.profiles.length;
      themeController.isDarkMode;
      notificationController.unreadCount.value;

      return Container(
        color: surfaceColor,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: MediaQuery.of(context).padding.top + 16,
          bottom: 8, // Era 16
        ),
        child: Row(
          children: [
            // Botão de voltar (se necessário)
            if (showBackButton) ...[
              IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Get.back(),
              ),
              const SizedBox(width: 8),
            ],
            // Logo
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Título
            Text(
              title ?? 'MeAlerte',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Spacer(),
            // Actions customizadas
            if (actions != null) ...actions!,
            // Botão de notificações (se não há actions customizadas)
            if (actions == null) ...[
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    onPressed: () => Get.to(() => const NotificationListScreen()),
                  ),
                  if (notificationController.unreadCount.value > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationController.unreadCount.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            // Seletor de Perfil - sem const para permitir atualizações
            ProfileSelectorWidget(
              key: ValueKey('profile_selector_${profileController.currentProfile.value?.id}'),
              showName: false,
            ),
          ],
        ),
      );
    });
  }
}
