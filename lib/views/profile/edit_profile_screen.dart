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

class EditProfileScreen extends StatefulWidget {
  final Profile profileInitial;

  const EditProfileScreen({super.key, required this.profileInitial});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // ✅ CORREÇÃO: Removido 'late final' para permitir inicialização posterior
  late TextEditingController _nomeController;

  DateTime? _dataNascimento;
  String? _selectedGenero;
  String? _imagePath;
  String? _originalImagePath;
  
  late Future<Profile?> _loadProfileFuture;
  bool _fieldsInitialized = false; // ✅ CORREÇÃO: Flag para controlar a inicialização

  final List<String> _generos = ['Masculino', 'Feminino', 'Outro'];

  @override
  void initState() {
    super.initState();
    // ✅ CORREÇÃO: initState agora é síncrono
    _loadProfileFuture = _loadProfile();
  }

  Future<Profile?> _loadProfile() async {
    final profileController = Get.find<ProfileController>();
    return await profileController.getProfileById(widget.profileInitial.id);
  }

  // Este método inicializa as variáveis e o controller
  void _initializeFields(Profile profile) {
    _nomeController = TextEditingController(text: profile.nome);
    _selectedGenero = profile.genero;
    _imagePath = profile.caminhoImagem;
    _originalImagePath = profile.caminhoImagem;

    if (profile.dataNascimento != null) {
      try {
        _dataNascimento = DateTime.parse(profile.dataNascimento!);
      } catch (e) {
        _dataNascimento = null;
      }
    }
  }

  @override
  void dispose() {
    // ✅ CORREÇÃO: Verificação mais segura antes de chamar dispose
    if (_fieldsInitialized) {
      _nomeController.dispose();
    }
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
      ),
      body: FutureBuilder<Profile?>(
        future: _loadProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Erro ao carregar o perfil.'));
          }

          final profile = snapshot.data!;
          
          // ✅ CORREÇÃO: Inicializa os campos APENAS UMA VEZ
          if (!_fieldsInitialized) {
            _initializeFields(profile);
            _fieldsInitialized = true;
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 32),
                  _buildFormFields(),
                  const SizedBox(height: 32),
                  _buildActionButtons(profileController, profile),
                ],
              ),
            ),
          );
        },
      ),
    );
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
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      if (mounted) {
        setState(() {
          _imagePath = savedImage.path;
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
            if (_imagePath != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remover Foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() {
                    _imagePath = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        ProfileImageWidget(
          imagePath: _imagePath,
          size: 120,
          onTap: _showImageSourceActionSheet,
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetsDefault.buildTextField(
          controller: _nomeController,
          label: 'Nome *',
          hint: 'Ex: João da Silva',
          keyboardType: TextInputType.text,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Nome é obrigatório';
            if (v.trim().length < 2) return 'Nome deve ter pelo menos 2 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 20),
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
        Text('Gênero', style: heading2Style),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGenero,
          dropdownColor: surfaceColor,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: backgroundColor,
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
            hint: Text(
              'Selecione o gênero',
              style: TextStyle(color: textColor.withOpacity(0.5)),
            ),
          ),
          items: _generos.map((genero) {
            return DropdownMenuItem(
              value: genero,
              child: Text(genero, style: TextStyle(color: textColor)),
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

  Widget _buildActionButtons(ProfileController controller, Profile profile) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => _saveProfile(controller, profile),
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
              onPressed: () => _deleteProfile(controller, profile),
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

  Future<void> _selectDate() async {
    final initialDate = _dataNascimento ?? DateTime.now().subtract(const Duration(days: 365 * 20));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() {
        _dataNascimento = picked;
      });
    }
  }

  Future<void> _deleteProfile(ProfileController controller, Profile profile) async {
    final success = await controller.deleteProfile(profile);
    if (success && mounted) {
      Get.back();
    }
  }

  Future<void> _saveProfile(ProfileController controller, Profile profile) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String? dataNascimentoISO;
    if (_dataNascimento != null) {
      dataNascimentoISO = _dataNascimento!.toIso8601String();
    }

    if (_originalImagePath != null &&
        _originalImagePath != _imagePath &&
        _originalImagePath!.isNotEmpty) {
      await controller.deleteImage(_originalImagePath!);
    }

    final updatedProfile = profile.copyWith(
      nome: _nomeController.text.trim(),
      dataNascimento: dataNascimentoISO,
      genero: _selectedGenero,
      caminhoImagem: _imagePath,
    );

    final success = await controller.updateProfile(updatedProfile);
    if (success && mounted) {
      Get.back();
    }
  }
}