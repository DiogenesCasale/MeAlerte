import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/views/main_layout.dart';
import 'package:app_remedio/utils/profile_helper.dart';

class EditScheduleScreen extends StatefulWidget {
  final TodayDose dose;
  
  const EditScheduleScreen({super.key, required this.dose});

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final SchedulesController schedulesController = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _doseController = TextEditingController();
  final _intervalController = TextEditingController();
  final _durationController = TextEditingController();
  final _observacaoController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  ScheduledMedication? _scheduledMedication;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledMedication();
  }

  Future<void> _loadScheduledMedication() async {
    try {
      // Buscar o ScheduledMedication completo pelo ID
      final scheduledMeds = await schedulesController.getAllScheduledFromDB();
      _scheduledMedication = scheduledMeds.firstWhere(
        (med) => med.id == widget.dose.scheduledMedicationId,
      );
      
      // Preencher campos com dados atuais
      _doseController.text = widget.dose.dose.toString();
      _intervalController.text = _scheduledMedication!.intervalo.toString();
      _durationController.text = _scheduledMedication!.dias.toString();
      _observacaoController.text = widget.dose.observacao ?? '';
      _selectedTime = TimeOfDay.fromDateTime(widget.dose.scheduledTime);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar medicamento agendado: $e');
      Get.back();
      ToastService.showError(context, 'Erro ao carregar dados do medicamento');
    }
  }

  @override
  void dispose() {
    _doseController.dispose();
    _intervalController.dispose();
    _durationController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Editar Agendamento', style: heading2Style),
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Editar Agendamento', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicamento (não editável)
              Row(
                children: [
                  Text('Medicamento', style: heading2Style),
                  const SizedBox(width: 8),
                  Icon(Icons.lock, size: 16, color: textColor.withOpacity(0.6)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: textColor.withValues(alpha: 0.2), style: BorderStyle.solid),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dose.medicationName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'O medicamento não pode ser alterado na edição',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dose
              Text('Dose (quantidade) *', style: heading2Style),
              const SizedBox(height: 8),
              TextFormField(
                controller: _doseController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Ex: 1, 2, 0.5',
                  hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                ),
                style: TextStyle(color: textColor),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Dose é obrigatória';
                  }
                  final dose = double.tryParse(value.trim());
                  if (dose == null || dose <= 0) {
                    return 'Dose deve ser um número > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Horário
              Text('Hora Início *', style: heading2Style),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Intervalo e Duração responsivo
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400) {
                    // Layout de coluna para telas pequenas
                    return Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Intervalo (horas) *', style: heading2Style),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _intervalController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '8',
                                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor),
                                ),
                                filled: true,
                                fillColor: surfaceColor,
                              ),
                              style: TextStyle(color: textColor),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Intervalo é obrigatório';
                                }
                                final interval = int.tryParse(value);
                                if (interval == null || interval <= 0) {
                                  return 'Intervalo deve ser > 0';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Duração (dias) *', style: heading2Style),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '7',
                                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor),
                                ),
                                filled: true,
                                fillColor: surfaceColor,
                              ),
                              style: TextStyle(color: textColor),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Duração é obrigatória';
                                }
                                final duration = int.tryParse(value);
                                if (duration == null || duration <= 0) {
                                  return 'Duração deve ser > 0';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Layout de linha para telas maiores
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Intervalo (horas) *', style: heading2Style),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _intervalController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '8',
                                  hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  filled: true,
                                  fillColor: surfaceColor,
                                ),
                                style: TextStyle(color: textColor),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Intervalo é obrigatório';
                                  }
                                  final interval = int.tryParse(value);
                                  if (interval == null || interval <= 0) {
                                    return 'Intervalo deve ser > 0';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Duração (dias) *', style: heading2Style),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '7',
                                  hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  filled: true,
                                  fillColor: surfaceColor,
                                ),
                                style: TextStyle(color: textColor),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Duração é obrigatória';
                                  }
                                  final duration = int.tryParse(value);
                                  if (duration == null || duration <= 0) {
                                    return 'Duração deve ser > 0';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 20),

              // Observações
              Text('Observações (opcional)', style: heading2Style),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observacaoController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Observações adicionais (opcional)',
                  hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                ),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 40),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _updateMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Salvar Alterações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _updateMedication() async {
    if (_formKey.currentState!.validate() && _scheduledMedication != null) {
      try {
        // Criar um novo ScheduledMedication com os dados atualizados
        final updatedMedication = ScheduledMedication(
          id: _scheduledMedication!.id,
          hora: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          dose: double.parse(_doseController.text),
          intervalo: int.parse(_intervalController.text),
          dias: int.parse(_durationController.text),
          observacao: _observacaoController.text.isEmpty ? null : _observacaoController.text,
          idMedicamento: _scheduledMedication!.idMedicamento,
          dataCriacao: _scheduledMedication!.dataCriacao,
          dataAtualizacao: _scheduledMedication!.dataAtualizacao,
          idPerfil: widget.dose.idPerfil,
        );

        // Atualizar no banco de dados através do controller
        await schedulesController.updateScheduled(updatedMedication);
        
        ToastService.showSuccess(context, 'Agendamento atualizado com sucesso!');
        Get.offAll(() => MainLayout(initialIndex: 0));
      } catch (e) {
        print('Erro ao atualizar medicamento: $e');
        ToastService.showError(context, 'Erro ao atualizar agendamento');
      }
    }
  }
} 