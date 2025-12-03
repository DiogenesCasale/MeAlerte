import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/report_controller.dart';
import 'package:app_remedio/utils/constants.dart';

class AdherencePieChart extends StatelessWidget {
  final ReportController controller;

  const AdherencePieChart({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final taken = controller.dosesTaken.value.toDouble();
      final missed = controller.dosesMissed.value.toDouble();
      final lateDoses = controller.dosesLate.value.toDouble();
      final skipped = controller.dosesSkipped.value.toDouble();
      final total = taken + missed + lateDoses + skipped;

      if (total == 0) {
        return const Center(child: Text('Sem dados para o período'));
      }

      return SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: [
              if (taken > 0)
                PieChartSectionData(
                  color: Colors.green,
                  value: taken,
                  title: '${((taken / total) * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (lateDoses > 0)
                PieChartSectionData(
                  color: Colors.orange,
                  value: lateDoses,
                  title: '${((lateDoses / total) * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (missed > 0)
                PieChartSectionData(
                  color: Colors.red,
                  value: missed,
                  title: '${((missed / total) * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (skipped > 0)
                PieChartSectionData(
                  color: Colors.grey,
                  value: skipped,
                  title: '${((skipped / total) * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class DailyTrendBarChart extends StatelessWidget {
  final ReportController controller;

  const DailyTrendBarChart({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final trend = controller.dailyTrend;
      final maxVal = trend.reduce((curr, next) => curr > next ? curr : next);
      final maxY = maxVal > 0 ? maxVal + 1 : 5.0;

      return SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    const style = TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    );
                    String text;
                    switch (value.toInt()) {
                      case 0:
                        text = 'Seg';
                        break;
                      case 1:
                        text = 'Ter';
                        break;
                      case 2:
                        text = 'Qua';
                        break;
                      case 3:
                        text = 'Qui';
                        break;
                      case 4:
                        text = 'Sex';
                        break;
                      case 5:
                        text = 'Sáb';
                        break;
                      case 6:
                        text = 'Dom';
                        break;
                      default:
                        text = '';
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(text, style: style),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= trend.length) {
                      return const SizedBox.shrink();
                    }
                    return Center(
                      child: Text(
                        trend[index].toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: trend.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: primaryColor,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}

class CriticalTimeCard extends StatelessWidget {
  final ReportController controller;

  const CriticalTimeCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.criticalTimeStats;
      final morning = stats['Manhã'] ?? 0;
      final afternoon = stats['Tarde'] ?? 0;
      final night = stats['Noite'] ?? 0;

      String critical = 'Nenhum';
      int max = 0;

      if (morning > max) {
        max = morning;
        critical = 'Manhã';
      }
      if (afternoon > max) {
        max = afternoon;
        critical = 'Tarde';
      }
      if (night > max) {
        max = night;
        critical = 'Noite';
      }

      if (max == 0) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Horário Crítico',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Parabéns!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Você não esqueceu nenhuma dose neste período.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      }

      return Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Horário Crítico (Mais Esquecimentos)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                critical,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text('Você esqueceu $max doses neste período.'),
            ],
          ),
        ),
      );
    });
  }
}
