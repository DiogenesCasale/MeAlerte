import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/profile_controller.dart';

class ProfileImageWidget extends StatelessWidget {
  final String? imagePath;
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;

  const ProfileImageWidget({
    super.key,
    this.imagePath,
    this.size = 80,
    this.showBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Força rebuild quando perfil muda
      final profileController = Get.find<ProfileController>();
      profileController.currentProfile.value;
      
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: _buildImage(),
          ),
        ),
      );
    });
  }

  Widget _buildImage() {
    // Se tem caminho de imagem válido
    if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.startsWith('assets/')) {
        return Image.asset(
          imagePath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          key: ValueKey('asset_$imagePath'),
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage();
          },
        );
        } else {
          // Para arquivos locais - verifica se existe antes de carregar
          final file = File(imagePath!);
          
          // MELHOR TRATAMENTO: Usa Future para verificar de forma assíncrona
          return FutureBuilder<bool>(
            future: file.exists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Mostra loading enquanto verifica
                return _buildDefaultImage();
              }
              
              if (snapshot.data == true) {
                // Arquivo existe, carrega normalmente
                return Image.file(
                  file,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  key: ValueKey('profile_file_$imagePath'),
                  errorBuilder: (context, error, stackTrace) {
                    // Se der erro mesmo o arquivo existindo, mostra padrão
                    return _buildDefaultImage();
                  },
                );
              } else {
                // Arquivo não existe, mostra imagem padrão
                return _buildDefaultImage();
              }
            },
          );
        }
    }

    // Imagem padrão
    return _buildDefaultImage();
  }

  Widget _buildDefaultImage() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.person, size: size * 0.6, color: Colors.white),
    );
  }
}
