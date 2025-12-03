// arquivo: views/annotation/annotations_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/annotation_controller.dart';
import 'package:app_remedio/models/annotation_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/views/annotation/add_edit_annotation_screen.dart';

// Copiado da outra tela
enum DateFilterPreset {
  currentDay,
  currentMonth,
  last3Months,
  last6Months,
  currentYear,
}

// Convertido para StatefulWidget
class AnnotationsListScreen extends StatefulWidget {
  const AnnotationsListScreen({super.key});

  @override
  State<AnnotationsListScreen> createState() => _AnnotationsListScreenState();
}

class _AnnotationsListScreenState extends State<AnnotationsListScreen> {
  // O controller é injetado via Get.put() para garantir uma única instância
  final AnnotationController controller = Get.put(AnnotationController());
  
  DateTime? _startDate;
  DateTime? _endDate;
  DateFilterPreset? _selectedPreset;

  @override
  void initState() {
    super.initState();
    // Define o período inicial e carrega os dados
    _applyDateFilterPreset(DateFilterPreset.currentMonth);
  }

  void _applyDateFilterPreset(DateFilterPreset preset) {
    final now = DateTime.now();
    DateTime newStartDate;
    DateTime newEndDate = now;

    switch (preset) {
      case DateFilterPreset.currentDay:
        newStartDate = DateTime(now.year, now.month, now.day);
        break;
      case DateFilterPreset.currentMonth:
        newStartDate = DateTime(now.year, now.month, 1);
        break;
      case DateFilterPreset.last3Months:
        newStartDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case DateFilterPreset.last6Months:
        newStartDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case DateFilterPreset.currentYear:
        newStartDate = DateTime(now.year, 1, 1);
        break;
    }

    setState(() {
      _startDate = newStartDate;
      _endDate = newEndDate;
      _selectedPreset = preset;
    });
    // Chama o método do controller para aplicar o filtro
    controller.setDateFilter(_startDate!, _endDate!);
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day);
    final lastDate = now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
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

    if (pickedDate != null) {
      setState(() {
        _selectedPreset = null;
        if (isStartDate) {
          _startDate = pickedDate;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 23, 59, 59);
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = pickedDate;
          }
        }
      });
      controller.setDateFilter(_startDate!, _endDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Diário de Anotações', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Widgets de filtro adicionados aqui
          _buildPresetFilters(),
          _buildDateFilterSelectors(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator(color: primaryColor));
              }
              if (controller.annotationsList.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: controller.annotationsList.length,
                itemBuilder: (context, index) {
                  final annotation = controller.annotationsList[index];
                  return _buildAnnotationCard(annotation, controller, context);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddEditAnnotationScreen()),
        backgroundColor: primaryColor,
        tooltip: 'Nova Anotação',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPresetFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPresetChip('Hoje', DateFilterPreset.currentDay),
            _buildPresetChip('Mês Atual', DateFilterPreset.currentMonth),
            _buildPresetChip('Últimos 3 Meses', DateFilterPreset.last3Months),
            _buildPresetChip('Últimos 6 Meses', DateFilterPreset.last6Months),
            _buildPresetChip('Ano Atual', DateFilterPreset.currentYear),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, DateFilterPreset preset) {
    final isSelected = _selectedPreset == preset;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _applyDateFilterPreset(preset);
          }
        },
        selectedColor: primaryColor.withOpacity(0.9),
        backgroundColor: surfaceColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: isSelected ? primaryColor : textColor.withOpacity(0.2)),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildDateFilterSelectors() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              label: 'De:',
              date: _startDate,
              onPressed: () => _pickDate(isStartDate: true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDateButton(
              label: 'Até:',
              date: _endDate,
              onPressed: () => _pickDate(isStartDate: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    final displayDate = date != null ? DateFormat('dd/MM/yy').format(date) : 'Selecione';
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.calendar_today_outlined, size: 18, color: textColor.withOpacity(0.7)),
      label: Text(
        '$label $displayDate',
        style: bodyTextStyle.copyWith(color: textColor, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: surfaceColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(
            color: _selectedPreset == null ? primaryColor : Colors.transparent,
            width: _selectedPreset == null ? 1.5 : 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  Widget _buildAnnotationCard(Annotation annotation, AnnotationController controller, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(() => AddEditAnnotationScreen(annotation: annotation)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  annotation.anotacao,
                  style: bodyTextStyle.copyWith(fontSize: 16, height: 1.5),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: textColor.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy \'às\' HH:mm').format(annotation.dataCriacaoDateTime),
                      style: bodyTextStyle.copyWith(fontSize: 12, color: textColor.withOpacity(0.5)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7)),
                      onPressed: () => _showDeleteDialog(annotation, controller, context),
                      tooltip: 'Excluir Anotação',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Annotation annotation, AnnotationController controller, BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmar Exclusão', style: heading2Style),
        content: Text('Deseja realmente excluir esta anotação?', style: bodyTextStyle),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.deleteAnnotation(annotation.id!);
              final overlayContext = Get.overlayContext;
              if (overlayContext != null) {
                if (success) {
                  ToastService.showSuccess(overlayContext, 'Anotação excluída com sucesso.');
                } else {
                  ToastService.showError(overlayContext, 'Não foi possível excluir a anotação.');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_outlined, size: 80, color: textColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("Nenhuma anotação", style: heading2Style),
          const SizedBox(height: 8),
          Text(
            "As anotações feitas neste período\n aparecerão aqui.",
            textAlign: TextAlign.center,
            style: bodyTextStyle.copyWith(color: textColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}