import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/notification_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app_remedio/controllers/settings_controller.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'dart:io'; // Para verificar a plataforma (Platform.isAndroid)
import 'package:jbh_ringtone/jbh_ringtone.dart';
import 'package:app_remedio/views/sound_selection_screen.dart';

// <-- MUDANÇA 2: Converter para StatefulWidget
class SettingsScreen extends StatefulWidget {
  final bool showBackButton;
  const SettingsScreen({super.key, this.showBackButton = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Carregando...';
  final settingsController = Get.find<SettingsController>();

  @override
  void initState() {
    super.initState();
    // <-- MUDANÇA 4: Chamar a função para buscar a versão
    _loadVersionInfo();
  }

  // <-- MUDANÇA 5: Função assíncrona para buscar a versão
  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading:
            widget.showBackButton, // <-- MUDANÇA: Usar widget.
        leading: widget.showBackButton
            ? IconButton(
                // <-- MUDANÇA: Usar widget.
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Get.back(),
              )
            : null,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Seção Notificações
            _buildSectionHeader('Notificações'),
            const SizedBox(height: 12),
            _buildNotificationsCard(),
            const SizedBox(height: 32),

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
                    Obx(
                      () => Column(
                        children: AppThemeMode.values
                            .map(
                              (mode) => _buildThemeOption(
                                mode,
                                themeController.themeMode.value == mode,
                                () => themeController.setThemeMode(mode),
                              ),
                            )
                            .toList(),
                      ),
                    ),
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
                    // <-- MUDANÇA 6: Usar a variável de estado
                    subtitle: _appVersion,
                    onTap: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget
    trailing, // Agora o widget final (Switch, Dropdown) é obrigatório
    VoidCallback? onTap,
  }) {
    // Usamos um InkWell e Row para ter controle total do layout e do toque
    return InkWell(
      onTap: onTap,
      child: Padding(
        // Padding interno para cada linha, criando um respiro
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing, // Adiciona o widget final (Switch, Dropdown, etc.)
          ],
        ),
      ),
    );
  }

  // MÉTODO ANTIGO ATUALIZADO: Substitua o seu _buildNotificationsCard por este
  Widget _buildNotificationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        // ALTERAÇÃO 1: Adicionando a sombra que faltava para combinar com os outros cards
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // O ClipRRect garante que o efeito de toque do InkWell respeite as bordas arredondadas
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Obx(() {
          // A visibilidade das opções aninhadas agora é controlada aqui
          final bool areOptionsVisible =
              settingsController.notificationsEnabled.value;

          return Column(
            children: [
              _buildSettingsRow(
                icon: Icons.notifications, // Ícone mais genérico
                title: 'Habilitar Notificações',
                trailing: Switch(
                  value: settingsController.notificationsEnabled.value,
                  onChanged: settingsController.setNotificationsEnabled,
                  activeColor: primaryColor, // Cor do switch ativo
                ),
              ),

              // Anima a aparição e desaparecimento das outras opções
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    if (areOptionsVisible) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: Icons.vibration,
                        title: 'Vibrar',
                        trailing: Switch(
                          value: settingsController.vibrateEnabled.value,
                          onChanged: settingsController.setVibrate,
                          activeColor: primaryColor,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: Icons.music_note,
                        title: 'Som da Notificação',
                        // Exibe o nome do som salvo no controller
                        subtitle:
                            settingsController.notificationSoundTitle.value,
                        onTap: _pickSound, // Chama o seletor de som ao tocar
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: Icons.alarm,
                        title: 'Lembrar antes',
                        trailing: DropdownButton<int>(
                          value: settingsController.timeBefore.value,
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10 min')),
                            DropdownMenuItem(value: 15, child: Text('15 min')),
                            DropdownMenuItem(value: 30, child: Text('30 min')),
                            DropdownMenuItem(value: 60, child: Text('1 hora')),
                          ],
                          onChanged: (v) =>
                              settingsController.setTimeBefore(v!),
                          underline: const SizedBox.shrink(),
                          style: TextStyle(color: textColor, fontSize: 15),
                          dropdownColor: surfaceColor,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: Icons.history,
                        title: 'Lembrar após (atraso)',
                        trailing: DropdownButton<int>(
                          value: settingsController.timeAfter.value,
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10 min')),
                            DropdownMenuItem(value: 15, child: Text('15 min')),
                            DropdownMenuItem(value: 30, child: Text('30 min')),
                            DropdownMenuItem(value: 60, child: Text('1 hora')),
                          ],
                          onChanged: (v) => settingsController.setTimeAfter(v!),
                          underline: const SizedBox.shrink(),
                          style: TextStyle(color: textColor, fontSize: 15),
                          dropdownColor: surfaceColor,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: Icons.send_to_mobile,
                        title: 'Testar Notificação',
                        subtitle: 'Enviar uma notificação de teste',
                        onTap: _testNotification,
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // MÉTODO: Testar notificação
  void _testNotification() async {
    try {
      final notificationService = NotificationService();
      await notificationService.testNotification();

      ToastService.showSuccess(
        context,
        'Notificação de teste enviada! Verifique se ela apareceu.',
      );
    } catch (e) {
      ToastService.showError(
        context,
        'Erro ao enviar notificação de teste: $e',
      );
    }
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
        child: Icon(icon, color: primaryColor, size: 20),
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
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: Colors.grey)
              : null),
      onTap: onTap,
    );
  }

  Future<void> _pickSound() async {
    // Para Android, abrimos nossa tela de seleção personalizada
    if (Platform.isAndroid) {
      // Paramos qualquer som que possa estar tocando antes de navegar
      JbhRingtone().stopRingtone();

      // Navega para a tela de seleção e aguarda um resultado
      final result = await Get.to<JbhRingtoneModel>(
        () => SoundSelectionScreen(
          // Passa a URI atual para que a tela saiba qual som está selecionado
          currentSoundUri: settingsController.notificationSoundUri.value,
        ),
      );

      // 'result' será o JbhRingtoneModel selecionado ou null se o usuário voltou sem escolher
      if (result != null) {
        print('🔔 Som selecionado: ${result.title}, URI: ${result.uri}');
        // Atualiza o som no seu controller com a URI e o TÍTULO real do som!
        settingsController.setNotificationSound(
          result.uri.toString(),
          result.title,
        );
        if (mounted) {
          ToastService.showSuccess(context, 'Som de notificação atualizado!');
        }
      } else {
        print('🔔 Seleção de som cancelada.');
      }
    } else if (Platform.isIOS) {
      // A lógica para iOS (que não tem seletor) continua a mesma
      // Você pode manter o diálogo que já tinha
      Get.dialog(
        AlertDialog(
          backgroundColor: surfaceColor,
          title: Text('Som da Notificação', style: heading2Style),
          content: Text(
            'No iOS, você pode usar o som padrão do aplicativo ou desativar o som para esta notificação.',
            style: bodyTextStyle,
          ),
          actions: [
            TextButton(
              child: Text('Padrão', style: TextStyle(color: primaryColor)),
              onPressed: () {
                settingsController.setNotificationSound(null, 'Padrão');
                Get.back();
              },
            ),
            TextButton(
              child: Text('Silencioso', style: TextStyle(color: textColor)),
              onPressed: () {
                settingsController.setNotificationSound('silent', 'Silencioso');
                Get.back();
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildThemeOption(
    AppThemeMode mode,
    bool isSelected,
    VoidCallback onTap,
  ) {
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
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: primaryColor, size: 20)
            : null,
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
