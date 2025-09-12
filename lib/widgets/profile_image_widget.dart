import 'dart:io';
import 'package:flutter/material.dart';

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
        child: ClipOval(child: _buildImage()),
      ),
    );
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
          key: ValueKey('asset_${imagePath}'),
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage();
          },
        );
      } else {
        // Para arquivos locais - verifica se existe antes de carregar
        final file = File(imagePath!);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            // MUDANÇA PRINCIPAL AQUI: Use uma chave estável baseada no caminho.
            key: ValueKey('file_$imagePath'),
            // REMOVA cacheWidth e cacheHeight, deixe o Flutter gerenciar.
            errorBuilder: (context, error, stackTrace) {
              // Adicione um print para depurar erros de carregamento
              print("Erro ao carregar imagem em ProfileImageWidget: $error");
              return _buildDefaultImage();
            },
          );
        } else {
          // Arquivo não existe, mostra imagem padrão
          return _buildDefaultImage();
        }
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
