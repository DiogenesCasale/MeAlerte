import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  final bool showBackButton;
  const SettingsScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton ? IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ) : null,
        title: Text(
          'Configurações',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Seção Aparência
            _buildSectionHeader('Aparência'),
            const SizedBox(height: 12),
            
                        // Card do tema
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Tema do Aplicativo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() => Column(
                      children: AppThemeMode.values.map((mode) => _buildThemeOption(
                        mode,
                        themeController.themeMode.value == mode,
                        () => themeController.setThemeMode(mode),
                      )).toList(),
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Seção Sobre
            _buildSectionHeader('Sobre'),
            const SizedBox(height: 12),
            
                         Container(
               decoration: BoxDecoration(
                 color: surfaceColor,
                 borderRadius: BorderRadius.circular(12),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.1),
                     blurRadius: 10,
                     offset: const Offset(0, 4),
                   ),
                 ],
               ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: 'Versão',
                    subtitle: '0.2.0',
                    onTap: null,
                  ),
                  // Divider(
                  //   height: 1,
                  //   color: Colors.grey.withOpacity(0.2),
                  //   indent: 60,
                  // ),
                  // _buildSettingsTile(
                  //   icon: Icons.privacy_tip_outlined,
                  //   title: 'Política de Privacidade',
                  //   onTap: () {
                  //     // TODO: Implementar
                  //   },
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.6),
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                )
              : null),
      onTap: onTap,
    );
  }

  Widget _buildThemeOption(AppThemeMode mode, bool isSelected, VoidCallback onTap) {
    final themeName = _getThemeDisplayName(mode);
    final themeIcon = _getThemeIcon(mode);
    final themeDescription = _getThemeDescription(mode);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          themeIcon,
          color: isSelected ? primaryColor : textColor.withOpacity(0.7),
          size: 24,
        ),
        title: Text(
          themeName,
          style: TextStyle(
            color: isSelected ? primaryColor : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          themeDescription,
          style: TextStyle(
            color: textColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        trailing: isSelected ? Icon(
          Icons.check_circle,
          color: primaryColor,
          size: 20,
        ) : null,
      ),
    );
  }

  String _getThemeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Tema Claro';
      case AppThemeMode.dark:
        return 'Tema Escuro';
      case AppThemeMode.system:
        return 'Padrão do Sistema';
    }
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.settings_brightness;
    }
  }

  String _getThemeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Sempre usar tema claro';
      case AppThemeMode.dark:
        return 'Sempre usar tema escuro';
      case AppThemeMode.system:
        return 'Seguir configuração do sistema';
    }
  }
} 