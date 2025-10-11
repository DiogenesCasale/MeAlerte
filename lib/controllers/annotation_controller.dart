import 'package:get/get.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/models/annotation_model.dart';

class AnnotationController extends GetxController {
  final DatabaseController _dbController = DatabaseController.instance;
  final ProfileController _profileController = Get.find<ProfileController>();

  final RxList<Annotation> annotationsList = <Annotation>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Reage a mudanças no perfil para carregar as anotações corretas
    ever(_profileController.currentProfile, (_) => loadAnnotations());
    loadAnnotations();
  }

  Future<void> loadAnnotations() async {
    final currentProfile = _profileController.currentProfile.value;
    if (currentProfile?.id == null) {
      annotationsList.clear(); // Limpa a lista se não houver perfil
      return;
    }

    try {
      isLoading.value = true;
      final db = await _dbController.database;
      final result = await db.query(
        'tblAnotacoes',
        orderBy: 'dataCriacao DESC',
        where: 'deletado = 0 AND idPerfil = ?',
        whereArgs: [currentProfile!.id],
      );
      final anotacoes = result.map((json) => Annotation.fromMap(json)).toList();
      annotationsList.assignAll(anotacoes);
    } catch (e) {
      print('Erro ao carregar anotações: $e');
      Get.snackbar('Erro', 'Não foi possível carregar as anotações.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addAnnotation(String textoAnotacao) async {
    final currentProfile = _profileController.currentProfile.value;
    if (currentProfile?.id == null) return false;

    final novaAnotacao = Annotation(
      idPerfil: currentProfile!.id!,
      anotacao: textoAnotacao,
      dataCriacao: DateTime.now().toIso8601String(),
      dataAtualizacao: DateTime.now().toIso8601String(),
    );

    try {
      final db = await _dbController.database;
      await db.insert('tblAnotacoes', novaAnotacao.toMap());
      loadAnnotations(); // Recarrega a lista
      return true;
    } catch (e) {
      print('Erro ao adicionar anotação: $e');
      return false;
    }
  }
  
  Future<bool> updateAnnotation(Annotation anotacao) async {
     try {
      final db = await _dbController.database;
      await db.update(
        'tblAnotacoes',
        {
          'anotacao': anotacao.anotacao,
          'dataAtualizacao': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [anotacao.id],
      );
      loadAnnotations();
      return true;
    } catch (e) {
      print('Erro ao atualizar anotação: $e');
      return false;
    }
  }

  Future<bool> deleteAnnotation(int id) async {
    try {
      final db = await _dbController.database;
      await db.update(
        'tblAnotacoes',
        {'deletado': 1, 'dataAtualizacao': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      loadAnnotations();
      return true;
    } catch (e) {
      print('Erro ao deletar anotação: $e');
      return false;
    }
  }

  
}