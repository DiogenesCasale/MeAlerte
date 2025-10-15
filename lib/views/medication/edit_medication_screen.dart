import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/views/main_layout.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/utils/profile_helper.dart';


class EditMedicationScreen extends StatefulWidget {
  final Medication medication;
  final bool showMedicationListScreen;

  const EditMedicationScreen({super.key, required this.medication, this.showMedicationListScreen = false});

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  final MedicationController medicationController = Get.find();
  final _formKey = GlobalKey<FormState>();

  // Controllers para os campos do formulário
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _observacaoController = TextEditingController();

  // Variáveis de estado
  late MedicationType _selectedType;
  File? _imageFile;
  String? _savedImagePath;
  int _observacaoLength = 0;
  static const int _maxObservacaoLength = 250;

  @override
  void initState() {
    super.initState();

    // Preenche os campos com os dados existentes do medicamento
    _nameController.text = widget.medication.nome;
    _observacaoController.text = widget.medication.observacao ?? '';
    _selectedType = widget.medication.tipo;
    _savedImagePath = widget.medication.caminhoImagem;
    _observacaoLength = _observacaoController.text.length;
    _stockController.text = widget.medication.estoque.toString();

    // Carrega a imagem existente, se houver
    if (_savedImagePath != null && _savedImagePath!.isNotEmpty) {
      _imageFile = File(_savedImagePath!);
    }

    // Listener para o contador de caracteres
    _observacaoController.addListener(() {
      if (mounted) {
        setState(() {
          _observacaoLength = _observacaoController.text.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(
        pickedFile.path,
      ).copy('${appDir.path}/$fileName');

      if (mounted) {
        setState(() {
          _imageFile = savedImage;
          _savedImagePath = savedImage.path;
        });
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.photo_library, color: textColor),
              title: Text(
                'Galeria de Fotos',
                style: TextStyle(color: textColor),
              ),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: textColor),
              title: Text('Câmera', style: TextStyle(color: textColor)),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
            if (_imageFile != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Remover Foto',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  setState(() {
                    _imageFile = null;
                    _savedImagePath = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateMedication() async {
    if (!_formKey.currentState!.validate()) {
      ToastService.showError(
        context,
        'Por favor, corrija os campos destacados.',
      );
      return;
    }

    // Verifica se há um perfil ativo
    if (!ProfileHelper.hasActiveProfile) {
      ToastService.showError(context, 'É necessário selecionar um perfil primeiro.');
      return;
    }

    try {
      final updatedMedication = Medication(
        id: widget.medication.id,
        nome: _nameController.text.trim(),
        estoque: double.parse(_stockController.text.trim()),
        observacao: _observacaoController.text.trim().isEmpty
            ? null
            : _observacaoController.text.trim(),
        tipo: _selectedType,
        caminhoImagem: _savedImagePath,
        idPerfil: widget.medication.idPerfil, // Mantém o ID do perfil original
      );

      await medicationController.updateMedication(updatedMedication);

      ToastService.showSuccess(context, 'Medicamento atualizado com sucesso!');
      if (widget.showMedicationListScreen) {
        Get.offAll(() => MainLayout(initialIndex: 1));
      } else {
        Get.back();
      }
    } catch (e) {
      ToastService.showError(
        context,
        'Erro ao atualizar o medicamento: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Editar Medicamento', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Nome do Medicamento *',
                hint: 'Ex: Paracetamol 750mg',
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Nome é obrigatório';
                  if (v.trim().length < 2)
                    return 'Nome deve ter pelo menos 2 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTypeAndStockFields(),
              const SizedBox(height: 20),
              _buildObservationField(),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _updateMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Salvar Alterações',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Os widgets de construção (build) são os mesmos da tela de adicionar,
  // pois eles já leem os valores das variáveis de estado que preenchemos no initState.
  // Vou colar eles aqui para o arquivo ficar completo.

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        children: [
          Text('Foto do Medicamento', style: heading2Style),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showImageSourceActionSheet,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: textColor.withOpacity(0.3)),
                image: _imageFile != null
                    ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _imageFile == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: textColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toque para adicionar',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeAndStockFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo do Medicamento *', style: heading2Style),
              const SizedBox(height: 8),
              DropdownButtonFormField<MedicationType>(
                value: _selectedType,
                dropdownColor: surfaceColor,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(),
                items: MedicationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? MedicationType.comprimido;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: _buildTextField(
            controller: _stockController,
            label: 'Estoque *',
            hint: 'Ex: 30',
            keyboardType: TextInputType.number,
            suffixText: _selectedType.unit,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Obrigatório';
              final stock = int.tryParse(v);
              if (stock == null || stock < 0) return 'Inválido';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildObservationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Observações', style: heading2Style),
            Text(
              '$_observacaoLength/$_maxObservacaoLength',
              style: TextStyle(
                color: _observacaoLength > _maxObservacaoLength
                    ? Colors.red
                    : textColor.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _observacaoController,
          maxLines: 3,
          maxLength: _maxObservacaoLength,
          style: TextStyle(color: textColor),
          decoration: _inputDecoration(
            hint: 'Observações adicionais (opcional)',
          ).copyWith(counterText: ''),
          validator: (value) {
            if (value != null && value.length > _maxObservacaoLength) {
              return 'Máximo de $_maxObservacaoLength caracteres excedido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: heading2Style),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor),
          decoration: _inputDecoration(hint: hint, suffixText: suffixText),
          validator: validator,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, String? suffixText}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffixText,
      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
      filled: true,
      fillColor: backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: textColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: secondaryColor, width: 2),
      ),
    );
  }
}
