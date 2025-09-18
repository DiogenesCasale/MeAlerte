import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/controllers/global_state_controller.dart';
import 'package:app_remedio/models/profile_model.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/utils/profile_helper.dart';

class ProfileController extends GetxController {
  final _dbController = DatabaseController.instance;
  final ImagePicker _picker = ImagePicker();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Observables
  final RxList<Profile> profiles = <Profile>[].obs;
  final Rx<Profile?> currentProfile = Rx<Profile?>(null);
  final RxBool isLoading = false.obs;

  // Keys para SharedPreferences
  static const String _currentProfileKey = 'current_profile_id';

  @override
  void onInit() {
    super.onInit();
    _initializeProfiles();
  }

  /// Inicializa os perfis e carrega o atual
  Future<void> _initializeProfiles() async {
    await _loadProfiles();
    await _loadCurrentProfile();
  }

  // ==================== OPERAÇÕES DE PERFIL ====================

  /// Carrega todos os perfis não deletados do banco
  Future<void> _loadProfiles() async {
    try {
      isLoading.value = true;
      final db = await _dbController.database;
      final result = await db.query(
        'tblPerfil',
        where: 'deletado = ?',
        whereArgs: [0],
        orderBy: 'dataCriacao ASC',
      );

      profiles.value = result.map((map) => Profile.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao carregar perfis: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Carrega o perfil atual das preferências
  Future<void> _loadCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileId = prefs.getInt(_currentProfileKey);

      if (profileId != null) {
        final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
        currentProfile.value = profile;
      }

      // Se não houver perfil atual ou não encontrou, define o primeiro
      if (currentProfile.value == null && profiles.isNotEmpty) {
        await setCurrentProfile(profiles.first);
      }
    } catch (e) {
      print('Erro ao carregar perfil atual: $e');
    }
  }

  /// Define o perfil atual
  Future<void> setCurrentProfile(Profile profile) async {
    try {
      currentProfile.value = profile;
      await _saveCurrentProfileId(profile.id!);

      // Notifica outros controllers sobre a mudança de perfil
      ProfileHelper.notifyProfileChanged();

      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showSuccess(
          context,
          'Perfil alterado para ${profile.nome}',
        );
      }
    } catch (e) {
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro ao alterar perfil: $e');
      }
    }
  }

  /// Salva o ID do perfil atual nas preferências
  Future<void> _saveCurrentProfileId(int profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currentProfileKey, profileId);
    } catch (e) {
      print('Erro ao salvar perfil atual: $e');
    }
  }

  /// Cria um novo perfil
  Future<bool> createProfile(Profile profile) async {
    try {
      isLoading.value = true;
      final db = await _dbController.database;

      final id = await db.insert('tblPerfil', profile.toMap());
      final newProfile = profile.copyWith(id: id);

      profiles.add(newProfile);

      // Se for o primeiro perfil, define como atual
      if (currentProfile.value == null) {
        currentProfile.value = newProfile;
        await _saveCurrentProfileId(newProfile.id!);
      }

      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showSuccess(
          context,
          'Perfil "${profile.nome}" criado com sucesso!',
        );
      }
      return true;
    } catch (e) {
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro ao criar perfil: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Atualiza um perfil existente
  Future<bool> updateProfile(Profile profile) async {
    try {
      isLoading.value = true;
      final db = await _dbController.database;

      await db.update(
        'tblPerfil',
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );

      final index = profiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        // SOLUÇÃO MAIS FORTE: Atualizar ANTES de qualquer outra coisa
        profiles[index] = profile;

        // Atualiza o perfil atual se for o mesmo
        if (currentProfile.value?.id == profile.id) {
          // Limpa cache de imagens para garantir atualização
          _clearImageCache();

          // Atualiza diretamente o perfil atual
          currentProfile.value = profile;

          // Notifica o GlobalStateController sobre a mudança
          try {
            final globalState = Get.find<GlobalStateController>();
            globalState.notifyProfileUpdate();
          } catch (e) {
            print('GlobalStateController não encontrado: $e');
          }
        }
        
        // Atualiza a lista reativa
        profiles.refresh();
      }

      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showSuccess(context, 'Perfil atualizado com sucesso!');
      }
      return true;
    } catch (e) {
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro ao atualizar perfil: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Exclui um perfil (soft delete)
  Future<bool> deleteProfile(Profile profile) async {
    try {
      // Verifica se é o único perfil
      if (profiles.length <= 1) {
        final context = Get.overlayContext;
        if (context != null) {
          ToastService.showError(
            context,
            'Não é possível excluir o único perfil!',
          );
        }
        return false;
      }

      // Confirma a exclusão com autenticação
      final confirmed = await _confirmDeleteWithAuth();
      if (!confirmed) return false;

      isLoading.value = true;
      final db = await _dbController.database;

      // Soft delete
      await db.update(
        'tblPerfil',
        {'deletado': 1, 'dataAtualizacao': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [profile.id],
      );

      // Remove da lista
      profiles.removeWhere((p) => p.id == profile.id);

      // Se era o perfil atual, muda para outro
      if (currentProfile.value?.id == profile.id) {
        if (profiles.isNotEmpty) {
          currentProfile.value = profiles.first;
          await _saveCurrentProfileId(profiles.first.id!);
        } else {
          currentProfile.value = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_currentProfileKey);
        }
      }

      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showSuccess(
          context,
          'Perfil "${profile.nome}" excluído com sucesso!',
        );
      }
      return true;
    } catch (e) {
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro ao excluir perfil: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== GERENCIAMENTO DE IMAGENS ====================

  /// Seleciona uma imagem da galeria
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return await _saveImageToAppDir(image.path);
      }
    } catch (e) {
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro ao selecionar imagem: $e');
      }
    }
    return null;
  }

  /// Captura uma imagem da câmera
  Future<String?> takePhotoFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return await _saveImageToAppDir(image.path);
      }
    } catch (e) {
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro ao capturar foto: $e');
      }
    }
    return null;
  }

  /// Salva a imagem no diretório do app
  Future<String> _saveImageToAppDir(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${directory.path}/profile_images');

      // Cria o diretório se não existir
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }

      // Verifica se o arquivo original existe
      final originalFile = File(imagePath);
      if (!await originalFile.exists()) {
        throw Exception('Arquivo original não encontrado: $imagePath');
      }

      // Gera um nome único para a imagem
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '${profileImagesDir.path}/$fileName';

      // Copia a imagem para o diretório do app
      await originalFile.copy(newPath);

      // Verifica se o arquivo foi copiado com sucesso
      final newFile = File(newPath);
      if (!await newFile.exists()) {
        throw Exception('Falha ao copiar arquivo para: $newPath');
      }

      return newPath;
    } catch (e) {
      print('Erro ao salvar imagem: $e');
      rethrow;
    }
  }

  /// Remove uma imagem do armazenamento
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Erro ao deletar imagem: $e');
    }
  }

  /// Mostra diálogo para escolher fonte da imagem
  Future<String?> showImageSourceDialog() async {
    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Escolher Foto'),
        content: const Text('Como você deseja adicionar a foto?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(result: 'gallery');
            },
            child: const Text('Galeria'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(result: 'camera');
            },
            child: const Text('Câmera'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (result == null) return null;

    if (result == 'gallery') {
      return await pickImageFromGallery();
    } else if (result == 'camera') {
      return await takePhotoFromCamera();
    }

    return null;
  }

  // ==================== CACHE E UTILITÁRIOS ====================

  /// Limpa o cache de imagens do Flutter
  void _clearImageCache() {
    try {
      // Limpa cache de imagens para forçar recarregamento
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      // Força rebuild de widgets dependentes
      update();
    } catch (e) {
      print('Erro ao limpar cache de imagem: $e');
    }
  }

  /// Recarrega o perfil atual do banco de dados
  Future<void> _reloadCurrentProfile(int profileId) async {
    try {
      final db = await _dbController.database;
      final result = await db.query(
        'tblPerfil',
        where: 'id = ? AND deletado = 0',
        whereArgs: [profileId],
      );

      if (result.isNotEmpty) {
        final reloadedProfile = Profile.fromMap(result.first);
        currentProfile.value = reloadedProfile;
        await _saveCurrentProfileId(profileId);

        // Força rebuilds para garantir que todos os widgets atualizem
        currentProfile.refresh();
        profiles.refresh();
        update();
      }
    } catch (e) {
      print('Erro ao recarregar perfil atual: $e');
    }
  }

  // ==================== AUTENTICAÇÃO E SEGURANÇA ====================

  /// Confirma a exclusão com autenticação biométrica ou senha
  Future<bool> _confirmDeleteWithAuth() async {
    try {
      // Primeira confirmação
      final confirmDialog = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text(
            'Tem certeza que deseja excluir este perfil?\n\n'
            'Esta ação não pode ser desfeita e todos os dados '
            'relacionados ao perfil serão perdidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (confirmDialog != true) return false;

      // Verifica se há autenticação biométrica disponível
      try {
        final isAvailable = await _localAuth.canCheckBiometrics;
        final isDeviceSupported = await _localAuth.isDeviceSupported();
        final availableBiometrics = await _localAuth.getAvailableBiometrics();

        if (isAvailable &&
            isDeviceSupported &&
            availableBiometrics.isNotEmpty) {
          // Tentar autenticação biométrica
          final biometricResult = await _authenticateWithBiometrics();
          if (biometricResult) {
            return true;
          } else {
            // Se a biometria falhou, oferece opção de usar confirmação manual
            return await _showAuthFailedDialog();
          }
        } else {
          // Fallback para confirmação manual se não houver biometria
          return await _authenticateWithManualConfirmation();
        }
      } catch (e) {
        print('Erro na verificação de biometria: $e');
        // Fallback para confirmação manual
        return await _authenticateWithManualConfirmation();
      }
    } catch (e) {
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro na confirmação: $e');
      }
      return false;
    }
  }

  /// Autenticação com biometria
  Future<bool> _authenticateWithBiometrics() async {
    try {
      await HapticFeedback.mediumImpact();

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Confirme sua identidade para excluir o perfil',
        options: const AuthenticationOptions(
          biometricOnly: false, // Permite PIN/senha como fallback
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        await HapticFeedback.lightImpact();
        return true;
      } else {
        await HapticFeedback.heavyImpact();
        print('Autenticação biométrica cancelada pelo usuário');
        return false;
      }
    } catch (e) {
      print('Erro na autenticação biométrica: $e');

      // Não mostra toast aqui, deixa para o diálogo de falha lidar com isso
      await HapticFeedback.heavyImpact();
      return false;
    }
  }

  /// Mostra diálogo quando a autenticação biométrica falha
  Future<bool> _showAuthFailedDialog() async {
    try {
      final result = await Get.dialog<String>(
        AlertDialog(
          title: const Text('Autenticação Falhada'),
          content: const Text(
            'A autenticação biométrica não foi concluída.\n\n'
            'Você pode tentar novamente ou usar a confirmação manual.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: 'cancel'),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Get.back(result: 'retry'),
              child: const Text('Tentar Novamente'),
            ),
            TextButton(
              onPressed: () => Get.back(result: 'manual'),
              child: const Text('Confirmação Manual'),
            ),
          ],
        ),
      );

      switch (result) {
        case 'retry':
          return await _authenticateWithBiometrics();
        case 'manual':
          return await _authenticateWithManualConfirmation();
        default:
          return false;
      }
    } catch (e) {
      print('Erro no diálogo de falha de autenticação: $e');
      return false;
    }
  }

  /// Autenticação manual (fallback)
  Future<bool> _authenticateWithManualConfirmation() async {
    try {
      await HapticFeedback.mediumImpact();

      final TextEditingController confirmController = TextEditingController();
      final RxBool isValid = false.obs;

      final authDialog = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirme sua Identidade'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para excluir o perfil, digite "EXCLUIR" no campo abaixo para confirmar.',
              ),
              const SizedBox(height: 16),
              Obx(
                () => TextField(
                  controller: confirmController,
                  decoration: InputDecoration(
                    hintText: 'Digite EXCLUIR',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.security),
                    suffixIcon: isValid.value
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  onChanged: (value) {
                    isValid.value = value.toUpperCase() == 'EXCLUIR';
                  },
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            Obx(
              () => TextButton(
                onPressed: isValid.value ? () => Get.back(result: true) : null,
                style: TextButton.styleFrom(
                  foregroundColor: isValid.value ? Colors.red : Colors.grey,
                ),
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      confirmController.dispose();
      return authDialog == true;
    } catch (e) {
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Falha na confirmação: $e');
      }
      return false;
    }
  }

  // ==================== UTILITÁRIOS ====================

  /// Retorna o caminho da imagem padrão
  String get defaultImagePath => 'assets/images/default_profile.png';

  /// Valida os dados do perfil
  String? validateProfile({
    required String nome,
    String? dataNascimento,
    String? genero,
    double? peso,
  }) {
    if (nome.trim().isEmpty) {
      return 'Nome é obrigatório';
    }

    if (nome.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }

    if (dataNascimento != null && dataNascimento.isNotEmpty) {
      try {
        final nascimento = DateTime.parse(dataNascimento);
        final hoje = DateTime.now();
        if (nascimento.isAfter(hoje)) {
          return 'Data de nascimento não pode ser no futuro';
        }
      } catch (e) {
        return 'Data de nascimento inválida';
      }
    }

    if (peso != null && peso <= 0) {
      return 'Peso deve ser maior que zero';
    }

    return null;
  }

  /// Recarrega os dados
  @override
  Future<void> refresh() async {
    await _loadProfiles();
    await _loadCurrentProfile();
  }
}
