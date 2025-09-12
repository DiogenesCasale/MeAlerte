import 'dart:io';
import 'package:app_remedio/views/medication/add_medication_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:app_remedio/views/schedules/add_schedule_screen.dart';
import 'package:app_remedio/views/schedules/edit_schedule_screen.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/widgets/expandable_fab_widget.dart';
import 'package:app_remedio/widgets/date_selector_widget.dart';
import 'package:app_remedio/widgets/app_header_widget.dart';
import 'package:app_remedio/models/action_button_model.dart';
import 'package:intl/intl.dart';

class ScheduleListScreen extends GetView<SchedulesController> {
  final bool showAppBar;
  const ScheduleListScreen({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    final SchedulesController schedulesController =
        Get.find<SchedulesController>();
    final ThemeController themeController = Get.find();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: showAppBar
          ? AppBar(
              title: Text('Agendamentos de Hoje', style: heading2Style),
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              centerTitle: true,
              elevation: 0,
              actions: [
                Obx(
                  () => IconButton(
                    icon: Icon(
                      themeController.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: textColor,
                    ),
                    onPressed: () => themeController.toggleTheme(),
                    tooltip: themeController.isDarkMode
                        ? 'Tema Claro'
                        : 'Tema Escuro',
                  ),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          // Cabeçalho e seleção de dias (só mostra quando não tem AppBar)
          if (!showAppBar) ...[
            const AppHeaderWidget(),
            const DateSelectorWidget(),
          ],

          // Conteúdo principal
          Expanded(
            child: Obx(() {
              if (schedulesController.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }
              if (schedulesController.groupedDoses.isEmpty) {
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
                        onPressed: () =>
                            Get.to(() => const AddScheduleScreen()),
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text(
                          'Agendar Medicamento',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final timeKeys = schedulesController.groupedDoses.keys.toList();
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: timeKeys.length,
                itemBuilder: (context, index) {
                  final time = timeKeys[index];
                  final dosesForTime = schedulesController.groupedDoses[time]!;
                  return _buildTimeGroup(time, dosesForTime);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: ExpandableFab(
        distance: 80.0,
        heroTag: 'scheduleListScreen',
        children: [
          ActionButtonModel(
            onPressed: () => Get.to(() => const AddScheduleScreen()),
            icon: Icon(Icons.schedule, color: Colors.white),
            label: 'Novo Agendamento',
            backgroundColor: primaryColor,
          ),
          ActionButtonModel(
            onPressed: () => Get.to(
              () => const AddMedicationScreen(showMedicationListScreen: true),
            ),
            icon: Icon(Icons.medication, color: Colors.white),
            label: 'Novo Medicamento',
            backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  void _showDoseDetailsModal(BuildContext context, TodayDose dose) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle visual do modal
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // NOVO: Row para imagem e detalhes
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem do Medicamento
                const SizedBox(width: 2),

                // Detalhes (Nome, Dose, Horário)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dose.medicationName,
                        style: heading1Style.copyWith(
                          fontSize: 24,
                        ), // Fonte maior
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Dose: ${dose.dose % 1 == 0 ? dose.dose.toInt().toString() : dose.dose.toString()}',
                        style: bodyTextStyle.copyWith(
                          fontSize: 16,
                        ), // Fonte maior
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Horário: ${DateFormat('HH:mm').format(dose.scheduledTime)}',
                        style: bodyTextStyle.copyWith(
                          fontSize: 16,
                        ), // Fonte maior
                      ),
                    ],
                  ),
                ),

                if (dose.caminhoImagem != null &&
                    dose.caminhoImagem!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(dose.caminhoImagem!),
                      width: 250,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 250,
                        height: 100,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medication_liquid,
                          color: textColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // NOVO: Divisor e Observações no rodapé
            if (dose.observacao != null && dose.observacao!.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Observações:',
                style: bodyTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dose.observacao!,
                style: bodyTextStyle.copyWith(
                  fontStyle: FontStyle.italic,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Status atual da medicação
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(dose.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(dose.status).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(dose.status),
                    color: _getStatusColor(dose.status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${dose.status.displayName}',
                    style: TextStyle(
                      color: _getStatusColor(dose.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // Botões de ação (dinâmicos baseados no status)
            OutlinedButton.icon(
              icon: Icon(
                dose.status == MedicationStatus.taken 
                    ? Icons.remove_circle_outline 
                    : Icons.check,
                color: dose.status == MedicationStatus.taken 
                    ? Colors.orange 
                    : Colors.green,
              ),
              label: Text(
                dose.status == MedicationStatus.taken 
                    ? 'Desmarcar como Tomado' 
                    : 'Marcar como Tomado',
                style: TextStyle(
                  color: dose.status == MedicationStatus.taken 
                      ? Colors.orange 
                      : Colors.green,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: dose.status == MedicationStatus.taken 
                      ? Colors.orange 
                      : Colors.green,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _markAsTaken(dose),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: Icon(Icons.edit, color: primaryColor),
              label: Text(
                'Editar Agendamento',
                style: TextStyle(color: primaryColor),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _editMedication(dose),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Deletar Agendamento',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _deleteMedication(dose),
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
              children: doses
                  .map((dose) => _buildMedicationCard(dose))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(TodayDose dose) {
    final statusColor = _getStatusColor(dose.status);
    final statusIcon = _getStatusIcon(dose.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showDoseDetailsModal(Get.context!, dose),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Indicador de status visual
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
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
                        const SizedBox(width: 8),
                        // Indicador de status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dose.status.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (dose.observacao != null &&
                            dose.observacao!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                    if (dose.observacao != null &&
                        dose.observacao!.isNotEmpty) ...[
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão de ação baseado no status
                  _buildActionButton(
                    icon: dose.status == MedicationStatus.taken 
                        ? Icons.remove_circle_outline 
                        : Icons.check,
                    color: dose.status == MedicationStatus.taken 
                        ? Colors.orange 
                        : Colors.green,
                    onTap: () {
                      _markAsTaken(dose);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  void _editMedication(TodayDose dose) {
    Get.to(() => EditScheduleScreen(dose: dose));
  }

  void _markAsTaken(TodayDose dose) async {
    final schedulesController = Get.find<SchedulesController>();
    
    try {
      if (dose.status == MedicationStatus.taken) {
        // Se já foi tomada, desmarca
        await schedulesController.unmarkDoseAsTaken(dose.takenDoseId!);
        _showCheckSuccessToast('${dose.medicationName} foi desmarcado');
      } else {
        // Se não foi tomada, marca como tomada
        await schedulesController.markDoseAsTaken(dose);
        _showCheckSuccessToast('${dose.medicationName} foi marcado como tomado');
      }
      Get.back();
    } catch (e) {
      print('Erro ao marcar dose: $e');
      _showErrorToast(message: 'Erro ao atualizar o status da medicação');
    }
  }

  /// Retorna a cor baseada no status da medicação
  Color _getStatusColor(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return Colors.green;
      case MedicationStatus.late:
        return Colors.red;
      case MedicationStatus.upcoming:
        return Colors.orange;
      case MedicationStatus.missed:
        return Colors.purple;
      case MedicationStatus.notTaken:
        return primaryColor;
    }
  }

  /// Retorna o ícone baseado no status da medicação
  IconData _getStatusIcon(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return Icons.check_circle;
      case MedicationStatus.late:
        return Icons.warning;
      case MedicationStatus.upcoming:
        return Icons.access_time;
      case MedicationStatus.missed:
        return Icons.cancel;
      case MedicationStatus.notTaken:
        return Icons.circle_outlined;
    }
  }

  void _deleteMedication(TodayDose dose) {
    final schedulesController = Get.find<SchedulesController>();
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Confirmar Exclusão', style: heading2Style),
        content: Text(
          'Deseja realmente excluir o agendamento de ${dose.medicationName}?',
          style: bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: textColor.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                Get.back(); // Fechar dialog
                await schedulesController.deleteScheduled(
                  dose.scheduledMedicationId,
                );
                _showDeleteSuccessToast(dose.medicationName);
                Get.back();
              } catch (e) {
                print('Erro ao excluir medicamento: $e');
                _showDeleteErrorToast();
                Get.back();
              }
            },
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteSuccessToast(String medicationName) {
    final context = Get.overlayContext;
    if (context != null) {
      ToastService.showSuccess(
        context,
        '$medicationName foi excluído com sucesso',
      );
    }
  }

  void _showCheckSuccessToast(String medicationName) {
    final context = Get.overlayContext;
    if (context != null) {
      ToastService.showSuccess(
        context,
        '$medicationName foi marcado como tomado',
      );
    }
  }

  void _showErrorToast({String message = 'Não foi possível realizar a ação.'}) {
    final context = Get.overlayContext;
    if (context != null) {
      ToastService.showError(context, message);
    }
  }

  void _showDeleteErrorToast() {
    final context = Get.overlayContext;
    if (context != null) {
      ToastService.showError(
        context,
        'Não foi possível excluir o agendamento.',
      );
    }
  }
}
