import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/annotation_controller.dart';
import 'package:app_remedio/models/annotation_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';

class AddEditAnnotationScreen extends StatefulWidget {
  final Annotation? annotation;

  const AddEditAnnotationScreen({super.key, this.annotation});

  @override
  State<AddEditAnnotationScreen> createState() => _AddEditAnnotationScreenState();
}

class _AddEditAnnotationScreenState extends State<AddEditAnnotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final AnnotationController _controller = Get.find();
  bool get _isEditing => widget.annotation != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _textController.text = widget.annotation!.anotacao;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveAnnotation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    Get.focusScope?.unfocus();

    bool success;
    if (_isEditing) {
      final updatedAnnotation = Annotation(
        id: widget.annotation!.id,
        idPerfil: widget.annotation!.idPerfil,
        anotacao: _textController.text.trim(),
        dataCriacao: widget.annotation!.dataCriacao,
        dataAtualizacao: DateTime.now().toIso8601String(),
      );
      success = await _controller.updateAnnotation(updatedAnnotation);
    } else {
      success = await _controller.addAnnotation(_textController.text.trim());
    }

    final overlayContext = Get.overlayContext;
    if (overlayContext != null) {
      if (success) {
        Get.back();
        ToastService.showSuccess(overlayContext, 'Anotação salva com sucesso!');
      } else {
        ToastService.showError(overlayContext, 'Não foi possível salvar a anotação.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Anotação' : 'Nova Anotação', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.check_circle_outline, color: primaryColor, size: 28),
              onPressed: _saveAnnotation,
              tooltip: 'Salvar Anotação',
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextFormField(
              controller: _textController,
              autofocus: true,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              style: bodyTextStyle.copyWith(fontSize: 16),
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Digite sua anotação aqui...',
                hintStyle: bodyTextStyle.copyWith(color: textColor.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'A anotação não pode estar vazia.';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }
}