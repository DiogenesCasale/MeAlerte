import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/annotation_controller.dart';
import 'package:app_remedio/models/annotation_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/views/annotation/add_edit_annotation_screen.dart';

class AnnotationsListScreen extends StatelessWidget {
  const AnnotationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AnnotationController controller = Get.put(AnnotationController());

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Diário de Anotações', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }
        if (controller.annotationsList.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Espaço para o FAB
          itemCount: controller.annotationsList.length,
          itemBuilder: (context, index) {
            final annotation = controller.annotationsList[index];
            return _buildAnnotationCard(annotation, controller, context);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddEditAnnotationScreen()),
        backgroundColor: primaryColor,
        tooltip: 'Nova Anotação',
        child: const Icon(Icons.add, color: Colors.white),
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
              Get.back(); // **CORRIGIDO: Fecha o dialog antes de chamar o toast**
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
          Text("Seu diário está vazio", style: heading2Style),
          const SizedBox(height: 8),
          Text(
            "Use o botão '+' para criar sua primeira anotação.",
            textAlign: TextAlign.center,
            style: bodyTextStyle.copyWith(color: textColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}