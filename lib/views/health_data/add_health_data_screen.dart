import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/health_data_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/models/health_data_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:intl/intl.dart';

class AddHealthDataScreen extends StatefulWidget {
  const AddHealthDataScreen({super.key});

  @override
  State<AddHealthDataScreen> createState() => _AddHealthDataScreenState();
}

class _AddHealthDataScreenState extends State<AddHealthDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _valorSistolicaController = TextEditingController();
  final _valorDiastolicaController = TextEditingController();
  final _observacaoController = TextEditingController();
  
  HealthDataType? _selectedType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  final healthDataController = Get.find<HealthDataController>();
  final profileController = Get.find<ProfileController>();

  @override
  void dispose() {
    _valorController.dispose();
    _valorSistolicaController.dispose();
    _valorDiastolicaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Adicionar Dados de Saúde',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 24),
              
              if (_selectedType != null) ...[
                _buildValueInputs(),
                const SizedBox(height: 24),
                
                _buildDateTimeSelector(),
                const SizedBox(height: 24),
                
                _buildObservationField(),
                const SizedBox(height: 32),
                
                _buildSaveButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Dado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<HealthDataType>(
            value: _selectedType,
            decoration: defaultInputDecoration.copyWith(
              hintText: 'Selecione o tipo de dado',
              prefixIcon: Icon(Icons.category, color: primaryColor),
            ),
            items: HealthDataType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.label),
              );
            }).toList(),
            onChanged: (HealthDataType? value) {
              setState(() {
                _selectedType = value;
                _valorController.clear();
                _valorSistolicaController.clear();
                _valorDiastolicaController.clear();
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Selecione um tipo de dado';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildValueInputs() {
    if (_selectedType!.isPressaoArterial) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pressão Arterial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valorSistolicaController,
                    decoration: defaultInputDecoration.copyWith(
                      labelText: 'Sistólica',
                      hintText: '120',
                      prefixIcon: Icon(Icons.favorite, color: primaryColor),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite a pressão sistólica';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Digite um número válido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _valorDiastolicaController,
                    decoration: defaultInputDecoration.copyWith(
                      labelText: 'Diastólica',
                      hintText: '80',
                      prefixIcon: Icon(Icons.favorite_border, color: primaryColor),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite a pressão diastólica';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Digite um número válido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Unidade: ${_selectedType!.unidade}',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              decoration: defaultInputDecoration.copyWith(
                labelText: _selectedType!.label,
                hintText: 'Digite o valor',
                prefixIcon: Icon(_getIconForType(_selectedType!), color: primaryColor),
                suffixText: _selectedType!.unidade,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite um valor';
                }
                if (double.tryParse(value) == null) {
                  return 'Digite um número válido';
                }
                return null;
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDateTimeSelector() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data e Hora',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          dateFormat.format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          timeFormat.format(DateTime(2023, 1, 1, _selectedTime.hour, _selectedTime.minute)),
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObservationField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observações (Opcional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _observacaoController,
            decoration: defaultInputDecoration.copyWith(
              labelText: 'Observações',
              hintText: 'Adicione observações sobre esta medição...',
              prefixIcon: Icon(Icons.note_add, color: primaryColor),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveHealthData,
        icon: _isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save),
        label: Text(
          _isLoading ? 'Salvando...' : 'Salvar Dados',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(HealthDataType type) {
    switch (type) {
      case HealthDataType.peso:
        return Icons.monitor_weight;
      case HealthDataType.altura:
        return Icons.height;
      case HealthDataType.glicose:
        return Icons.bloodtype;
      case HealthDataType.pressaoArterial:
        return Icons.favorite;
      case HealthDataType.frequenciaCardiaca:
        return Icons.favorite_border;
      case HealthDataType.temperatura:
        return Icons.thermostat;
      case HealthDataType.saturacaoOxigenio:
        return Icons.air;
      default:
        return Icons.health_and_safety;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveHealthData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentProfile = profileController.currentProfile.value;
    if (currentProfile?.id == null) {
      ToastService.showError(context, 'Nenhum perfil selecionado');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dataRegistro = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      HealthData healthData;

      if (_selectedType!.isPressaoArterial) {
        healthData = HealthData(
          idPerfil: currentProfile!.id!,
          tipo: _selectedType!.name,
          valorSistolica: double.parse(_valorSistolicaController.text),
          valorDiastolica: double.parse(_valorDiastolicaController.text),
          unidade: _selectedType!.unidade,
          observacao: _observacaoController.text.trim().isEmpty 
            ? null 
            : _observacaoController.text.trim(),
          dataRegistro: dataRegistro.toIso8601String(),
        );
      } else {
        healthData = HealthData(
          idPerfil: currentProfile!.id!,
          tipo: _selectedType!.name,
          valor: double.parse(_valorController.text),
          unidade: _selectedType!.unidade,
          observacao: _observacaoController.text.trim().isEmpty 
            ? null 
            : _observacaoController.text.trim(),
          dataRegistro: dataRegistro.toIso8601String(),
        );
      }

      final success = await healthDataController.addHealthData(healthData);

      if (success) {
        ToastService.showSuccess(context, 'Dados de saúde salvos com sucesso');
        Get.back();
      } else {
        ToastService.showError(context, 'Erro ao salvar dados de saúde');
      }
    } catch (e) {
      ToastService.showError(context, 'Ocorreu um erro inesperado!');
      print('Erro ao salvar dados de saúde: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
