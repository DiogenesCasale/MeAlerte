import 'dart:io';
import 'package:app_remedio/views/medication/add_medication_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:app_remedio/models/medication_model.dart';
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
            AppHeaderWidget(), // Remove const para permitir rebuilds
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
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
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
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Imagem do medicamento - movida para o topo e maior
              if (dose.caminhoImagem != null && dose.caminhoImagem!.isNotEmpty)
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        _showFullScreenImage(context, dose.caminhoImagem!),
                    child: Hero(
                      tag: 'medicationImage_${dose.scheduledMedicationId}',
                      child: Container(
                        width: 200,
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(dose.caminhoImagem!),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.medication_liquid,
                              color: textColor.withOpacity(0.3),
                              size: 80,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Nome do medicamento
              Text(
                dose.medicationName,
                style: heading1Style.copyWith(fontSize: 24),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Informações da dose e horário
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.medication,
                                color: primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Dose',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dose.dose % 1 == 0 ? dose.dose.toInt().toString() : dose.dose.toString()}',
                            style: bodyTextStyle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Horário',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm').format(dose.scheduledTime),
                            style: bodyTextStyle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Aviso sobre estoque - no lugar onde era a imagem
              FutureBuilder<Medication?>(
                future: Get.find<MedicationController>().getMedicationById(
                  dose.idMedicamento,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final medication = snapshot.data!;
                    return FutureBuilder<bool>(
                      future: Get.find<MedicationController>().isLowStock(
                        dose.idMedicamento,
                      ),
                      builder: (context, lowStockSnapshot) {
                        final isLowStock = lowStockSnapshot.data ?? false;
                        return FutureBuilder<double>(
                          future: Get.find<MedicationController>()
                              .getDaysRemaining(dose.idMedicamento),
                          builder: (context, daysSnapshot) {
                            final daysRemaining = daysSnapshot.data ?? 0;

                            Color stockColor = Colors.green;
                            IconData stockIcon = Icons.inventory;
                            String stockMessage =
                                'Estoque: ${medication.estoque} unidades';

                            if (isLowStock) {
                              stockColor = medication.estoque <= 0
                                  ? Colors.red
                                  : Colors.orange;
                              stockIcon = medication.estoque <= 0
                                  ? Icons.warning
                                  : Icons.warning_amber;

                              if (medication.estoque <= 0) {
                                stockMessage = 'ATENÇÃO: Medicamento em falta!';
                              } else {
                                final daysText = daysRemaining < 1
                                    ? "menos de 1 dia"
                                    : "${daysRemaining.toStringAsFixed(1)} dias";
                                stockMessage =
                                    'ATENÇÃO: Estoque baixo!\n${medication.estoque} unidades (~$daysText restantes)';
                              }
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: stockColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: stockColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(stockIcon, color: stockColor, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      stockMessage,
                                      style: TextStyle(
                                        color: stockColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory, color: Colors.grey, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Carregando informações do estoque...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              // Divisor e Observações
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
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Status atual da medicação
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(dose.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(dose.status).withOpacity(0.3),
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

              // Botões de ação (seu código existente)
              OutlinedButton.icon(
                icon: Icon(
                  dose.status == MedicationStatus.taken
                      ? Icons.remove_circle_outline
                      : Icons.check,
                  color: backgroundColor,
                ),
                label: Text(
                  dose.status == MedicationStatus.taken
                      ? 'Desmarcar como Tomado'
                      : 'Marcar como Tomado',
                  style: TextStyle(color: backgroundColor),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: dose.status == MedicationStatus.taken
                      ? Colors.orange
                      : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: backgroundColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _markAsTaken(dose),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: Icon(Icons.edit, color: backgroundColor),
                label: Text(
                  'Editar Agendamento',
                  style: TextStyle(color: backgroundColor),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: backgroundColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _editMedication(dose),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: Icon(Icons.delete, color: backgroundColor),
                label: Text(
                  'Deletar Agendamento',
                  style: TextStyle(color: backgroundColor),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: backgroundColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _deleteMedication(dose),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(ctx).pop(), // Fecha o dialog ao tocar
            child: InteractiveViewer(
              // Permite zoom e pan na imagem
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(imagePath)),
                ),
              ),
            ),
          ),
        );
      },
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
              Icon(statusIcon, color: statusColor, size: 20),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
    Get.back(); // Fechar o modal primeiro
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
        _showCheckSuccessToast(
          '${dose.medicationName} foi marcado como tomado',
        );
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
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Excluir Agendamento', style: heading2Style),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como você deseja excluir o agendamento de ${dose.medicationName}?',
              style: bodyTextStyle,
            ),
            const SizedBox(height: 16),
            Text(
              'Escolha uma opção:',
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
          ),
          // TODO: Implementar a exclusão de um horário específico
          // TextButton(
          //   onPressed: () => _confirmDeleteSingle(dose),
          //   child: Text(
          //     'Apenas este horário',
          //     style: TextStyle(color: Colors.orange),
          //   ),
          // ),
          TextButton(
            onPressed: () => _confirmDeleteAll(dose),
            child: Text(
              'Todo o agendamento',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSingle(TodayDose dose) {
    Get.back(); // Fechar dialog anterior
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Confirmar Exclusão', style: heading2Style),
        content: Text(
          'Deseja excluir apenas este horário específico de ${dose.medicationName}?\n\nIsso criará uma exceção para este horário, mantendo os demais agendamentos.',
          style: bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                Get.back(); // Fechar dialog de confirmação
                final schedulesController = Get.find<SchedulesController>();
                await schedulesController.deleteSpecificDose(
                  dose.scheduledMedicationId,
                  dose.scheduledTime,
                );
                _showDeleteSuccessToast(
                  'Horário específico de ${dose.medicationName} foi excluído',
                );
                Get.back(); // Fechar modal principal
              } catch (e) {
                print('Erro ao excluir horário específico: $e');
                _showDeleteErrorToast();
              }
            },
            child: Text(
              'Excluir apenas este',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(TodayDose dose) {
    Get.back(); // Fechar dialog anterior
    final schedulesController = Get.find<SchedulesController>();
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Confirmar Exclusão Total', style: heading2Style),
        content: Text(
          'Deseja excluir TODOS os agendamentos de ${dose.medicationName}?\n\nEsta ação não pode ser desfeita e removerá todo o cronograma deste medicamento.',
          style: bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                Get.back();
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
            child: Text('Excluir tudo', style: TextStyle(color: Colors.red)),
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
        '$medicationName',
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
