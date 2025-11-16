import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/widgets/profile_image_widget.dart';
import 'package:app_remedio/views/profile/profile_list_screen.dart';
import 'package:app_remedio/views/profile/edit_profile_screen.dart';
import 'package:app_remedio/views/settings_screen.dart';
import 'package:app_remedio/views/health_data/health_data_list_screen.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/views/medication/stock_history_screen.dart';
import 'package:app_remedio/views/annotation/annotation_list_screen.dart';
import 'package:app_remedio/views/backup/backup_screen.dart';
import 'package:app_remedio/views/reports/doses_report_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool showBackButton;
  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Get.back(),
              )
            : null,
        title: Text(
          'Perfil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        // Força rebuild quando o perfil muda
        profileController.currentProfile.value;
        profileController.profiles.length;

        final currentProfile = profileController.currentProfile.value;

        if (profileController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (currentProfile == null) {
          return _buildNoProfileView();
        }

        return _buildProfileView(currentProfile);
      }),
    );
  }

  Widget _buildNoProfileView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
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
                Icon(
                  Icons.person_add,
                  size: 80,
                  color: primaryColor.withOpacity(0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nenhum perfil encontrado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Crie seu primeiro perfil para começar a organizar seus medicamentos',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => const ProfileListScreen()),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Criar Primeiro Perfil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(dynamic currentProfile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildCurrentProfileHeader(),

            const SizedBox(height: 24),

            // Seção Perfil
            _buildSectionHeader('Meu Perfil'),
            const SizedBox(height: 12),
            _buildProfileSection(),

            const SizedBox(height: 24),

            // Seção Saúde
            _buildSectionHeader('Saúde e Acompanhamento'),
            const SizedBox(height: 12),
            Builder(builder: (context) => _buildHealthSection(context)),

            const SizedBox(height: 24),

            // Seção Configurações
            _buildSectionHeader('Configurações'),
            const SizedBox(height: 12),
            _buildSettingsSection(),

            const SizedBox(height: 24),

            // Seção Backup
            _buildSectionHeader('Backup'),
            const SizedBox(height: 12),
            _buildBackupSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentProfileHeader() {
    final profileController = Get.find<ProfileController>();
    final currentProfile = profileController.currentProfile.value;

    if (currentProfile == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ProfileImageWidget(
            key: ValueKey(
              'profile_image_${currentProfile.id}_${currentProfile.caminhoImagem}',
            ),
            imagePath: currentProfile.caminhoImagem,
            size: 60,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentProfile.nome,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (currentProfile.idade != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${currentProfile.idade} anos',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Perfil Ativo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: primaryColor, size: 24),
        ],
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

  Widget _buildProfileSection() {
    final profileController = Get.find<ProfileController>();
    final currentProfile = profileController.currentProfile.value;

    return Container(
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
            icon: Icons.edit,
            title: 'Editar Perfil',
            subtitle: 'Alterar informações pessoais e foto',
            onTap: currentProfile != null
                ? () {
                    // Apenas navegue. O controller agora gerencia 100% da atualização.
                    Get.to(
                      () => EditProfileScreen(profileInitial: currentProfile),
                    );
                  }
                : null,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.group,
            title: 'Gerenciar Perfis',
            subtitle: 'Criar, editar ou trocar entre perfis',
            onTap: () => Get.to(() => const ProfileListScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSection(BuildContext context) {
    return Container(
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
            icon: Icons.favorite_outline,
            title: 'Dados de Saúde',
            subtitle: 'Registrar peso, pressão, glicose e outros dados',
            onTap: () => Get.to(() => const HealthDataDashboardScreen()),
          ),
          _buildDivider(),
          // Ideia de ter consultas foi deixada de lado por enquanto
          // _buildSettingsTile(
          //   icon: Icons.calendar_today,
          //   title: 'Consultas',
          //   subtitle: 'Agendar e acompanhar consultas médicas',
          //   onTap: () => _showFeatureInDevelopment('Consultas', context),
          // ),
          // _buildDivider(),
          _buildSettingsTile(
            icon: Icons.analytics,
            title: 'Relatórios',
            subtitle: 'Relatórios de medicamentos e aderência',
            onTap: () => Get.to(() => const DosesReportScreen()),
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.inventory,
            title: 'Histórico',
            subtitle: 'Histórico de reposição e uso de medicamentos',
            onTap: () => Get.to(() => const StockHistoryScreen()),
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.book,
            title: 'Diário',
            subtitle: 'Observações pessoais e anotações',
            onTap: () => Get.to(() => const AnnotationsListScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
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
            icon: Icons.settings,
            title: 'Configurações do App',
            subtitle: 'Tema, notificações e preferências',
            onTap: () => Get.to(() => const SettingsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    return Container(
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
            icon: Icons.backup,
            title: 'Backup',
            subtitle: 'Backup e restauração dos dados',
            onTap: () => Get.to(() => const BackupScreen()),
          ),
        ],
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

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.withOpacity(0.2), indent: 60);
  }

}
