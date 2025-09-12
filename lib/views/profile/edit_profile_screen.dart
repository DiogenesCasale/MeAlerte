import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/models/profile_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/widgets/profile_image_widget.dart';
import 'package:app_remedio/utils/widgets_default.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _pesoController;

  DateTime? _dataNascimento;
  String? _selectedGenero;
  String? _imagePath;
  String? _originalImagePath;

  final List<String> _generos = ['Masculino', 'Feminino', 'Outro'];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nomeController = TextEditingController(text: widget.profile.nome);
    _selectedGenero = widget.profile.genero;
    _imagePath = widget.profile.caminhoImagem;
    _originalImagePath = widget.profile.caminhoImagem;

    // Converter data de nascimento
    if (widget.profile.dataNascimento != null) {
      try {
        _dataNascimento = DateTime.parse(widget.profile.dataNascimento!);
      } catch (e) {
        _dataNascimento = null;
      }
    }

    // Peso
    _pesoController = TextEditingController(
      text: widget.profile.peso?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _pesoController.dispose();
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
          'Editar Perfil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          if (profileController.profiles.length > 1)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteProfile(profileController),
              tooltip: 'Excluir Perfil',
            ),
        ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => _selectImage(controller),
              icon: Icon(Icons.edit, color: primaryColor),
              label: Text(
                'Alterar Foto',
                style: TextStyle(color: primaryColor),
              ),
            ),
            if (_imagePath != null) ...[
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Remover',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome
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

        const SizedBox(height: 20),

        // Peso
        WidgetsDefault.buildTextField(
          controller: _pesoController,
          label: 'Peso (kg) *',
          hint: 'Ex: 70',
          keyboardType: TextInputType.numberWithOptions(decimal: true)
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
                      'Salvar Alterações',
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

        if (controller.profiles.length > 1) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _deleteProfile(controller),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Excluir Perfil',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectImage(ProfileController controller) async {
    final imagePath = await controller.showImageSourceDialog();
    if (imagePath != null) {
      setState(() {
        _imagePath = imagePath;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
  }

  Future<void> _selectDate() async {
    final initialDate = _dataNascimento ?? DateTime.now().subtract(const Duration(days: 365 * 20));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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

  Future<void> _deleteProfile(ProfileController controller) async {
    final success = await controller.deleteProfile(widget.profile);
    if (success) {
      Get.back();
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

    // Converte peso
    double? peso;
    if (_pesoController.text.isNotEmpty) {
      peso = double.tryParse(_pesoController.text.replaceAll(',', '.'));
    }

    // Remove imagem anterior se foi alterada
    if (_originalImagePath != null &&
        _originalImagePath != _imagePath &&
        _originalImagePath!.isNotEmpty) {
      await controller.deleteImage(_originalImagePath!);
    }

    final updatedProfile = widget.profile.copyWith(
      nome: _nomeController.text.trim(),
      dataNascimento: dataNascimentoISO,
      genero: _selectedGenero,
      peso: peso,
      caminhoImagem: _imagePath,
    );

    final success = await controller.updateProfile(updatedProfile);
    if (success) {
      Get.back();
    }
  }
}
