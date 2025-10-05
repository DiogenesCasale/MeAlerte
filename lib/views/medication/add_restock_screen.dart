import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/utils/toast_service.dart';

class AddRestockScreen extends StatefulWidget {
  const AddRestockScreen({super.key});

  @override
  State<AddRestockScreen> createState() => _AddRestockScreenState();
}

class _AddRestockScreenState extends State<AddRestockScreen> {
  final MedicationController medicationController = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  Medication? _selectedMedication;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveRestock() async {
    // Valida o formulário
    if (!_formKey.currentState!.validate()) {
      ToastService.showError(context, 'Por favor, preencha todos os campos.');
      return;
    }

    if (_selectedMedication == null) {
      ToastService.showError(context, 'Selecione um medicamento.');
      return;
    }

    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ToastService.showError(context, 'Quantidade inválida.');
      return;
    }

    try {
      // Chama o método do controller para adicionar o estoque
      await medicationController.addStock(_selectedMedication!.id!, amount);
      
      ToastService.showSuccess(context, 'Estoque de ${_selectedMedication!.nome} atualizado!');
      Get.back(); // Volta para a tela anterior

    } catch (e) {
      ToastService.showError(context, 'Erro ao salvar reposição: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Nova Reposição', style: heading2Style),
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
              Text('Quantidade a Adicionar *', style: heading2Style),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(
                  hint: 'Ex: 30',
                  suffixText: _selectedMedication?.tipo.unit ?? 'unidades',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Quantidade é obrigatória.';
                  final amount = int.tryParse(v);
                  if (amount == null || amount <= 0) return 'Valor inválido.';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              // Botão Salvar
              ElevatedButton(
                onPressed: _saveRestock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salvar Reposição', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para decoração dos inputs, igual ao da sua outra tela
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