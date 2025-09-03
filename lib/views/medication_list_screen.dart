import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:app_remedio/views/add_medication_screen.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/widgets/expandable_fab_widget.dart';
import 'package:app_remedio/models/action_button_model.dart';
import 'package:intl/intl.dart';

class MedicationListScreen extends GetView<MedicationController> {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(MedicationController());
    final ThemeController themeController = Get.find();

    return Obx(() => Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Agendamentos de Hoje', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeController.isDarkMode.value ? Icons.light_mode : Icons.dark_mode,
              color: textColor,
            ),
            onPressed: () => themeController.toggleTheme(),
            tooltip: themeController.isDarkMode.value ? 'Tema Claro' : 'Tema Escuro',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }
        if (controller.groupedDoses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 64,
                  color: textColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "Nenhum agendamento para hoje.",
                  style: bodyTextStyle.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                                 ElevatedButton.icon(
                   onPressed: () => Get.to(() => const AddMedicationScreen()),
                   icon: Icon(Icons.add, color: Colors.white),
                   label: Text('Agendar Medicamento', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }

        final timeKeys = controller.groupedDoses.keys.toList();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: timeKeys.length,
          itemBuilder: (context, index) {
            final time = timeKeys[index];
            final dosesForTime = controller.groupedDoses[time]!;
            return _buildTimeGroup(time, dosesForTime);
          },
        );
      }),
      floatingActionButton: ExpandableFab(
        distance: 80.0,
        children: [
                        ActionButtonModel(
                onPressed: () => Get.to(() => const AddMedicationScreen()),
                icon: Icon(Icons.medication_outlined, color: Colors.white),
                label: 'Novo Agendamento',
                backgroundColor: primaryColor,
              ),
        ],
      ),
    ));
  }

  void _showDoseDetailsModal(BuildContext context, TodayDose dose) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle visual do modal
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(dose.medicationName, style: heading1Style),
            const SizedBox(height: 8),
            Text('Dose: ${dose.dose % 1 == 0 ? dose.dose.toInt().toString() : dose.dose.toString()}', style: bodyTextStyle),
            Text('Horário: ${DateFormat('HH:mm').format(dose.scheduledTime)}', style: bodyTextStyle),
            if (dose.observacao != null && dose.observacao!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Observações: ${dose.observacao}', style: bodyTextStyle),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: Icon(Icons.edit, color: primaryColor),
              label: Text('Editar Agendamento', style: TextStyle(color: primaryColor)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Get.back();
                // TODO: Implementar edição
                Get.snackbar('Em Breve', 'Funcionalidade de edição será implementada.');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeGroup(String time, List<TodayDose> doses) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: doses.map((dose) => _buildMedicationCard(dose)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(TodayDose dose) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showDoseDetailsModal(Get.context!, dose),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dose.medicationName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Dose: ${dose.dose % 1 == 0 ? dose.dose.toInt().toString() : dose.dose.toString()}',
                          style: subtitleTextStyle,
                        ),
                        if (dose.observacao != null && dose.observacao!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                    if (dose.observacao != null && dose.observacao!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dose.observacao!,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: primaryColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
