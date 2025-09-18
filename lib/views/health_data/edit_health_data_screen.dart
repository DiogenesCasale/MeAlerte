import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/health_data_controller.dart';
import 'package:app_remedio/models/health_data_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/utils/toast_service.dart';

class EditHealthDataScreen extends StatefulWidget {
  final HealthData healthData;
  
  const EditHealthDataScreen({
    super.key,
    required this.healthData,
  });

  @override
  State<EditHealthDataScreen> createState() => _EditHealthDataScreenState();
}

class _EditHealthDataScreenState extends State<EditHealthDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _valorSistolicaController = TextEditingController();
  final _valorDiastolicaController = TextEditingController();
  final _observacaoController = TextEditingController();
  
  late HealthDataType? _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;

  final healthDataController = Get.find<HealthDataController>();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _selectedType = HealthDataType.fromString(widget.healthData.tipo);
    
    final dataRegistro = widget.healthData.dataRegistroDateTime;
    _selectedDate = dataRegistro;
    _selectedTime = TimeOfDay.fromDateTime(dataRegistro);
    
    if (_selectedType?.isPressaoArterial == true) {
      _valorSistolicaController.text = widget.healthData.valorSistolica?.toString() ?? '';
      _valorDiastolicaController.text = widget.healthData.valorDiastolica?.toString() ?? '';
    } else {
      _valorController.text = widget.healthData.valor?.toString() ?? '';
    }
    
    _observacaoController.text = widget.healthData.observacao ?? '';
  }

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
          'Editar Dados de Saúde',
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
              _buildTypeInfo(),
              const SizedBox(height: 24),
              
              _buildValueInputs(),
              const SizedBox(height: 24),
              
              _buildDateTimeSelector(),
              const SizedBox(height: 24),
              
              _buildObservationField(),
              const SizedBox(height: 32),
              
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForType(_selectedType!),
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de Dado',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
                Text(
                  _selectedType?.label ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
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
        onPressed: _isLoading ? null : _updateHealthData,
        icon: _isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save),
        label: Text(
          _isLoading ? 'Salvando...' : 'Salvar Alterações',
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

  Future<void> _updateHealthData() async {
    if (!_formKey.currentState!.validate()) {
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

      HealthData updatedHealthData;

      if (_selectedType!.isPressaoArterial) {
        updatedHealthData = widget.healthData.copyWith(
          valorSistolica: double.parse(_valorSistolicaController.text),
          valorDiastolica: double.parse(_valorDiastolicaController.text),
          observacao: _observacaoController.text.trim().isEmpty 
            ? null 
            : _observacaoController.text.trim(),
          dataRegistro: dataRegistro.toIso8601String(),
        );
      } else {
        updatedHealthData = widget.healthData.copyWith(
          valor: double.parse(_valorController.text),
          observacao: _observacaoController.text.trim().isEmpty 
            ? null 
            : _observacaoController.text.trim(),
          dataRegistro: dataRegistro.toIso8601String(),
        );
      }

      final success = await healthDataController.updateHealthData(updatedHealthData);

      if (success) {
        ToastService.showSuccess(context, 'Dados de saúde atualizados com sucesso');
        Get.back();
      } else {
        ToastService.showError(context, 'Erro ao atualizar dados de saúde');
      }
    } catch (e) {
      ToastService.showError(context, 'Erro inesperado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
