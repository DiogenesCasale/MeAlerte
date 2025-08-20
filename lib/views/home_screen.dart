import 'package:flutter/material.dart';
import 'package:app_remedio/views/add_medication_screen.dart';
import 'package:app_remedio/views/medication_list_screen.dart';
import 'package:app_remedio/utils/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Bem-vindo, novamente!'),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Acesso rápido', style: heading2Style),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildQuickAccessCard(context, 'Novo medicamento', Icons.medication, const AddMedicationScreen())),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickAccessCard(context, 'Medicamentos', Icons.list_alt, const MedicationListScreen())),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Resumo dos últimos 30 dias', style: heading2Style),
          const SizedBox(height: 10),
          _buildSummaryCard('Medicamentos tomados', '50', Colors.blue),
          _buildSummaryCard('Reposições feitas', '100', Colors.green),
          _buildSummaryCard('Consultas realizadas', '10', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(BuildContext context, String title, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: bodyTextStyle),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
