import 'package:flutter/material.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/models/medication.dart';
import 'package:app_remedio/utils/constants.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _intervalController = TextEditingController();
  final _durationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _observationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _intervalController.dispose();
    _durationController.dispose();
    _startTimeController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _addMedication() async {
    if (_formKey.currentState!.validate()) {
      final newMedication = Medication(
        name: _nameController.text,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        interval: _intervalController.text,
        duration: _durationController.text,
        startTime: _startTimeController.text,
        observation: _observationController.text,
      );

      await DatabaseController.instance.create(newMedication);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicamento cadastrado!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Medicamento'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(controller: _nameController, label: 'Nome', hint: 'Ex: Dipirona'),
                const SizedBox(height: 20),
                _buildTextField(controller: _quantityController, label: 'Quantidade', hint: '1', keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                _buildTextField(controller: _intervalController, label: 'Intervalo', hint: '8 horas'),
                const SizedBox(height: 20),
                _buildTextField(controller: _durationController, label: 'Duração', hint: '7 dias'),
                const SizedBox(height: 20),
                _buildTextField(controller: _startTimeController, label: 'Horário inicial', hint: '19:30'),
                const SizedBox(height: 20),
                _buildTextField(controller: _observationController, label: 'Observação', hint: 'Tomar com água', maxLines: 4, isRequired: false),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _addMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cadastrar', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: backgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Por favor, preencha este campo.';
            }
            return null;
          },
        ),
      ],
    );
  }
}
