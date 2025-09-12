import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/widgets/profile_image_widget.dart';
import 'package:app_remedio/views/profile/profile_list_screen.dart';

class ProfileSelectorWidget extends StatelessWidget {
  final bool showName;
  final double imageSize;
  
  const ProfileSelectorWidget({
    super.key,
    this.showName = true,
    this.imageSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return Obx(() {
      final currentProfile = profileController.currentProfile.value;
      
      if (currentProfile == null) {
        return _buildNoProfileWidget();
      }

      return _buildProfileSelector(currentProfile, profileController);
    });
  }

  Widget _buildNoProfileWidget() {
    return GestureDetector(
      onTap: () => Get.to(() => const ProfileListScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add,
              size: imageSize * 0.7,
              color: primaryColor,
            ),
            if (showName) ...[
              const SizedBox(width: 8),
              Text(
                'Criar Perfil',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSelector(dynamic currentProfile, ProfileController controller) {
    return GestureDetector(
      onTap: () => _showProfileOptions(controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileImageWidget(
              imagePath: currentProfile.caminhoImagem,
              size: imageSize,
              showBorder: false,
            ),
            if (showName) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentProfile.nome,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (controller.profiles.length > 1)
                    Text(
                      'Trocar perfil',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
            if (controller.profiles.length > 1) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: primaryColor,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showProfileOptions(ProfileController controller) {
    if (controller.profiles.length <= 1) {
      Get.to(() => const ProfileListScreen());
      return;
    }

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Selecionar Perfil',
                    style: heading2Style,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Get.back();
                      Get.to(() => const ProfileListScreen());
                    },
                    child: Text(
                      'Gerenciar',
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Lista de perfis
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: Get.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: controller.profiles.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final profile = controller.profiles[index];
                  final isSelected = controller.currentProfile.value?.id == profile.id;
                  
                  return ListTile(
                    leading: ProfileImageWidget(
                      imagePath: profile.caminhoImagem,
                      size: 50,
                    ),
                     title: Text(
                       profile.nome,
                       style: TextStyle(
                         fontSize: 16, 
                         fontWeight: FontWeight.w600, 
                         color: isSelected ? primaryColor : textColor,
                       ),
                     ),
                    subtitle: profile.idade != null
                      ? Text('${profile.idade} anos')
                      : null,
                    trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: primaryColor,
                        )
                      : null,
                    onTap: isSelected 
                      ? null 
                      : () async {
                          Get.back();
                          await controller.setCurrentProfile(profile);
                        },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isSelected 
                      ? primaryColor.withOpacity(0.1) 
                      : null,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
