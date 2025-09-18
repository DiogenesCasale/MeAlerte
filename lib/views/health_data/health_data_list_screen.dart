import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/health_data_controller.dart';
import 'package:app_remedio/models/health_data_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/views/health_data/add_health_data_screen.dart';
import 'package:app_remedio/views/health_data/edit_health_data_screen.dart';
import 'package:intl/intl.dart';

class HealthDataListScreen extends GetView<HealthDataController> {
  const HealthDataListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recarrega os dados toda vez que a tela é construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadHealthData();
    });

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
          'Dados de Saúde',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.healthDataList.isEmpty) {
          return _buildEmptyState();
        }

        return _buildHealthDataList(controller);
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddHealthDataScreen()),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                  Icons.favorite_outline,
                  size: 80,
                  color: primaryColor.withOpacity(0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nenhum dado de saúde registrado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Comece registrando seus dados de saúde para acompanhar sua evolução',
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
                    onPressed: () => Get.to(() => const AddHealthDataScreen()),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Adicionar Primeiro Registro',
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

  Widget _buildHealthDataList(HealthDataController controller) {
    // Agrupa dados por tipo
    final groupedData = <String, List<HealthData>>{};
    for (final data in controller.healthDataList) {
      if (!groupedData.containsKey(data.tipo)) {
        groupedData[data.tipo] = [];
      }
      groupedData[data.tipo]!.add(data);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Resumo rápido
          _buildQuickSummary(controller),
          const SizedBox(height: 24),
          
          // Lista agrupada por tipo
          ...groupedData.entries.map((entry) => 
            _buildHealthDataGroup(entry.key, entry.value)
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary(HealthDataController controller) {
    final registeredTypes = controller.getRegisteredDataTypes();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total de Registros',
                  controller.healthDataList.length.toString(),
                  Icons.assessment,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Tipos Diferentes',
                  registeredTypes.length.toString(),
                  Icons.category,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthDataGroup(String tipo, List<HealthData> dataList) {
    final healthDataType = HealthDataType.fromString(tipo);
    final typeLabel = healthDataType?.label ?? tipo;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForType(tipo),
            color: primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          typeLabel,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          '${dataList.length} registro${dataList.length != 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 14,
            color: textColor.withOpacity(0.6),
          ),
        ),
        children: dataList.map((data) => _buildHealthDataItem(data)).toList(),
      ),
    );
  }

  Widget _buildHealthDataItem(HealthData data) {
    final healthDataType = HealthDataType.fromString(data.tipo);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (healthDataType?.isPressaoArterial == true) ...[
                  Text(
                    data.pressaoArterialFormatada,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ] else ...[
                  Text(
                    data.valorFormatado,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(data.dataRegistroDateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
                if (data.observacao != null && data.observacao!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.observacao!,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                Get.to(() => EditHealthDataScreen(healthData: data));
              } else if (value == 'delete') {
                _showDeleteDialog(data);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Icon(
              Icons.more_vert,
              color: textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    switch (tipo) {
      case 'peso':
        return Icons.monitor_weight;
      case 'altura':
        return Icons.height;
      case 'glicose':
        return Icons.bloodtype;
      case 'pressaoArterial':
        return Icons.favorite;
      case 'frequenciaCardiaca':
        return Icons.favorite_border;
      case 'temperatura':
        return Icons.thermostat;
      case 'saturacaoOxigenio':
        return Icons.air;
      default:
        return Icons.health_and_safety;
    }
  }

  void _showDeleteDialog(HealthData data) {
    final healthDataController = Get.find<HealthDataController>();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este registro de dados de saúde?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await healthDataController.deleteHealthData(data.id!);
              if (success) {
                Get.snackbar(
                  'Sucesso',
                  'Registro excluído com sucesso',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Erro',
                  'Erro ao excluir registro',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
