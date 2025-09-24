import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/models/profile_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/widgets/profile_image_widget.dart';
import 'package:app_remedio/utils/widgets_default.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  DateTime? _dataNascimento;

  String? _selectedGenero;
  String? _imagePath;

  final List<String> _generos = ['Masculino', 'Feminino', 'Outro'];

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Novo Perfil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto do perfil
              _buildPhotoSection(profileController),

              const SizedBox(height: 32),

              // Campos do formulário
              _buildFormFields(),

              const SizedBox(height: 32),

              // Botões
              _buildActionButtons(profileController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ProfileController controller) {
    return Column(
      children: [
        ProfileImageWidget(
          imagePath: _imagePath,
          size: 120,
          onTap: () => _selectImage(controller),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _selectImage(controller),
          icon: Icon(
            _imagePath != null ? Icons.edit : Icons.camera_alt,
            color: primaryColor,
          ),
          label: Text(
            _imagePath != null ? 'Alterar Foto' : 'Adicionar Foto',
            style: TextStyle(color: primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome
        const SizedBox(height: 8),
        WidgetsDefault.buildTextField(
          controller: _nomeController,
          label: 'Nome *',
          hint: 'Ex: João da Silva',
          keyboardType: TextInputType.text,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Nome é obrigatório';
            }
            if (v.trim().length < 2) {
              return 'Nome deve ter pelo menos 2 caracteres';
            }
            return null;
          },
        ),

        const SizedBox(height: 20),

        // Data de Nascimento
        WidgetsDefault.buildDateField(
          label: 'Data de Nascimento',
          value: _dataNascimento,
          onTap: _selectDate,
          isRequired: false,
          validator: (value) {
            if (value != null && value.isAfter(DateTime.now())) {
              return 'Data não pode ser no futuro';
            }
            return null;
          },
        ),

        const SizedBox(height: 20),

        // Gênero
        Text('Gênero', style: heading2Style),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGenero,
          dropdownColor: surfaceColor, // 🔹 controla a cor de fundo do dropdown
          style: TextStyle(color: textColor), // 🔹 estilo do texto dos itens
          decoration: InputDecoration(
            filled: true,
            fillColor: backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: secondaryColor, width: 2),
            ),
          ),
          hint: Text(
            // 🔹 aqui sim aparece a hint
            'Selecione o gênero',
            style: TextStyle(color: textColor.withValues(alpha: 0.5)),
          ),
          items: _generos.map((genero) {
            return DropdownMenuItem(
              value: genero,
              child: Text(
                genero,
                style: TextStyle(color: textColor), // 🔹 garante contraste
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGenero = value;
            });
          },
        ),

      ],
    );
  }

  Widget _buildActionButtons(ProfileController controller) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => _saveProfile(controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Salvar Perfil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: textColor.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Future<void> _selectImage(ProfileController controller) async {
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
          _imagePath = savedImage.path;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecionar data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked != null) {
      setState(() {
        _dataNascimento = picked;
      });
    }
  }

  Future<void> _saveProfile(ProfileController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Converte data para formato ISO
    String? dataNascimentoISO;
    if (_dataNascimento != null) {
      dataNascimentoISO = _dataNascimento!.toIso8601String();
    }

    final profile = Profile(
      nome: _nomeController.text.trim(),
      dataNascimento: dataNascimentoISO,
      genero: _selectedGenero,
      caminhoImagem: _imagePath,
    );

    final success = await controller.createProfile(profile);
    if (success) {
      Get.back();
    }
  }
}
