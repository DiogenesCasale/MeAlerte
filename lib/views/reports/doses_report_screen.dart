import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/report_controller.dart';
import 'package:app_remedio/utils/constants.dart';

class DosesReportScreen extends StatelessWidget {
  const DosesReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializa o controller
    final reportController = Get.put(ReportController());

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Relatório de Doses', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtros de período
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPeriodChip(
                      'Última Semana',
                      ReportPeriod.lastWeek,
                      reportController,
                    ),
                    _buildPeriodChip(
                      'Último Mês',
                      ReportPeriod.lastMonth,
                      reportController,
                    ),
                    _buildPeriodChip(
                      'Últimos 3 Meses',
                      ReportPeriod.last3Months,
                      reportController,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Seletor de datas personalizado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _buildDateButton(
                      context,
                      'De:',
                      reportController.startDate.value,
                      (date) {
                        reportController.setCustomPeriod(
                          date,
                          reportController.endDate.value,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateButton(
                      context,
                      'Até:',
                      reportController.endDate.value,
                      (date) {
                        reportController.setCustomPeriod(
                          reportController.startDate.value,
                          date,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Estatísticas
          Obx(() {
            if (reportController.isLoading.value) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.all(16),
              color: surfaceColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          reportController.totalDoses.value.toString(),
                          Icons.medication,
                          primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Tomadas',
                          reportController.dosesTaken.value.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Perdidas',
                          reportController.dosesMissed.value.toString(),
                          Icons.cancel,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getAdherenceGradient(
                          reportController.adherenceRate.value,
                        ),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _getAdherenceColor(
                            reportController.adherenceRate.value,
                          ).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Taxa de Aderência',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${reportController.adherenceRate.value.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                  const Text(
                                    '%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getAdherenceMessage(
                                  reportController.adherenceRate.value,
                                ),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getAdherenceIcon(
                              reportController.adherenceRate.value,
                            ),
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Lista de doses
          Expanded(
            child: Obx(() {
              if (reportController.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (reportController.reportData.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_chart_outlined,
                        size: 64,
                        color: textColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma dose encontrada',
                        style: bodyTextStyle.copyWith(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('no período selecionado', style: subtitleTextStyle),
                    ],
                  ),
                );
              }

              // Agrupa doses por data
              final groupedByDate = <String, List<ReportData>>{};
              for (var dose in reportController.reportData) {
                groupedByDate.putIfAbsent(dose.dataTomada, () => []).add(dose);
              }

              final dates = groupedByDate.keys.toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final doses = groupedByDate[date]!;
                  return _buildDateGroup(date, doses);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(
    String label,
    ReportPeriod period,
    ReportController controller,
  ) {
    final isSelected = controller.selectedPeriod.value == period;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            controller.changePeriod(period);
          }
        },
        selectedColor: primaryColor.withOpacity(0.9),
        backgroundColor: surfaceColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? primaryColor : textColor.withOpacity(0.2),
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime) onDateSelected,
  ) {
    final reportController = Get.find<ReportController>();
    final isCustom =
        reportController.selectedPeriod.value == ReportPeriod.custom;

    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          locale: const Locale('pt', 'BR'),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: surfaceColor,
                  onSurface: textColor,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      icon: Icon(
        Icons.calendar_today_outlined,
        size: 18,
        color: textColor.withOpacity(0.7),
      ),
      label: Text(
        '$label ${DateFormat('dd/MM/yy').format(date)}',
        style: bodyTextStyle.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: surfaceColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        side: BorderSide(
          color: isCustom ? primaryColor : Colors.transparent,
          width: isCustom ? 1.5 : 0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.7),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(String date, List<ReportData> doses) {
    final parsedDate = DateTime.parse(date);
    final formattedDate = DateFormat(
      'dd/MM/yyyy - EEEE',
      'pt_BR',
    ).format(parsedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${doses.length} dose${doses.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: doses.map((dose) => _buildDoseCard(dose)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseCard(ReportData dose) {
    final statusColor = dose.wasTaken ? Colors.green : Colors.red;
    final statusIcon = dose.wasTaken ? Icons.check_circle : Icons.cancel;
    final statusText = dose.wasTaken ? 'Tomada' : 'Perdida';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagem do medicamento (se houver)
            if (dose.caminhoImagem != null && dose.caminhoImagem!.isNotEmpty)
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: backgroundColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(dose.caminhoImagem!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.medication,
                      color: textColor.withOpacity(0.3),
                    ),
                  ),
                ),
              ),

            // Informações da dose
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.medicationName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: textColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Agendado: ${dose.horarioAgendado}',
                        style: subtitleTextStyle,
                      ),
                      if (dose.wasTaken &&
                          dose.horarioTomada != dose.horarioAgendado) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• Tomado: ${dose.horarioTomada}',
                          style: subtitleTextStyle.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Dose: ${dose.dose % 1 == 0 ? dose.dose.toInt().toString() : dose.dose.toString()}',
                        style: subtitleTextStyle,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (dose.observacao != null &&
                      dose.observacao!.isNotEmpty &&
                      dose.observacao != 'Dose não tomada') ...[
                    const SizedBox(height: 4),
                    Text(
                      dose.observacao!,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAdherenceIcon(double rate) {
    if (rate >= 90) return Icons.emoji_events;
    if (rate >= 70) return Icons.thumb_up;
    if (rate >= 50) return Icons.trending_up;
    return Icons.trending_down;
  }

  Color _getAdherenceColor(double rate) {
    if (rate >= 90) return const Color(0xFF4CAF50); // Verde excelente
    if (rate >= 70) return const Color(0xFF2196F3); // Azul bom
    if (rate >= 50) return const Color(0xFFFF9800); // Laranja regular
    return const Color(0xFFF44336); // Vermelho ruim
  }

  List<Color> _getAdherenceGradient(double rate) {
    final baseColor = _getAdherenceColor(rate);
    return [baseColor.withOpacity(0.8), baseColor];
  }

  String _getAdherenceMessage(double rate) {
    if (rate >= 90) return 'Excelente! Continue assim! 🎉';
    if (rate >= 70) return 'Muito bom! Você está indo bem! 👍';
    if (rate >= 50) return 'Pode melhorar! Não desista! 💪';
    return 'Vamos tentar melhorar juntos! 🤝';
  }
}
