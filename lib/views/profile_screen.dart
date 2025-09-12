import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/widgets/profile_image_widget.dart';
import 'package:app_remedio/views/profile/profile_list_screen.dart';
import 'package:app_remedio/views/profile/edit_profile_screen.dart';
import 'package:app_remedio/views/settings_screen.dart';

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
        leading: showBackButton ? IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ) : null,
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      child: Column(
        children: [
          // Cabeçalho do Perfil Atual
          _buildCurrentProfileHeader(currentProfile),
          
          const SizedBox(height: 24),
          
          // Seção Perfil
          _buildSectionHeader('Meu Perfil'),
          const SizedBox(height: 12),
          _buildProfileSection(currentProfile),
          
          const SizedBox(height: 24),
          
          // Seção Configurações
          _buildSectionHeader('Configurações'),
          const SizedBox(height: 12),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildCurrentProfileHeader(dynamic profile) {
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
            imagePath: profile.caminhoImagem,
            size: 60,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nome,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (profile.idade != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${profile.idade} anos',
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
          Icon(
            Icons.check_circle,
            color: primaryColor,
            size: 24,
          ),
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

  Widget _buildProfileSection(dynamic profile) {
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
            onTap: () => Get.to(() => EditProfileScreen(profile: profile)),
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

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.withOpacity(0.2),
      indent: 60,
    );
  }

  void _editProfile(dynamic profile) {
    Get.to(() => EditProfileScreen(profile: profile));
  }

}