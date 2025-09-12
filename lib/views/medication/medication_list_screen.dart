import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/widgets/app_header_widget.dart';
import 'package:app_remedio/widgets/expandable_fab_widget.dart';
import 'package:app_remedio/models/action_button_model.dart';
import 'package:app_remedio/views/schedules/add_schedule_screen.dart';
import 'package:app_remedio/views/medication/add_medication_screen.dart';
import 'package:app_remedio/views/medication/edit_medication_screen.dart';

class MedicationListScreen extends GetView<MedicationController> {
  final bool showAppBar;
  const MedicationListScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: showAppBar
          ? AppBar(
              title: Text('Meus Medicamentos', style: heading2Style),
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: primaryColor),
                  onPressed: () => Get.to(
                    () => const AddMedicationScreen(
                      showMedicationListScreen: true,
                    ),
                  ),
                  tooltip: 'Novo Medicamento',
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          if (!showAppBar) ...[
            const AppHeaderWidget(), // Mantido
          ],
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              // ALTERADO: Usa o controller de busca do MedicationController
              decoration: InputDecoration(
                hintText: 'Pesquisar medicamentos...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                prefixIcon: Icon(
                  Icons.search,
                  color: textColor.withOpacity(0.5),
                ),
                // ALTERADO: Usa Obx para reatividade
                suffixIcon: Obx(() {
                  return controller.isSearchTextEmpty.value
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: textColor.withOpacity(0.5),
                          ),
                          onPressed: () {
                            // A lógica de limpar agora pode ser centralizada no controller
                            _clearSearch();
                          },
                        );
                }),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: textColor),
              // ALTERADO: A busca já é acionada pelo listener no controller
              onChanged: (value) => controller.searchMedications(value),
            ),
          ),

          // Lista de medicamentos
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (controller.groupedMedications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_liquid_outlined,
                        size: 64,
                        color: textColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        // ALTERADO: A condição agora usa o controller
                        controller.groupedMedications.isEmpty
                            ? "Nenhum medicamento cadastrado."
                            : "Nenhum medicamento encontrado.",
                        style: bodyTextStyle.copyWith(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Get.to(
                          () => const AddMedicationScreen(
                            showMedicationListScreen: true,
                          ),
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Adicionar Medicamento',
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

              final groupKeys = controller.groupedMedications.keys.toList();
              return ListView.builder(
                // Removido padding desnecessário que conflitava com o margin do grupo
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: groupKeys.length,
                itemBuilder: (context, index) {
                  final letter = groupKeys[index];
                  final medsForLetter = controller.groupedMedications[letter]!;
                  return _buildMedicationGroup(letter, medsForLetter);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: ExpandableFab(
        distance: 80.0,
        heroTag: 'medicationListScreen',
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

  /// Constrói o card de grupo (ex: "A", "B")
  Widget _buildMedicationGroup(String letter, List<Medication> medications) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.05),
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
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              letter,
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
              children: medications
                  .map((med) => _buildMedicationItemCard(med))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o card de um item de medicamento individual
  /// Constrói o card de um item de medicamento individual
  Widget _buildMedicationItemCard(Medication medication) {
    // NOVO: Lógica para decidir entre imagem e ícone
    Widget leadingWidget;
    if (medication.caminhoImagem != null &&
        medication.caminhoImagem!.isNotEmpty) {
      final imageFile = File(medication.caminhoImagem!);
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          imageFile,
          width: 48, // Tamanho da imagem
          height: 48,
          fit: BoxFit.cover,
          // Widget a ser mostrado em caso de erro ao carregar a imagem
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 48,
              height: 48,
              color: Colors.grey[200],
              child: Icon(
                _getMedicationIcon(medication.tipo),
                color: primaryColor,
                size: 24,
              ),
            );
          },
        ),
      );
    } else {
      // Se não houver imagem, usa o ícone padrão
      leadingWidget = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(
          _getMedicationIcon(medication.tipo),
          color: primaryColor,
          size: 24,
        ),
      );
    }

    // ALTERADO: O corpo do widget agora usa o `leadingWidget` que criamos
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.08), width: 1),
      ),
      child: InkWell(
        onTap: () => Get.to(() => EditMedicationScreen(medication: medication)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              leadingWidget, // <--- AQUI ESTÁ A MUDANÇA PRINCIPAL
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estoque: ${medication.estoque} ${medication.tipo.unit}',
                      style: TextStyle(
                        fontSize: 14,
                        color: medication.estoque > 10
                            ? Colors.green.shade600
                            : (medication.estoque > 0
                                  ? Colors.orange.shade700
                                  : Colors.red.shade600),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (medication.observacao != null &&
                        medication.observacao!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        medication.observacao!,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.6)),
                color: surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: textColor, size: 20),
                        const SizedBox(width: 8),
                        Text('Editar', style: TextStyle(color: textColor)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Excluir',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    Get.to(() => EditMedicationScreen(medication: medication));
                  } else if (value == 'delete') {
                    _confirmDelete(medication);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMedicationIcon(MedicationType type) {
    switch (type) {
      case MedicationType.comprimido:
        return Icons.medication;
      case MedicationType.liquido:
        return Icons.water_drop_outlined;
      case MedicationType.injecao:
        return Icons.colorize;
    }
  }

  void _clearSearch() {
    controller.searchMedications('');
  }

  void _confirmDelete(Medication medication) {
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmar Exclusão', style: heading2Style),
        content: Text(
          'Deseja realmente excluir o medicamento "${medication.nome}"?\n\nEsta ação não pode ser desfeita.',
          style: bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ToastService.showInfo(
                Get.context!,
                'Exclusão será implementada em breve',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
