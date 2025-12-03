import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/health_data_controller.dart';
import 'package:app_remedio/models/health_data_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/views/health_data/edit_health_data_screen.dart'; // Importe a tela de edição
import 'package:intl/intl.dart';
import 'package:app_remedio/utils/toast_service.dart';

class HealthDataDetailScreen extends StatelessWidget {
  final HealthDataType dataType;
  final HealthDataController controller = Get.find();

  HealthDataDetailScreen({super.key, required this.dataType});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<HealthData> dataList =
          controller.healthDataList.where((d) => d.tipo == dataType.name).toList()
            ..sort(
              (a, b) => b.dataRegistroDateTime.compareTo(a.dataRegistroDateTime),
            );

      return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            dataType.label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
        ),
        body: Column(
          children: [
            Container(
              height: 250,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: _buildLineChart(dataList),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Histórico de Registros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${dataList.length} registros',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: dataList.length,
                itemBuilder: (context, index) {
                  return _buildHealthDataItem(dataList[index], context);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLineChart(List<HealthData> data) {
    final chartData = data.take(30).toList().reversed.toList();
    if (chartData.length < 2) {
      return Center(
        child: Text(
          'Dados insuficientes para gerar gráfico',
          style: TextStyle(color: textColor.withOpacity(0.5)),
        ),
      );
    }

    List<LineChartBarData> lineBarsData = [];
    final spots = chartData.asMap().entries.map((entry) {
      final value = entry.value.tipo == HealthDataType.pressaoArterial.name
          ? entry.value.valorSistolica
          : entry.value.valor;
      return FlSpot(entry.key.toDouble(), value!);
    }).toList();
    lineBarsData.add(_createLineBar(spots, primaryColor));

    if (dataType == HealthDataType.pressaoArterial) {
      final diastolicSpots = chartData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.valorDiastolica!);
      }).toList();
      lineBarsData.add(_createLineBar(diastolicSpots, Colors.teal));
    }

    return LineChart(
      LineChartData(
        lineBarsData: lineBarsData,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: leftTitleWidgets,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dataPoint = chartData[spot.spotIndex];
                final date = DateFormat(
                  'dd/MM/yy',
                ).format(dataPoint.dataRegistroDateTime);
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} ${dataType.unidade}\n$date',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  LineChartBarData _createLineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return Text(
      value.toInt().toString(),
      style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
      textAlign: TextAlign.left,
    );
  }

  Widget _buildHealthDataItem(HealthData data, BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text(
          data.tipo == HealthDataType.pressaoArterial.name
              ? data.pressaoArterialFormatada
              : data.valorFormatado,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(dateFormat.format(data.dataRegistroDateTime)),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Get.to(() => EditHealthDataScreen(healthData: data));
            } else if (value == 'delete') {
              _showDeleteDialog(data, context);
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
        ),
      ),
    );
  }

  void _showDeleteDialog(HealthData data, BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este registro?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await controller.deleteHealthData(data.id!);
                ToastService.showSuccess(
                  context,
                  'Registro de saúde excluído com sucesso',
                );
                Get.back();
              } catch (e) {
                print('Erro ao excluir registro de saúde: $e');
                ToastService.showError(
                  context,
                  'Erro ao excluir registro de saúde',
                );
                Get.back();
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
