import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/models/treatment_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:intl/intl.dart';

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

  Medication? _selectedMedication;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  Future<void> _addTreatment() async {
    if (_formKey.currentState!.validate() && _selectedMedication != null) {
      final startDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
      final treatment = Treatment(
        medicamentoId: _selectedMedication!.id!,
        dose: _doseController.text,
        dataHoraInicio: startDateTime.toIso8601String(),
        intervaloHoras: int.parse(_intervalController.text),
        duracaoDias: int.parse(_durationController.text),
      );
      await controller.addTreatment(treatment);
      Get.back();
    } else {
      Get.snackbar('Erro', 'Por favor, selecione um medicamento e preencha todos os campos.');
    }
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    Get.dialog(AlertDialog(
      title: const Text('Novo Medicamento'),
      content: Form(
        key: dialogFormKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
          TextFormField(controller: stockController, decoration: const InputDecoration(labelText: 'Estoque'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (dialogFormKey.currentState!.validate()) {
              controller.addNewMedication(nameController.text, int.parse(stockController.text));
              Get.back();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Tratamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Medicamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<Medication>(
                value: _selectedMedication,
                hint: const Text('Selecione um medicamento'),
                items: controller.allMedications.map((med) => DropdownMenuItem(value: med, child: Text(med.nome))).toList(),
                onChanged: (value) => setState(() => _selectedMedication = value),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0))),
              )),
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _showAddMedicationDialog, child: const Text('Cadastrar Novo'))),
              const SizedBox(height: 20),
              _buildTextField(controller: _doseController, label: 'Dose', hint: 'Ex: 1 comprimido'),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildDateTimePicker('Data Início', DateFormat('dd/MM/yyyy').format(_selectedDate), _selectDate)),
                const SizedBox(width: 16),
                Expanded(child: _buildDateTimePicker('Hora Início', _selectedTime.format(context), _selectTime)),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildTextField(controller: _intervalController, label: 'Intervalo (h)', hint: '8', keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(controller: _durationController, label: 'Duração (dias)', hint: '7', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 40),
              ElevatedButton(onPressed: _addTreatment, child: const Text('Cadastrar')),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos _selectDate, _selectTime, _buildDateTimePicker, _buildTextField (iguais à versão anterior)
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2101));
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null && picked != _selectedTime) setState(() => _selectedTime = picked);
  }

  Widget _buildDateTimePicker(String label, String value, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(value), const Icon(Icons.calendar_today, size: 18)])))
    ]);
  }

  Widget _buildTextField({ required TextEditingController controller, required String label, required String hint, TextInputType keyboardType = TextInputType.text }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(controller: controller, keyboardType: keyboardType, decoration: InputDecoration(hintText: hint, filled: true, fillColor: backgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none)), validator: (v) => v!.isEmpty ? 'Obrigatório.' : null)
    ]);
  }
}
