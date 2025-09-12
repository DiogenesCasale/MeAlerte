import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/widgets/profile_image_widget.dart';
import 'package:app_remedio/views/profile/add_profile_screen.dart';
import 'package:app_remedio/views/profile/edit_profile_screen.dart';

class ProfileListScreen extends StatelessWidget {
  const ProfileListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Gerenciar Perfis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (profileController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Header com perfil atual
            _buildCurrentProfileHeader(profileController),
            
            // Lista de perfis
            Expanded(
              child: _buildProfilesList(profileController),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddProfileScreen()),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCurrentProfileHeader(ProfileController controller) {
    final currentProfile = controller.currentProfile.value;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
               Text(
                 'Perfil Atual',
                 style: TextStyle(
                   fontSize: 16, 
                   fontWeight: FontWeight.w600, 
                   color: primaryColor,
                 ),
               ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (currentProfile != null) ...[
            Row(
              children: [
                ProfileImageWidget(
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
           ] else ...[
             Text(
               'Nenhum perfil selecionado',
               style: TextStyle(
                 fontSize: 16,
                 color: textColor.withOpacity(0.6),
                 fontStyle: FontStyle.italic,
               ),
             ),
           ],
        ],
      ),
    );
  }

  Widget _buildProfilesList(ProfileController controller) {
    if (controller.profiles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: controller.profiles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final profile = controller.profiles[index];
        final isCurrentProfile = controller.currentProfile.value?.id == profile.id;
        
        return _buildProfileCard(profile, isCurrentProfile, controller);
      },
    );
  }

  Widget _buildProfileCard(
    dynamic profile, 
    bool isCurrentProfile, 
    ProfileController controller,
  ) {
    return Card(
      elevation: isCurrentProfile ? 4 : 2,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentProfile 
          ? BorderSide(color: primaryColor, width: 2)
          : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ProfileImageWidget(
          imagePath: profile.caminhoImagem,
          size: 50,
        ),
         title: Text(
           profile.nome,
           style: TextStyle(
             fontSize: 16, 
             fontWeight: FontWeight.w600, 
             color: isCurrentProfile ? primaryColor : textColor,
           ),
         ),
         subtitle: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
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
             if (isCurrentProfile) ...[
               const SizedBox(height: 4),
               Row(
                 children: [
                   Icon(
                     Icons.check_circle,
                     size: 16,
                     color: primaryColor,
                   ),
                   const SizedBox(width: 4),
                   Text(
                     'Perfil Atual',
                     style: TextStyle(
                       fontSize: 12,
                       color: primaryColor,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 ],
               ),
             ],
           ],
         ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textColor),
          onSelected: (value) async {
            switch (value) {
              case 'select':
                if (!isCurrentProfile) {
                  await controller.setCurrentProfile(profile);
                }
                break;
              case 'edit':
                Get.to(() => EditProfileScreen(profile: profile));
                break;
              case 'delete':
                await controller.deleteProfile(profile);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!isCurrentProfile)
              const PopupMenuItem(
                value: 'select',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Selecionar'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              enabled: controller.profiles.length > 1,
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: controller.profiles.length > 1 
                      ? Colors.red 
                      : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Excluir',
                    style: TextStyle(
                      color: controller.profiles.length > 1 
                        ? Colors.red 
                        : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          if (!isCurrentProfile) {
            controller.setCurrentProfile(profile);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 80,
            color: textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum perfil encontrado',
            style: heading2Style.copyWith(
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
           Text(
             'Crie seu primeiro perfil para começar',
             style: TextStyle(
               fontSize: 16,
               color: textColor.withOpacity(0.6),
             ),
             textAlign: TextAlign.center,
           ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const AddProfileScreen()),
            icon: const Icon(Icons.add),
            label: const Text('Criar Primeiro Perfil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
