import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/treatment_model.dart';
import 'package:app_remedio/views/add_medication_screen.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/widgets/expandable_fab_widget.dart';
import 'package:app_remedio/models/action_button_model.dart';
import 'package:intl/intl.dart';

class MedicationListScreen extends GetView<MedicationController> {
  const MedicationListScreen({super.key});

  // NOVO: Método para exibir o BottomSheet com as opções de adição
  void _showAddOptionsModal(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.medication_outlined, color: primaryColor),
              title: const Text('Novo Tratamento'),
              subtitle: const Text('Cadastrar um novo medicamento e agendamento.'),
              onTap: () {
                Get.back(); // Fecha o bottom sheet
                Get.to(() => const AddMedicationScreen());
              },
            ),
            // --- Espaço para futuras opções ---
            // ListTile(
            //   leading: const Icon(Icons.inventory_2_outlined, color: primaryColor),
            //   title: const Text('Nova Reposição de Estoque'),
            //   onTap: () { /* Navegar para tela de reposição */ },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.event_available_outlined, color: primaryColor),
            //   title: const Text('Agendar Consulta'),
            //   onTap: () { /* Navegar para tela de consultas */ },
            // ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.put(MedicationController());

    return Scaffold(
      appBar: AppBar(title: const Text('Agendamentos de Hoje'), centerTitle: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.groupedDoses.isEmpty) {
          return const Center(child: Text("Nenhum agendamento para hoje."));
        }

        final timeKeys = controller.groupedDoses.keys.toList();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: timeKeys.length,
          itemBuilder: (context, index) {
            final time = timeKeys[index];
            final dosesForTime = controller.groupedDoses[time]!;
            return _buildTimeGroup(time, dosesForTime);
          },
        );
      }),
      floatingActionButton: ExpandableFab(
        distance: 80.0,
        children: [
          ActionButtonModel(
            onPressed: () => Get.to(() => const AddMedicationScreen()),
            icon: const Icon(Icons.medication_outlined, color: Colors.white),
            label: 'Novo Tratamento',
            backgroundColor: primaryColor,
          ),
          // Adicione futuras ações aqui. Exemplo:
          // ActionButtonModel(
          //   onPressed: () => print('Reposição'),
          //   icon: const Icon(Icons.inventory_2_outlined, color: Colors.white),
          //   label: 'Reposição',
          //   backgroundColor: Colors.orange,
          // ),
        ],
      ),
    );
  }

  void _showDoseDetailsModal(BuildContext context, ScheduledDose dose) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(dose.medicationName, style: heading1Style),
            const SizedBox(height: 8),
            Text('Dose: ${dose.dose}', style: bodyTextStyle),
            Text('Horário: ${DateFormat('HH:mm').format(dose.scheduledTime)}', style: bodyTextStyle),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Marcar como Tomado'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: dose.isTaken ? null : () {
                controller.markDoseAsTaken(dose.treatmentId, dose.scheduledTime);
                Get.back();
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Editar Tratamento'),
              onPressed: () {
                Get.back();
                Get.snackbar('Em Breve', 'Funcionalidade de edição será implementada.');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeGroup(String time, List<ScheduledDose> doses) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 8),
          ...doses.map((dose) => _buildMedicationCard(dose)).toList(),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(ScheduledDose dose) {
    return Card(
      color: dose.isTaken ? Colors.grey[300] : Colors.white,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _showDoseDetailsModal(Get.context!, dose),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dose.medicationName,
                      style: TextStyle(decoration: dose.isTaken ? TextDecoration.lineThrough : null),
                    ),
                    Text(dose.dose, style: subtitleTextStyle),
                  ],
                ),
              ),
              if (dose.isTaken) const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}
