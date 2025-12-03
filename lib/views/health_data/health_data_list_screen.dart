import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/health_data_controller.dart';
import 'package:app_remedio/models/health_data_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/views/health_data/add_health_data_screen.dart';
import 'package:app_remedio/views/health_data/health_data_detail_screen.dart';
import 'package:intl/intl.dart';

class HealthDataDashboardScreen extends GetView<HealthDataController> {
  const HealthDataDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadHealthData();
    });

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Dashboard de Saúde', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.healthDataList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.healthDataList.isEmpty) {
          return _buildEmptyState();
        }
        return _buildDashboardBody();
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddHealthDataScreen()),
        backgroundColor: primaryColor,
        tooltip: 'Adicionar Registro',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboardBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: HealthDataType.values.map((type) {
        final typeData = controller.healthDataList
            .where((d) => d.tipo == type.name)
            .toList();
        
        typeData.sort((a, b) => b.dataRegistroDateTime.compareTo(a.dataRegistroDateTime));

        return _buildHealthCategoryCard(type, typeData);
      }).toList(),
    );
  }

  Widget _buildHealthCategoryCard(HealthDataType type, List<HealthData> data) {
    final bool hasData = data.isNotEmpty;
    final latestData = hasData ? data.first : null;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (hasData) {
            Get.to(() => HealthDataDetailScreen(dataType: type));
          } else {
            Get.to(() => const AddHealthDataScreen());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getIconForType(type), color: primaryColor, size: 24), // CORRIGIDO
                  const SizedBox(width: 12),
                  Text(
                    type.label,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasData) ...[
                Text(
                  latestData!.tipo == HealthDataType.pressaoArterial.name // CORRIGIDO
                      ? latestData.pressaoArterialFormatada
                      : latestData.valorFormatado,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                Text(
                  'Último registro em ${DateFormat('dd/MM/yy \'às\' HH:mm').format(latestData.dataRegistroDateTime)}',
                  style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: _buildSparklineChart(data),
                ),
              ] else ...[
                Text(
                  'Nenhum registro',
                  style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.5)),
                ),
                 Text(
                  'Toque para adicionar seu primeiro dado.',
                  style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.4)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSparklineChart(List<HealthData> data) {
    final chartData = data.take(7).toList().reversed.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < chartData.length; i++) {
        final value = chartData[i].tipo == HealthDataType.pressaoArterial.name // CORRIGIDO
            ? chartData[i].valorSistolica 
            : chartData[i].valor;
        if(value != null){
            spots.add(FlSpot(i.toDouble(), value));
        }
    }

    if (spots.length < 2) return const SizedBox.shrink();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.3), primaryColor.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(HealthDataType type) {
    // Mapeamento de ícones baseado no enum
    switch (type) {
      case HealthDataType.peso: return Icons.monitor_weight;
      case HealthDataType.altura: return Icons.height;
      case HealthDataType.glicose: return Icons.bloodtype;
      case HealthDataType.pressaoArterial: return Icons.favorite;
      case HealthDataType.frequenciaCardiaca: return Icons.favorite_border;
      case HealthDataType.temperatura: return Icons.thermostat;
      case HealthDataType.saturacaoOxigenio: return Icons.air;
      default: return Icons.health_and_safety;
    }
  }

  Widget _buildEmptyState() {
    // Seu widget _buildEmptyState, sem alterações.
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
                Icon(Icons.favorite_outline, size: 80, color: primaryColor.withOpacity(0.7)),
                const SizedBox(height: 24),
                Text('Nenhum dado de saúde registrado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Comece registrando seus dados de saúde para acompanhar sua evolução', style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.7)), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => const AddHealthDataScreen()),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Primeiro Registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}