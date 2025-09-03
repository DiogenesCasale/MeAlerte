import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final MedicationController controller = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _doseController = TextEditingController();
  final _intervalController = TextEditingController();
  final _durationController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _medicationSearchController = TextEditingController();
  final _medicationFocusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();

  Medication? _selectedMedication;
  TimeOfDay _selectedTime = TimeOfDay.now();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _medicationFocusNode.addListener(() {
      if (_medicationFocusNode.hasFocus) {
        _showDropdown();
      } else {
        _hideDropdown();
      }
    });
  }

  @override
  void dispose() {
    _hideDropdown();
    _doseController.dispose();
    _intervalController.dispose();
    _durationController.dispose();
    _observacaoController.dispose();
    _medicationSearchController.dispose();
    _medicationFocusNode.dispose();
    super.dispose();
  }

  void _showDropdown() {
    _hideDropdown(); // Remove qualquer dropdown existente
    
    final RenderBox? textFieldBox = _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (textFieldBox == null) return;
    
    final Offset textFieldPosition = textFieldBox.localToGlobal(Offset.zero);
    final Size textFieldSize = textFieldBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: textFieldPosition.dx,
        top: textFieldPosition.dy + textFieldSize.height + 4,
        width: textFieldSize.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: surfaceColor,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor.withValues(alpha: 0.2)),
            ),
            child: Obx(() {
              final medications = controller.filteredMedications;
              if (medications.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nenhum medicamento encontrado',
                        style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          _hideDropdown();
                          _medicationFocusNode.unfocus();
                          _showAddMedicationDialog();
                        },
                        icon: Icon(Icons.add, color: primaryColor),
                        label: Text('Cadastrar Novo', style: TextStyle(color: primaryColor)),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: medications.length + 1, // +1 para o botão "Cadastrar Novo"
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: textColor.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  if (index == medications.length) {
                    // Botão "Cadastrar Novo" no final da lista
                    return InkWell(
                      onTap: () {
                        _hideDropdown();
                        _medicationFocusNode.unfocus();
                        _showAddMedicationDialog();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.add, color: primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Cadastrar novo medicamento',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final medication = medications[index];
                  return InkWell(
                    onTap: () => _onMedicationSelected(medication),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.medication, color: primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medication.nome,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Estoque: ${medication.quantidade}',
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _addScheduledMedication() async {
    if (!_formKey.currentState!.validate()) {
      ToastService.showError(context, 'Por favor, corrija os campos destacados.');
      return;
    }

    if (_selectedMedication == null) {
      ToastService.showError(context, 'Por favor, selecione um medicamento.');
      return;
    }

    try {
      final scheduledMedication = ScheduledMedication(
        medicamentoId: _selectedMedication!.id!,
        dose: double.parse(_doseController.text.trim()),
        hora: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        intervalo: int.parse(_intervalController.text),
        dias: int.parse(_durationController.text),
        observacao: _observacaoController.text.trim().isEmpty ? null : _observacaoController.text.trim(),
      );
      
      await controller.addScheduledMedication(scheduledMedication);
      
      ToastService.showSuccess(context, 'Medicamento agendado com sucesso!');
      Get.back();
    } catch (e) {
      ToastService.showError(context, 'Erro ao agendar medicamento. Tente novamente.');
    }
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final observacaoController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Novo Medicamento', style: heading2Style),
        content: Form(
          key: dialogFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome *',
                  labelStyle: TextStyle(color: textColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  filled: true,
                  fillColor: backgroundColor,
                ),
                style: TextStyle(color: textColor),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: stockController,
                decoration: InputDecoration(
                  labelText: 'Quantidade *',
                  labelStyle: TextStyle(color: textColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  filled: true,
                  fillColor: backgroundColor,
                ),
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Quantidade é obrigatória';
                  }
                  final quantity = int.tryParse(v);
                  if (quantity == null || quantity < 0) {
                    return 'Quantidade deve ser um número ≥ 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: observacaoController,
                decoration: InputDecoration(
                  labelText: 'Observações',
                  labelStyle: TextStyle(color: textColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  filled: true,
                  fillColor: backgroundColor,
                ),
                style: TextStyle(color: textColor),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dialogFormKey.currentState!.validate()) {
                try {
                  await controller.addNewMedication(
                    nameController.text.trim(),
                    int.parse(stockController.text),
                    observacaoController.text.trim().isEmpty ? null : observacaoController.text.trim(),
                  );
                  Get.back();
                  ToastService.showSuccess(context, 'Medicamento adicionado com sucesso!');
                } catch (e) {
                  ToastService.showError(context, 'Erro ao adicionar medicamento. Tente novamente.');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onMedicationSelected(Medication medication) {
    setState(() {
      _selectedMedication = medication;
      _medicationSearchController.text = medication.nome;
    });
    _hideDropdown();
    _medicationFocusNode.unfocus();
  }

  void _onSearchChanged(String query) {
    controller.searchMedications(query);
    if (query.isEmpty) {
      setState(() {
        _selectedMedication = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Novo Agendamento', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          _medicationFocusNode.unfocus();
          _hideDropdown();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Medicamento *', style: heading2Style),
                const SizedBox(height: 8),
                
                // Campo de busca/seleção unificado
                TextFormField(
                  key: _textFieldKey,
                  controller: _medicationSearchController,
                  focusNode: _medicationFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Digite o nome do medicamento...',
                    hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedMedication != null)
                          IconButton(
                            icon: Icon(Icons.clear, color: textColor),
                            onPressed: () {
                              setState(() {
                                _selectedMedication = null;
                                _medicationSearchController.clear();
                              });
                              controller.searchMedications('');
                              _hideDropdown();
                            },
                          ),
                        Icon(_overlayEntry != null ? Icons.expand_less : Icons.expand_more, color: textColor),
                        const SizedBox(width: 8),
                      ],
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    filled: true,
                    fillColor: backgroundColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  onChanged: _onSearchChanged,
                  validator: (value) => _selectedMedication == null ? 'Selecione um medicamento' : null,
                ),
                
                const SizedBox(height: 20),
                
                _buildTextField(
                  controller: _doseController, 
                  label: 'Dose (quantidade) *', 
                  hint: 'Ex: 1, 2, 0.5',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Dose é obrigatória';
                    }
                    final dose = double.tryParse(v.trim());
                    if (dose == null || dose <= 0) {
                      return 'Dose deve ser um número > 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                _buildTimePicker('Hora Início *', '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}', _selectTime),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _intervalController, 
                        label: 'Intervalo (horas) *', 
                        hint: '8', 
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Intervalo é obrigatório';
                          }
                          final interval = int.tryParse(v);
                          if (interval == null || interval <= 0) {
                            return 'Intervalo deve ser > 0';
                          }
                          return null;
                        },
                      )
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _durationController, 
                        label: 'Duração (dias) *', 
                        hint: '7', 
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Duração é obrigatória';
                          }
                          final duration = int.tryParse(v);
                          if (duration == null || duration <= 0) {
                            return 'Duração deve ser > 0';
                          }
                          return null;
                        },
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                _buildTextField(
                  controller: _observacaoController,
                  label: 'Observações',
                  hint: 'Observações adicionais (opcional)',
                  maxLines: 3,
                ),
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: _addScheduledMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Agendar Medicamento', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: surfaceColor,
                hourMinuteTextColor: textColor,
                dialHandColor: primaryColor,
                dialBackgroundColor: surfaceColor,
                dialTextColor: textColor,
                entryModeIconColor: textColor,
                dayPeriodTextColor: textColor,
                dayPeriodColor: surfaceColor,
                dayPeriodBorderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                helpTextStyle: TextStyle(color: textColor),
                hourMinuteTextStyle: TextStyle(color: textColor, fontSize: 24),
                inputDecorationTheme: InputDecorationTheme(
                  fillColor: surfaceColor,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Widget _buildTimePicker(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: heading2Style),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: TextStyle(color: textColor)),
                Icon(Icons.access_time, size: 18, color: textColor),
              ]
            )
          )
        )
      ]
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: heading2Style),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
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
          validator: validator,
        )
      ]
    );
  }
}
