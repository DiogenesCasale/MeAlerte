import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:app_remedio/views/medication/add_medication_screen.dart';

class AddRestockScreen extends StatefulWidget {
  const AddRestockScreen({super.key});

  @override
  State<AddRestockScreen> createState() => _AddRestockScreenState();
}

class _AddRestockScreenState extends State<AddRestockScreen> {
  final MedicationController medicationController = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _observacaoController = TextEditingController();

  Medication? _selectedMedication;
  int _observacaoLength = 0;
  static const int _maxObservacaoLength = 250;

  @override
  void initState() {
    super.initState();
    _observacaoController.addListener(() {
      setState(() {
        _observacaoLength = _observacaoController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _saveRestock() async {
    // A validação agora trata todos os casos (inteiro, não-zero, etc)
    if (!_formKey.currentState!.validate()) {
      ToastService.showError(context, 'Por favor, corrija os campos destacados.');
      return;
    }

    if (_selectedMedication == null) {
      ToastService.showError(context, 'Selecione um medicamento.');
      return;
    }

    // Como o validador já garantiu que o texto é um inteiro válido,
    // podemos usar int.parse com segurança.
    final amount = int.parse(_amountController.text.trim());

    try {
      final observacao = _observacaoController.text.trim().isEmpty
          ? null
          : _observacaoController.text.trim();

      // >>> MODIFICAÇÃO CHAVE <<<
      // Convertemos o inteiro para double apenas na hora de chamar o controller
      await medicationController.addStock(
        _selectedMedication!.id!,
        amount.toDouble(), // Converte para double aqui
        observacao: observacao,
      );
      
      ToastService.showSuccess(
          context, 'Estoque de ${_selectedMedication!.nome} atualizado!');
      Get.back();

    } catch (e) {
      ToastService.showError(
          context, 'Erro ao salvar reposição: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Novo Lançamento', style: heading2Style),
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
              Text('Medicamento *', style: heading2Style),
              const SizedBox(height: 8),
              // Dropdown para selecionar o medicamento
              Obx(() {
                // Garante que a lista de medicamentos esteja disponível
                if (medicationController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Se não houver medicamentos, mostra o componente informativo
                if (medicationController.allMedications.isEmpty) {
                  return _buildEmptyMedicationState();
                }

                // Se houver medicamentos, mostra o Dropdown
                return DropdownButtonFormField<Medication>(
                  value: _selectedMedication,
                  isExpanded: true,
                  dropdownColor: surfaceColor,
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration(hint: 'Selecione um medicamento'),
                  items: medicationController.allMedications.map((med) {
                    return DropdownMenuItem(
                      value: med,
                      child: Text(med.nome, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMedication = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Selecione um medicamento.';
                    return null;
                  },
                );
              }),
              const SizedBox(height: 24),

              // Campo para a quantidade
              Text('Quantidade *', style: heading2Style),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                // >>> MODIFICAÇÃO AQUI <<<
                // Teclado para números inteiros, incluindo negativos.
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(
                  hint: 'Ex: 30 ou -10',
                  suffixText: _selectedMedication?.tipo.unit ?? 'unidades',
                ),
                // >>> MODIFICAÇÃO AQUI <<<
                // Validador para garantir que é um número inteiro e não é zero.
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Quantidade é obrigatória.';
                  }
                  // Tenta converter para inteiro
                  final amount = int.tryParse(v.trim());
                  if (amount == null) {
                    return 'Digite um número inteiro válido.';
                  }
                  if (amount == 0) {
                    return 'A quantidade não pode ser zero.';
                  }
                  return null; // Válido!
                },
              ),
              const SizedBox(height: 24),

              _buildObservationField(),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _saveRestock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salvar Lançamento', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NOVO WIDGET: Componente para quando não há medicamentos ---
  Widget _buildEmptyMedicationState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
          const SizedBox(height: 12),
          Text(
            'Nenhum medicamento cadastrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Você precisa cadastrar um medicamento antes de adicionar estoque.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              // Navega para a tela de adicionar medicamento
              Get.to(() => const AddMedicationScreen());
            },
            icon: Icon(Icons.add, color: primaryColor),
            label: Text(
              'Cadastrar Novo Medicamento',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // --- NOVO WIDGET: Campo de observação ---
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
          ).copyWith(
            counterText: '',
          ),
          validator: (value) {
            if (value != null && value.length > _maxObservacaoLength) {
              return 'A observação excedeu o limite de caracteres.';
            }
            return null;
          },
        ),
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