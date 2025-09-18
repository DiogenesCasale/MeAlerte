import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/widgets/profile_selector_widget.dart';
import 'package:app_remedio/utils/toast_service.dart';

class AppHeaderWidget extends StatelessWidget {
  const AppHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Força rebuild quando perfil ou tema mudam
      final profileController = Get.find<ProfileController>();
      final themeController = Get.find<ThemeController>();
      
      // Observa mudanças no perfil e tema
      profileController.currentProfile.value;
      profileController.profiles.length;
      themeController.isDarkMode;

      return Container(
        color: surfaceColor,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: MediaQuery.of(context).padding.top + 16,
          bottom: 16,
        ),
        child: Row(
          children: [
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
              'MeAlerte',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Spacer(),
            // Ícone de notificação (futuro)
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: textColor.withValues(alpha: 0.6),
              ),
              onPressed: () {
                final context = Get.overlayContext;
                if (context != null) {
                  ToastService.showInfo(
                    context,
                    'Notificações serão implementadas',
                  );
                }
              },
            ),
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
