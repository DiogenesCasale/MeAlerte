import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/views/main_layout.dart';
import 'package:app_remedio/views/medication/add_medication_screen.dart';
import 'package:app_remedio/views/medication/edit_medication_screen.dart';
import 'package:app_remedio/utils/widgets_default.dart';
import 'package:app_remedio/utils/profile_helper.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final MedicationController medicationController = Get.find();
  final SchedulesController schedulesController = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _doseController = TextEditingController();
  final _intervalController = TextEditingController();
  final _durationController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _medicationSearchController = TextEditingController();
  final _medicationFocusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();

  final ScrollController _scrollController = ScrollController();

  Medication? _selectedMedication;
  TimeOfDay _selectedTime = TimeOfDay.now();
  OverlayEntry? _overlayEntry;
  int _observacaoLength = 0;
  static const int _maxObservacaoLength = 250;

  // Variáveis para o novo sistema de datas
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _paraSempre = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      // Se o dropdown estiver visível e o usuário rolar a tela
      if (_overlayEntry != null) {
        _medicationFocusNode.unfocus(); // Tira o foco do campo de texto
        _hideDropdown(); // Esconde o dropdown
      }
    });

    _medicationFocusNode.addListener(() {
      if (_medicationFocusNode.hasFocus) {
        _showDropdown();
      } else {
        _hideDropdown();
      }
    });

    // Listener para contar caracteres da observação
    _observacaoController.addListener(() {
      setState(() {
        _observacaoLength = _observacaoController.text.length;
      });
    });

    // Adiciona listener para fechar dropdown quando outros widgets recebem foco
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).addListener(() {
        if (!_medicationFocusNode.hasFocus) {
          _hideDropdown();
        }
      });
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
    _scrollController.dispose();
    super.dispose();
  }

  void _showDropdown() {
    _hideDropdown(); // Remove qualquer dropdown existente

    final RenderBox? textFieldBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
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
              final medications = medicationController.filteredMedications;
              if (medications.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nenhum medicamento encontrado',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          _hideDropdown();
                          _medicationFocusNode.unfocus();
                          Get.to(
                            () => const AddMedicationScreen(
                              showMedicationListScreen: false,
                            ),
                          );
                        },
                        icon: Icon(Icons.add, color: primaryColor),
                        label: Text(
                          'Cadastrar Novo',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount:
                    medications.length + 1, // +1 para o botão "Cadastrar Novo"
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: textColor.withValues(alpha: 0.1)),
                itemBuilder: (context, index) {
                  if (index == medications.length) {
                    // Botão "Cadastrar Novo" no final da lista
                    return InkWell(
                      onTap: () {
                        _hideDropdown();
                        _medicationFocusNode.unfocus();
                        Get.to(
                          () => const AddMedicationScreen(
                            showMedicationListScreen: false,
                          ),
                        );
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
                                  'Estoque: ${medication.estoque} ${medication.tipo.unit}',
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // botão de editar
                          IconButton(
                            onPressed: () => Get.to(
                              () => EditMedicationScreen(
                                medication: medication,
                                showMedicationListScreen: false,
                              ),
                            ),
                            icon: Icon(
                              Icons.edit,
                              color: primaryColor,
                              size: 20,
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
      ToastService.showError(
        context,
        'Por favor, corrija os campos destacados.',
      );
      return;
    }

    if (_selectedMedication == null) {
      ToastService.showError(context, 'Por favor, selecione um medicamento.');
      return;
    }

    // Validação das datas
    if (!_paraSempre) {
      if (_dataInicio == null || _dataFim == null) {
        ToastService.showError(
          context,
          'Por favor, defina as datas de início e fim do tratamento.',
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

    try {
      final scheduledMedication = ScheduledMedication(
        idMedicamento: _selectedMedication!.id!,
        dose: double.parse(_doseController.text.trim()),
        hora:
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        intervalo: int.parse(_intervalController.text),
        dias: _paraSempre
            ? 0
            : (_dataFim!.difference(_dataInicio!).inDays +
                  1), // Compatibilidade
        dataInicio: _paraSempre ? null : _dataInicio!.toIso8601String(),
        dataFim: _paraSempre ? null : _dataFim!.toIso8601String(),
        paraSempre: _paraSempre,
        observacao: _observacaoController.text.trim().isEmpty
            ? null
            : _observacaoController.text.trim(),
        idPerfil: ProfileHelper.currentProfileId,
      );

      await schedulesController.addNewScheduled(scheduledMedication);

      ToastService.showSuccess(context, 'Medicamento agendado com sucesso!');
      Get.offAll(() => MainLayout(initialIndex: 0));
    } catch (e) {
      ToastService.showError(
        context,
        'Erro ao agendar medicamento. Tente novamente.',
      );
    }
  }

  void _onMedicationSelected(Medication medication) {
    setState(() {
      _selectedMedication = medication;
      _medicationSearchController.text = medication.nome;
    });
    _hideDropdown();
    _medicationFocusNode.unfocus();
    FocusScope.of(context).unfocus(); // Garantir que o foco seja removido
  }

  void _onSearchChanged(String query) {
    medicationController.searchMedications(query);
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
          FocusScope.of(context).unfocus(); // Remove foco de todos os campos
        },
        child: SingleChildScrollView(
          controller: _scrollController,
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
                    hintStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
                    ),
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
                              medicationController.searchMedications('');
                              _hideDropdown();
                            },
                          ),
                        Icon(
                          _overlayEntry != null
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: textColor,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: backgroundColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: textColor.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  onChanged: _onSearchChanged,
                  validator: (value) => _selectedMedication == null
                      ? 'Selecione um medicamento'
                      : null,
                ),

                const SizedBox(height: 20),

                // WidgetsDefault.buildTextField(
                //   controller: _doseController,
                //   label: 'Dose (quantidade) *',
                //   hint: 'Ex: 1, 2, 0.5',
                //   keyboardType: TextInputType.numberWithOptions(decimal: true),
                //   validator: (v) {
                //     if (v == null || v.trim().isEmpty) {
                //       return 'Dose é obrigatória';
                //     }
                //     final dose = double.tryParse(v.trim());
                //     if (dose == null || dose <= 0) {
                //       return 'Dose deve ser um número > 0';
                //     }
                //     return null;
                //   },
                // ),
                // const SizedBox(height: 20),

                // _buildTimePicker(
                //   'Hora Início *',
                //   '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                //   _selectTime,
                // ),
                _buildDoseAndTimeRow(),

                const SizedBox(height: 20),

                _buildResponsiveIntervalFields(),
                const SizedBox(height: 20),
                _buildDurationSelector(),
                const SizedBox(height: 20),

                _buildObservationField(),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _addScheduledMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Agendar Medicamento',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
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
                dayPeriodBorderSide: BorderSide(
                  color: textColor.withValues(alpha: 0.3),
                ),
                helpTextStyle: TextStyle(color: textColor),
                hourMinuteTextStyle: TextStyle(color: textColor, fontSize: 24),
                inputDecorationTheme: InputDecorationTheme(
                  fillColor: surfaceColor,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: textColor.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: textColor.withValues(alpha: 0.3),
                    ),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveIntervalFields() {
    return WidgetsDefault.buildTextField(
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
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duração do Tratamento *', style: heading2Style),
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
              // Data de Início (permanece igual)
              WidgetsDefault.buildDateField(
                label: 'Data Início',
                value: _dataInicio,
                onTap: () => _selectStartDate(),
                isRequired: true,
              ),
              const SizedBox(height: 16),

              WidgetsDefault.buildDateField(
                label: 'Data Fim',
                value: _dataFim, // Lógica para exibir o texto
                onTap: () => _selectEndDate(), // Desabilita o clique
                isRequired: !_paraSempre,
                isEnabled: !_paraSempre, // A mágica acontece aqui!
              ),
              const SizedBox(height: 4),

              // 2. Checkbox abaixo e alinhado à direita
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Alinha na direita
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
                        vertical: 8.0,
                      ),
                      child: Row(
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
          decoration: InputDecoration(
            hintText: 'Observações adicionais (opcional)',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            filled: true,
            fillColor: backgroundColor,
            counterText: '', // Remove contador padrão
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
          validator: (value) {
            if (value != null && value.length > _maxObservacaoLength) {
              return 'Observação não pode exceder $_maxObservacaoLength caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
        _dataInicio = picked;
        // Se data fim foi definida e é anterior à nova data início, resetar
        if (_dataFim != null && _dataFim!.isBefore(picked)) {
          _dataFim = null;
        }
      });
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
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
