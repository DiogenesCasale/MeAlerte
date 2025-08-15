import 'package:flutter/material.dart';
import 'package:me_alerte/controller/medication_controller.dart';
import 'package:me_alerte/model/medication_model.dart';

class MedicationRegisterScreen extends StatefulWidget {
  const MedicationRegisterScreen({super.key});

  @override
  State<MedicationRegisterScreen> createState() =>
      _MedicationRegisterScreenState();
}

class _MedicationRegisterScreenState extends State<MedicationRegisterScreen> {
  // Controller to manage the state and logic for medications.
  late final MedicationController _controller;

  // Text editing controllers to get user input from TextFormFields.
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the controller when the widget is first created.
    _controller = MedicationController();
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources when the widget is removed.
    _nameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Clears the input fields after a medication is saved.
  void _clearForm() {
    _nameController.clear();
    _quantityController.clear();
    _descriptionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Cadastro de Medicamentos'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Form fields for medication details
            _buildTextFormField(
              controller: _nameController,
              label: 'Nome do Medicamento',
            ),
            const SizedBox(height: 12),
            _buildTextFormField(
              controller: _quantityController,
              label: 'Quantidade',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildTextFormField(
              controller: _descriptionController,
              label: 'Descrição (Opcional)',
            ),
            const SizedBox(height: 24),

            // Button to save the medication
            ElevatedButton(
              onPressed: () {
                // Basic validation
                if (_nameController.text.isNotEmpty &&
                    _quantityController.text.isNotEmpty) {
                  _controller.addMedication(
                    name: _nameController.text,
                    quantity: int.parse(_quantityController.text),
                    description: _descriptionController.text,
                  );
                  _clearForm(); // Clear fields after saving
                  // Hide keyboard
                  FocusScope.of(context).unfocus();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Salvar Medicamento'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Medicamentos Salvos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // List of saved medications that updates automatically
            Expanded(
              child: ValueListenableBuilder<List<MedicationModel>>(
                valueListenable: _controller.medications,
                builder: (context, medicationList, child) {
                  if (medicationList.isEmpty) {
                    return const Center(
                      child: Text("Nenhum medicamento cadastrado."),
                    );
                  }
                  return ListView.builder(
                    itemCount: medicationList.length,
                    itemBuilder: (context, index) {
                      final medication = medicationList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(medication.nome),
                          subtitle: Text(
                            'Quantidade: ${medication.quantidade}\nDescrição: ${medication.descricao ?? 'N/A'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Delete the medication when the button is pressed
                              _controller.deleteMedication(medication.id!);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget to create consistently styled text form fields.
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
