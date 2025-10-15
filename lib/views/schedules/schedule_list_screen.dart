import 'dart:io';
import 'package:app_remedio/models/profile_model.dart';
import 'package:app_remedio/views/medication/add_medication_screen.dart';
import 'package:app_remedio/views/medication/add_restock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

import 'package:url_launcher/url_launcher.dart'; // Para abrir URLs (WhatsApp)
import 'package:app_remedio/controllers/profile_controller.dart'; // Precisamos do ProfileController para a mensagem

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
            backgroundColor: primaryColor,
          ),
          ActionButtonModel(
            onPressed: () => Get.to(() => const AddRestockScreen()),
            icon: Icon(Icons.add, color: Colors.white),
            label: 'Nova Reposição/Saída',
            backgroundColor: primaryColor,
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
        builder: (modalBuilderContext, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
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
                  if (dose.caminhoImagem != null &&
                      dose.caminhoImagem!.isNotEmpty)
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
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
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
                                    stockMessage =
                                        'ATENÇÃO: Medicamento em falta!';
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
                                      Icon(
                                        stockIcon,
                                        color: stockColor,
                                        size: 24,
                                      ),
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
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
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
                  if (dose.observacao != null &&
                      dose.observacao!.isNotEmpty) ...[
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
                    icon: Icon(Icons.share, color: backgroundColor),
                    label: Text(
                      'Compartilhar',
                      style: TextStyle(color: backgroundColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: backgroundColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        _shareMedication(context, modalBuilderContext, dose),
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
      margin: const EdgeInsets.only(bottom: 16.0), // Era 24.0
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12), // Era 16.0
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.1),
            blurRadius: 6, // Era 8.0
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8), // Era 16.0
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12), // Era 16.0
                topRight: Radius.circular(12), // Era 16.0
              ),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 20, // Era 18.0
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(3.0), // Era 8.0
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
      margin: const EdgeInsets.only(bottom: 6.0), // Era 8.0
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10), // Era 12.0
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _showDoseDetailsModal(Get.context!, dose),
        borderRadius: BorderRadius.circular(10), // Era 12.0
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Era 16.0
          child: Row(
            children: [
              // Indicador de status visual
              // Indicador de status visual, agora clicável
              InkWell(
                // Ação que será executada ao tocar no ícone
                onTap: () {
                  // Mostra um feedback visual de toque e depois chama a função
                  _markAsTaken(dose);
                },
                // Deixa o efeito "ripple" do toque circular, mais bonito para um ícone
                borderRadius: BorderRadius.circular(30.0),
                child: Padding(
                  // Adiciona um espaçamento para aumentar a área de toque (hitbox)
                  // tornando mais fácil para o usuário clicar
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
              ),
            
              // Não precisa mais de um SizedBox aqui, o padding do InkWell já cria um espaço
              const SizedBox(width: 6), // Remova ou ajuste se necessário

              // --- FIM DA MODIFICAÇÃO ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dose.medicationName,
                      style: TextStyle(
                        fontSize: 14, // Era 16.0
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2), // Era 4.0
                    Row(
                      children: [
                        Text(
                          'Dose: ${dose.dose % 1 == 0 ? dose.dose.toInt().toString() : dose.dose.toString()}',
                          style: subtitleTextStyle,
                        ),
                        const SizedBox(width: 6), // Era 8.0
                        // Indicador de status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4, // Era 6.0
                            vertical: 1, // Era 2.0
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6), // Era 8.0
                          ),
                          child: Text(
                            dose.status.displayName,
                            style: TextStyle(
                              fontSize: 12, // Era 10.0
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (dose.observacao != null &&
                            dose.observacao!.isNotEmpty) ...[
                          const SizedBox(width: 6), // Era 8.0
                          Icon(
                            Icons.info_outline,
                            size: 12, // Era 14.0
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                    if (dose.observacao != null &&
                        dose.observacao!.isNotEmpty) ...[
                      const SizedBox(height: 2), // Era 4.0
                      Text(
                        dose.observacao!,
                        style: TextStyle(
                          fontSize: 11, // Era 12.0
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
            ],
          ),
        ),
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

  void _shareMedication(
    BuildContext mainContext,
    BuildContext modalContext,
    TodayDose dose,
  ) {
    // 1. Fecha o modal de detalhes usando o CONTEXTO DO MODAL (modalContext)
    Navigator.of(modalContext).pop();

    // 2. Abre o novo modal usando o CONTEXTO PRINCIPAL (mainContext)
    // Adiciona um pequeno delay para garantir que o primeiro modal foi completamente removido da árvore de widgets
    Future.delayed(const Duration(milliseconds: 100), () {
      _showShareOptionsModal(mainContext, dose);
    });
  }

  void _showShareOptionsModal(BuildContext context, TodayDose dose) async {
    // Busca o controller do perfil para pegar a mensagem personalizada
    final ProfileController profileController = Get.find<ProfileController>();
    final Profile? currentLoadedProfile =
        profileController.currentProfile.value;

    // Espera (await) o resultado da busca no banco de dados
    final Profile? freshProfile = await profileController.getProfileById(
      currentLoadedProfile?.id,
    );

    // Agora 'freshProfile' é um objeto Profile (ou null), e não mais um Future.
    final String customMessageTemplate =
        freshProfile?.mensagemCompartilhar ?? defaultMessageTemplate;

    // Monta a mensagem final substituindo os placeholders
    final String doseAmount = dose.dose % 1 == 0
        ? dose.dose.toInt().toString()
        : dose.dose.toString();
    final String timeFormatted = DateFormat('HH:mm').format(dose.scheduledTime);

    // Substitui as variáveis na mensagem do perfil
    String shareMessage = customMessageTemplate
        .replaceAll('{nomePerfil}', freshProfile?.nome ?? 'Usuário')
        .replaceAll('{remedio}', dose.medicationName)
        .replaceAll('{dose}', doseAmount)
        .replaceAll('{hora}', timeFormatted);

    // Adiciona observação se houver
    if (dose.observacao != null && dose.observacao!.isNotEmpty) {
      shareMessage += '\n\n*Observação:* ${dose.observacao}';
    }

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
            Text(
              'Compartilhar Agendamento',
              textAlign: TextAlign.center,
              style: heading2Style,
            ),
            const SizedBox(height: 8),
            Text(
              dose.medicationName,
              textAlign: TextAlign.center,
              style: bodyTextStyle.copyWith(color: textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: Icon(Icons.copy, color: backgroundColor),
              label: Text(
                'Copiar Mensagem',
                style: TextStyle(color: backgroundColor),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: shareMessage));

                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();

                  // MUDANÇA PRINCIPAL AQUI
                  // Usamos Get.overlayContext para garantir que temos um contexto válido
                  // para mostrar o Toast, em vez de usar o 'context' que foi passado.
                  final overlayContext = Get.overlayContext;
                  if (overlayContext != null) {
                    ToastService.showSuccess(
                      overlayContext,
                      'Mensagem copiada!',
                    );
                  }
                } catch (e) {
                  print("Erro ao copiar e fechar modal: $e");
                  final overlayContext = Get.overlayContext;
                  if (overlayContext != null) {
                    ToastService.showError(
                      overlayContext,
                      'Erro ao copiar mensagem.',
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: Icon(
                Icons.chat_bubble_outline,
                color: backgroundColor,
              ), // Ícone do WhatsApp
              label: Text(
                'Enviar pelo WhatsApp',
                style: TextStyle(color: backgroundColor),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // Cor do WhatsApp
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final Uri whatsappUrl = Uri.parse(
                  'https://wa.me/?text=${Uri.encodeComponent(shareMessage)}',
                );

                if (await canLaunchUrl(whatsappUrl)) {
                  await launchUrl(
                    whatsappUrl,
                    mode: LaunchMode.externalApplication,
                  );
                  if (context.mounted) Navigator.of(ctx).pop();
                } else {
                  if (context.mounted) {
                    final overlayContext = Get.overlayContext;
                    Navigator.of(ctx).pop();
                    if (overlayContext != null) {
                      ToastService.showError(
                        overlayContext,
                        'Não foi possível abrir o WhatsApp.',
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
          TextButton(
            onPressed: () => _confirmDeleteSingle(dose),
            child: Text(
              'Apenas este horário',
              style: TextStyle(color: Colors.orange),
            ),
          ),
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
      ToastService.showSuccess(context, '$medicationName');
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
