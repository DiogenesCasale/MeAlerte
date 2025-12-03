import 'package:app_remedio/utils/toast_service.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/models/annotation_model.dart';

class AnnotationController extends GetxController {
  final DatabaseController _dbController = DatabaseController.instance;
  final ProfileController _profileController = Get.find<ProfileController>();

  final RxList<Annotation> annotationsList = <Annotation>[].obs;
  final RxBool isLoading = false.obs;

  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    // Reage a mudanças no perfil para carregar as anotações corretas
    ever(_profileController.currentProfile, (_) => loadAnnotations());
    loadAnnotations();
  }

  void setDateFilter(DateTime newStartDate, DateTime newEndDate) {
    startDate.value = newStartDate;
    endDate.value = newEndDate;
    loadAnnotations(); // Recarrega os dados com o novo filtro
  }

  Future<void> loadAnnotations() async {
    final currentProfile = _profileController.currentProfile.value;
    if (currentProfile?.id == null) {
      annotationsList.clear();
      return;
    }

    try {
      isLoading.value = true;
      final db = await _dbController.database;

      // Constrói a query e os argumentos dinamicamente
      String whereClause = 'deletado = 0 AND idPerfil = ?';
      List<dynamic> whereArgs = [currentProfile!.id];

      // Adiciona o filtro de data de início, se existir
      if (startDate.value != null) {
        // Pega o início do dia para a consulta
        final startOfDay = DateTime(
          startDate.value!.year,
          startDate.value!.month,
          startDate.value!.day,
        );
        whereClause += ' AND dataCriacao >= ?';
        whereArgs.add(startOfDay.toIso8601String());
      }

      // Adiciona o filtro de data de fim, se existir
      if (endDate.value != null) {
        // Pega o final do dia para incluir todos os registros da data final
        final endOfDay = DateTime(
          endDate.value!.year,
          endDate.value!.month,
          endDate.value!.day,
          23,
          59,
          59,
        );
        whereClause += ' AND dataCriacao <= ?';
        whereArgs.add(endOfDay.toIso8601String());
      }

      final result = await db.query(
        'tblAnotacoes',
        orderBy: 'dataCriacao DESC',
        where: whereClause, // Usa a cláusula WHERE dinâmica
        whereArgs: whereArgs, // Usa os argumentos dinâmicos
      );

      final anotacoes = result.map((json) => Annotation.fromMap(json)).toList();
      annotationsList.assignAll(anotacoes);
    } catch (e) {
      print('Erro ao carregar anotações: $e');
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(
          context,
          'Não foi possível carregar as anotações.',
        );
      }
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
