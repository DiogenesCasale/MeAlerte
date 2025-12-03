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

        // 1. Se a lista TOTAL estiver vazia, mostre o empty state
        if (profileController.profiles.isEmpty) {
          return _buildEmptyState();
        }

        // 2. Se houver perfis, mostre o header e a seção de "outros perfis"
        return Column(
          children: [
            // Header com perfil atual (sempre exibido se houver perfis)
            _buildCurrentProfileHeader(profileController),

            // Nova seção que contém a lista filtrada
            _buildOtherProfilesSection(profileController),
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
              Icon(Icons.person, color: primaryColor, size: 20),
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
              // Alinha os itens da Row (imagem, texto, botões)
              crossAxisAlignment: CrossAxisAlignment.center,
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

                // --- INÍCIO DA MODIFICAÇÃO ---
                // Substituímos o Icon(check) por uma Coluna
                // para agrupar o "check" e o "editar"
                const SizedBox(width: 8), // Espaço antes dos botões
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: primaryColor, size: 24),
                    const SizedBox(height: 10), // Espaço entre os ícones
                    // Botão de Editar
                    InkWell(
                      onTap: () {
                        // Navega para a tela de edição passando o perfil atual
                        Get.to(
                          () =>
                              EditProfileScreen(profileInitial: currentProfile),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0), // Área de clique
                        child: Icon(
                          Icons.edit_outlined, // Ícone de editar
                          color: textColor.withOpacity(0.7),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                // --- FIM DA MODIFICAÇÃO ---
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

  // NOVO WIDGET: Seção "Outros Perfis"
  Widget _buildOtherProfilesSection(ProfileController controller) {
    // Filtra a lista para pegar TODOS, EXCETO o perfil atual
    final currentProfileId = controller.currentProfile.value?.id;
    final otherProfiles = controller.profiles
        .where((p) => p.id != currentProfileId)
        .toList();

    // Se não houver outros perfis (ou seja, só existe 1 perfil no total)
    if (otherProfiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Text(
            'Não há outros perfis para gerenciar.',
            style: TextStyle(
              fontSize: 15,
              color: textColor.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Se houver, mostra o título e a lista filtrada
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Outros Perfis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            // Passa a lista JÁ FILTRADA para o _buildProfilesList
            child: _buildProfilesList(controller, otherProfiles),
          ),
        ],
      ),
    );
  }

  // WIDGET MODIFICADO: Agora recebe a lista de perfis
  Widget _buildProfilesList(
    ProfileController controller,
    List<dynamic> profiles,
  ) {
    // A verificação de lista vazia foi movida para o widget 'build' e '_buildOtherProfilesSection'
    // Esta lista agora contém APENAS os "outros perfis"

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: profiles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final profile = profiles[index];

        // Como esta lista SÓ TEM os "outros perfis",
        // 'isCurrentProfile' será sempre falso aqui.
        const bool isCurrentProfile = false;

        return _buildProfileCard(profile, isCurrentProfile, controller);
      },
    );
  }

  // Seu widget _buildProfileCard original (sem alterações)
  Widget _buildProfileCard(
    dynamic profile,
    bool isCurrentProfile,
    ProfileController controller,
  ) {
    // ... (coloquei o seu código original aqui)
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
        leading: ProfileImageWidget(imagePath: profile.caminhoImagem, size: 50),
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
            // Esta lógica de 'isCurrentProfile' nunca será
            // verdadeira aqui, o que é o correto.
            if (isCurrentProfile) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: primaryColor),
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
            if (profile.perfilPadrao) ...[
              const SizedBox(height: 4),
              Text(
                'Perfil Padrão',
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
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
                Get.to(() => EditProfileScreen(profileInitial: profile));
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

  // Seu widget _buildEmptyState original (sem alterações)
  Widget _buildEmptyState() {
    // ... (coloquei o seu código original aqui)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 80, color: textColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Nenhum perfil encontrado',
            style: heading2Style.copyWith(color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro perfil para começar',
            style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.6)),
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
