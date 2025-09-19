import 'package:app_remedio/utils/widgets_default.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/views/main_layout.dart';

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
  final _observacaoController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  ScheduledMedication? _scheduledMedication;
  bool _isLoading = true;

  // Variáveis para o novo sistema de datas
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _paraSempre = false;

  @override
  void initState() {
    super.initState();
    _loadScheduledMedication();
  }

  Future<void> _loadScheduledMedication() async {
    try {
      _scheduledMedication = await schedulesController
          .getScheduledMedicationById(widget.dose.scheduledMedicationId);

      if (_scheduledMedication == null) {
        throw Exception('Medicamento agendado não encontrado');
      }

      // Preencher campos com dados atuais
      _doseController.text = _scheduledMedication!.dose.toString();
      _intervalController.text = _scheduledMedication!.intervalo.toString();
      _observacaoController.text = _scheduledMedication!.observacao ?? '';
      _selectedTime = TimeOfDay.fromDateTime(widget.dose.scheduledTime);

      // Preencher dados do novo seletor de duração
      _paraSempre = _scheduledMedication!.paraSempre;
      if (_scheduledMedication!.dataInicio != null) {
        try {
          _dataInicio = DateTime.parse(_scheduledMedication!.dataInicio!);
        } catch (e) {
          _dataInicio = DateTime.now(); // Fallback para data atual
        }
      } else {
        _dataInicio = DateTime.now(); // Se não tem data início, usar hoje
      }

      if (_scheduledMedication!.dataFim != null) {
        try {
          _dataFim = DateTime.parse(_scheduledMedication!.dataFim!);
        } catch (e) {
          _dataFim = DateTime.now().add(
            const Duration(days: 30),
          ); // Fallback para 30 dias
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar medicamento agendado: $e');
      Get.back();
      ToastService.showError(context, 'Erro ao carregar dados do medicamento');
    }
  }

  @override
  void dispose() {
    _doseController.dispose();
    _intervalController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _updateMedication() async {
    if (!_formKey.currentState!.validate()) {
      ToastService.showError(
        context,
        'Por favor, corrija os campos destacados.',
      );
      return;
    }

    // Validação das datas
    if (!_paraSempre) {
      if (_dataInicio == null || _dataFim == null) {
        ToastService.showError(
          context,
          'Por favor, defina a data de fim do tratamento.',
        );
        return;
      }
      if (_dataFim!.isBefore(_dataInicio!)) {
        ToastService.showError(
          context,
          'A data de fim deve ser posterior à data de início.',
        );
        return;
      }
    }

    // Mostra o dialog de confirmação sobre o escopo da edição
    _showEditConfirmationDialog();
  }

  void _showEditConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Aplicar Alterações', style: heading2Style),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como você deseja aplicar as alterações no agendamento de ${widget.dose.medicationName}?',
              style: bodyTextStyle,
            ),
            const SizedBox(height: 16),
            Text(
              'Escolha uma opção:',
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
          ),
          // TODO: Implementar a edição de um horário específico
          // TextButton(
          //   onPressed: () => _confirmEditSingle(),
          //   child: Text(
          //     'Apenas este horário',
          //     style: TextStyle(color: Colors.orange),
          //   ),
          // ),
          TextButton(
            onPressed: () => _confirmEditAll(),
            child: Text(
              'Todo o agendamento',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEditSingle() {
    Get.back(); // Fechar dialog anterior
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Confirmar Edição', style: heading2Style),
        content: Text(
          'Deseja aplicar as alterações apenas para este horário específico?\n\nIsso criará uma exceção para este horário, mantendo os demais agendamentos inalterados.',
          style: bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await schedulesController.updateSpecificDose(
                  widget.dose,
                  newDose: double.parse(_doseController.text.trim()),
                  newObservacao: _observacaoController.text.trim().isEmpty
                      ? null
                      : _observacaoController.text.trim(),
                  newTime: DateTime(
                    widget.dose.scheduledTime.year,
                    widget.dose.scheduledTime.month,
                    widget.dose.scheduledTime.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  ),
                );

                Get.back(); // Fechar dialog
                ToastService.showSuccess(
                  context,
                  'Dose específica atualizada com sucesso!',
                );
                Get.offAll(
                  () => MainLayout(initialIndex: 0),
                ); // Voltar para tela principal
              } catch (e) {
                debugPrint('Erro ao atualizar dose específica: $e');
                ToastService.showError(
                  context,
                  'Erro ao atualizar dose específica',
                );
              }
            },
            child: Text(
              'Aplicar apenas aqui',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEditAll() {
    Get.back(); // Fechar dialog anterior
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Confirmar Edição Total', style: heading2Style),
        content: Text(
          'Deseja aplicar as alterações em TODOS os agendamentos futuros de ${widget.dose.medicationName}?\n\nIsso modificará todo o cronograma deste medicamento.',
          style: bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _performActualUpdate();
            },
            child: Text(
              'Aplicar em tudo',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performActualUpdate() async {
    try {
      final updatedMedication = ScheduledMedication(
        id: _scheduledMedication!.id,
        hora:
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        dose: double.parse(_doseController.text.trim()),
        intervalo: int.parse(_intervalController.text.trim()),
        dias: 0, // Campo antigo, não mais utilizado
        observacao: _observacaoController.text.trim().isEmpty
            ? null
            : _observacaoController.text.trim(),
        idMedicamento: _scheduledMedication!.idMedicamento,
        idPerfil: _scheduledMedication!.idPerfil,
        // Novos campos de data
        paraSempre: _paraSempre,
        dataInicio: _dataInicio?.toIso8601String(),
        dataFim: _paraSempre ? null : _dataFim?.toIso8601String(),
      );

      await schedulesController.updateScheduled(updatedMedication);

      ToastService.showSuccess(context, 'Agendamento atualizado com sucesso!');
      Get.offAll(() => MainLayout(initialIndex: 0));
    } catch (e) {
      debugPrint('Erro ao atualizar medicamento: $e');
      ToastService.showError(context, 'Erro ao atualizar agendamento');
    }
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
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Editar Agendamento', style: heading2Style),
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
                  border: Border.all(
                    color: textColor.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Text(
                  widget.dose.medicationName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Dose
              // WidgetsDefault.buildTextField(
              //   controller: _doseController,
              //   label: 'Dose (quantidade) *',
              //   hint: 'Ex: 1, 2, 0.5',
              //   keyboardType: TextInputType.numberWithOptions(decimal: true),
              //   validator: (v) {
              //     if (v == null || v.trim().isEmpty) return 'Dose é obrigatória';
              //     final dose = double.tryParse(v.trim());
              //     if (dose == null || dose <= 0) return 'Dose deve ser > 0';
              //     return null;
              //   },
              // ),

              // const SizedBox(height: 20),

              // // Hora
              // _buildTimePicker('Hora Início *',
              //     _selectedTime.format(context), _selectTime),
              _buildDoseAndTimeRow(),

              const SizedBox(height: 20),

              // Intervalo
              WidgetsDefault.buildTextField(
                controller: _intervalController,
                label: 'Intervalo (horas) *',
                hint: '8',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Intervalo é obrigatório';
                  final interval = int.tryParse(v);
                  if (interval == null || interval <= 0)
                    return 'Intervalo deve ser > 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Seletor de Duração
              _buildDurationSelector(),
              const SizedBox(height: 20),

              // Observações
              WidgetsDefault.buildTextField(
                controller: _observacaoController,
                label: 'Observações (opcional)',
                hint: 'Observações adicionais...',
                maxLines: 3,
              ),
              const SizedBox(height: 40),

              // Botão salvar
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

  // --- WIDGETS REUTILIZADOS E ADAPTADOS ---

  Widget _buildTimePicker(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: heading2Style),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: TextStyle(color: textColor, fontSize: 16)),
                Icon(Icons.access_time, color: primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Duração do Tratamento *', style: heading2Style),
            const SizedBox(width: 8),
            if (_dataInicio != null)
              Icon(Icons.lock, size: 16, color: textColor.withOpacity(0.6)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Data de Início (desabilitada para edição)
              WidgetsDefault.buildDateField(
                label: 'Data Início',
                value: _dataInicio,
                onTap: () {}, // Não permite clique
                isRequired: true,
                isEnabled: false, // Desabilita visualmente
              ),
              const SizedBox(height: 16),
              WidgetsDefault.buildDateField(
                label: 'Data Fim',
                value: _dataFim,
                onTap: () => _selectEndDate(),
                isRequired: !_paraSempre,
                isEnabled: !_paraSempre,
              ),
              const SizedBox(height: 4),

              // ALTERAÇÃO 3: O InkWell com o Checkbox foi movido para baixo e alinhado à direita.
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Alinha à direita
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _paraSempre = !_paraSempre;
                        if (_paraSempre) _dataFim = null;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 6.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _paraSempre,
                            onChanged: (value) {
                              setState(() {
                                _paraSempre = value ?? false;
                                if (_paraSempre) _dataFim = null;
                              });
                            },
                            activeColor: primaryColor,
                          ),
                          Text(
                            'Para Sempre',
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- FUNÇÕES DE SELEÇÃO DE DATA/HORA ---

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: surfaceColor,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _dataFim ??
          _dataInicio?.add(const Duration(days: 7)) ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: _dataInicio ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: surfaceColor,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dataFim = picked;
      });
    }
  }

  Widget _buildDoseAndTimeRow() {
    return Row(
      // Alinha os widgets pelo topo, fazendo com que os labels fiquem na mesma linha
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Widget da Dose ocupando metade do espaço
        Expanded(
          child: WidgetsDefault.buildTextField(
            controller: _doseController,
            label: 'Dose *', // Label um pouco mais curto
            hint: 'Ex: 1, 2',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Dose obrigatória';
              final dose = double.tryParse(v.trim());
              if (dose == null || dose <= 0) return 'Dose deve ser > 0';
              return null;
            },
          ),
        ),
        const SizedBox(width: 16), // Espaçamento entre os campos
        // Widget da Hora ocupando a outra metade do espaço
        Expanded(
          child: _buildTimePicker(
            'Hora Início *',
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
            _selectTime,
          ),
        ),
      ],
    );
  }
}
