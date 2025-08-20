import 'package:flutter/material.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/models/medication.dart';
import 'package:app_remedio/views/add_medication_screen.dart';
import 'package:app_remedio/utils/constants.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  late Future<List<Medication>> _medicationsFuture;

  @override
  void initState() {
    super.initState();
    _refreshMedications();
  }

  void _refreshMedications() {
    setState(() {
      _medicationsFuture = DatabaseController.instance.readAllMedications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeAlerte'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medicamentos para hoje', style: heading1Style),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Medication>>(
                future: _medicationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Erro: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Nenhum medicamento cadastrado."));
                  }

                  final medications = snapshot.data!;
                  return ListView.builder(
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final med = medications[index];
                      return _buildMedicationCard(med);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
          );
          _refreshMedications();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMedicationCard(Medication med) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.startTime, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(med.name, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete, color: secondaryColor),
              onPressed: () async {
                await DatabaseController.instance.delete(med.id!);
                _refreshMedications();
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: primaryColor),
              onPressed: () { /* Lógica para editar */ },
            ),
          ],
        ),
      ),
    );
  }
}
