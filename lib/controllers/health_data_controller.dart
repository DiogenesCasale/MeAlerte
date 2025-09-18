import 'package:get/get.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/models/health_data_model.dart';
import 'package:app_remedio/utils/toast_service.dart';

class HealthDataController extends GetxController {
  final DatabaseController _dbController = DatabaseController.instance;
  final ProfileController _profileController = Get.find<ProfileController>();

  // Observables para estado da UI
  final RxList<HealthData> healthDataList = <HealthData>[].obs;
  final RxList<HealthData> filteredHealthDataList = <HealthData>[].obs;
  final RxBool isLoading = false.obs;
  
  // Controller para busca
  final RxBool isSearchTextEmpty = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Carrega os dados diretamente sem checar perfil
    _waitForProfileAndInitialize();
  }
  
  @override
  void onClose() {
    super.onClose();
  }

  Future<void> _waitForProfileAndInitialize() async {
    try {
      // Aguarda o ProfileController estar disponível
      ProfileController? profileController;
      int attempts = 0;
      const maxAttempts = 50; // 5 segundos máximo
      
      while (profileController == null && attempts < maxAttempts) {
        try {
          profileController = Get.find<ProfileController>();
        } catch (e) {
          // Controller ainda não está disponível, aguarda um pouco
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
      }
      
      if (profileController == null) {
        print('ProfileController não encontrado após aguardar');
        return;
      }
      
      // Aguarda até o ProfileController terminar de carregar
      while (profileController.isLoading.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Se há perfil disponível, carrega os dados
      if (profileController.currentProfile.value != null) {
        await _initializeData();
      }
      // Se não há perfil, os dados serão carregados quando um perfil for selecionado
    } catch (e) {
      print('Erro ao aguardar ProfileController: $e');
    }
  }

  Future<void> _initializeData() async {
    await loadHealthData();
  }

  // Carrega todos os dados de saúde do perfil atual
  Future<void> loadHealthData() async {
    try {
      final db = await _dbController.database;

      isLoading.value = true;
      final currentProfile = _profileController.currentProfile.value;

      if (currentProfile?.id == null) {
        ToastService.showError(
          Get.overlayContext!,
          'Nenhum perfil selecionado',
        );
        isLoading.value = false;
        Get.back();
        return;
      }

      final result = await db.query(
        'tblDadosSaude',
        orderBy: 'dataRegistro DESC, dataCriacao DESC',
        where: 'deletado = 0 AND idPerfil = ?',
        whereArgs: [currentProfile!.id],
      );
      final healthData = result
          .map((json) => HealthData.fromMap(json))
          .toList();

      healthDataList.assignAll(healthData);

      print('Dados de saúde carregados com sucesso');
    } catch (e) {
      print('Erro ao carregar dados de saúde: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Adiciona um novo dado de saúde
  Future<bool> addHealthData(HealthData healthData) async {
    try {
      final db = await _dbController.database;
      await db.insert('tblDadosSaude', healthData.toMap());

      await loadHealthData();

      return true;
    } catch (e) {
      print('Erro ao adicionar dado de saúde: $e');
      return false;
    }
  }

  // Atualiza um dado de saúde existente
  Future<bool> updateHealthData(HealthData healthData) async {
    try {
      final db = await _dbController.database;
      await db.update(
        'tblDadosSaude',
        healthData.toMap(),
        where: 'id = ?',
        whereArgs: [healthData.id],
      );

      await loadHealthData();

      return true;
    } catch (e) {
      print('Erro ao atualizar dado de saúde: $e');
      return false;
    }
  }

  // Remove um dado de saúde (marca como deletado)
  Future<bool> deleteHealthData(int id) async {
    try {
      final db = await _dbController.database;
      await db.update(
        'tblDadosSaude',
        {'deletado': 1, 'dataAtualizacao': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

      await loadHealthData();

      return true;
    } catch (e) {
      print('Erro ao deletar dado de saúde: $e');
      return false;
    }
  }

  // Obtém dados de saúde por tipo
  List<HealthData> getHealthDataByType(String tipo) {
    return healthDataList.where((item) => item.tipo == tipo).toList();
  }

  // Obtém o último registro de um tipo específico
  HealthData? getLatestHealthDataByType(String tipo) {
    final dataByType = getHealthDataByType(tipo);
    if (dataByType.isNotEmpty) {
      return dataByType.first; // A lista já está ordenada por data DESC
    }
    return null;
  }

  // Obtém dados de saúde por período
  List<HealthData> getHealthDataByDateRange(DateTime inicio, DateTime fim) {
    return healthDataList.where((item) {
      final dataRegistro = item.dataRegistroDateTime;
      return dataRegistro.isAfter(inicio.subtract(const Duration(days: 1))) &&
          dataRegistro.isBefore(fim.add(const Duration(days: 1)));
    }).toList();
  }

  // Obtém estatísticas de um tipo de dado
  Map<String, dynamic> getHealthDataStats(String tipo) {
    final dataByType = getHealthDataByType(tipo);

    if (dataByType.isEmpty) {
      return {
        'total': 0,
        'ultimo': null,
        'media': null,
        'minimo': null,
        'maximo': null,
      };
    }

    List<double> valores = [];

    if (tipo == HealthDataType.pressaoArterial.name) {
      // Para pressão arterial, consideramos valores sistólicos
      valores = dataByType
          .where((item) => item.valorSistolica != null)
          .map((item) => item.valorSistolica!)
          .toList();
    } else {
      valores = dataByType
          .where((item) => item.valor != null)
          .map((item) => item.valor!)
          .toList();
    }

    if (valores.isEmpty) {
      return {
        'total': dataByType.length,
        'ultimo': dataByType.first,
        'media': null,
        'minimo': null,
        'maximo': null,
      };
    }

    final media = valores.reduce((a, b) => a + b) / valores.length;
    final minimo = valores.reduce((a, b) => a < b ? a : b);
    final maximo = valores.reduce((a, b) => a > b ? a : b);

    return {
      'total': dataByType.length,
      'ultimo': dataByType.first,
      'media': media,
      'minimo': minimo,
      'maximo': maximo,
    };
  }

  // Obtém tipos de dados únicos registrados
  List<String> getRegisteredDataTypes() {
    final tipos = healthDataList.map((item) => item.tipo).toSet().toList();
    tipos.sort();
    return tipos;
  }

  // Limpa todos os dados carregados
  void clearData() {
    healthDataList.clear();
  }
}
