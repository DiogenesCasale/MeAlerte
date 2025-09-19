import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/utils/profile_helper.dart';
import 'package:app_remedio/views/main_layout.dart';

class AddMedicationScreen extends StatefulWidget {
  final bool showMedicationListScreen;
  const AddMedicationScreen({super.key, this.showMedicationListScreen = false});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final MedicationController medicationController = Get.find();
  final _formKey = GlobalKey<FormState>();

  // Controllers para os campos do formulário
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _observacaoController = TextEditingController();

  // Variáveis de estado
  MedicationType _selectedType = MedicationType.comprimido;
  File? _imageFile;
  String? _savedImagePath;
  int _observacaoLength = 0;
  static const int _maxObservacaoLength = 250;

  @override
  void initState() {
    super.initState();
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
      imageQuality: 80, // Comprime um pouco a imagem para economizar espaço
      maxWidth: 1024,
    );

    if (pickedFile != null) {
      // Salva a imagem no diretório seguro do app
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
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
              title: Text('Galeria de Fotos', style: TextStyle(color: textColor)),
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
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      ToastService.showError(context, 'Por favor, corrija os campos destacados.');
      return;
    }

    // Verifica se há um perfil ativo
    if (!ProfileHelper.hasActiveProfile) {
      ToastService.showError(context, 'É necessário selecionar um perfil primeiro.');
      return;
    }

    try {
      final newMedication = Medication(
        nome: _nameController.text.trim(),
        estoque: int.parse(_stockController.text.trim()),
        observacao: _observacaoController.text.trim().isEmpty 
          ? null 
          : _observacaoController.text.trim(),
        tipo: _selectedType,
        caminhoImagem: _savedImagePath,
        idPerfil: ProfileHelper.currentProfileId, // Usa o ProfileHelper
      );
      
      await medicationController.addNewMedication(newMedication);

      ToastService.showSuccess(context, 'Medicamento salvo com sucesso!');

      if(widget.showMedicationListScreen) {
        Get.offAll(() => MainLayout(initialIndex: 1));
      } else {
        Get.back();
      }

    } catch (e) {
      ToastService.showError(context, 'Erro ao salvar o medicamento: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Novo Medicamento', style: heading2Style),
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
                  if (v == null || v.trim().isEmpty) return 'Nome é obrigatório';
                  if (v.trim().length < 2) return 'Nome deve ter pelo menos 2 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTypeAndStockFields(),
              const SizedBox(height: 20),
              _buildObservationField(),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salvar Medicamento', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                          Icon(Icons.camera_alt, size: 40, color: textColor.withOpacity(0.5)),
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
        // Seletor de Tipo
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
        // Campo de Estoque
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
        )
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