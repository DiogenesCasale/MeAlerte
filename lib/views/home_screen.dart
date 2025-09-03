import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/views/add_medication_screen.dart';
import 'package:app_remedio/views/medication_list_screen.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/controllers/theme_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    
    return Obx(() => Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Bem-vindo, novamente!', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeController.isDarkMode.value ? Icons.light_mode : Icons.dark_mode,
              color: textColor,
            ),
            onPressed: () => themeController.toggleTheme(),
            tooltip: themeController.isDarkMode.value ? 'Tema Claro' : 'Tema Escuro',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Acesso rápido', style: heading2Style),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildQuickAccessCard(context, 'Novo medicamento', Icons.medication, const AddMedicationScreen())),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickAccessCard(context, 'Medicamentos', Icons.list_alt, const MedicationListScreen())),
            ],
          ),
          const SizedBox(height: 30),
          Text('Resumo dos últimos 30 dias', style: heading2Style),
          const SizedBox(height: 10),
          _buildSummaryCard('Medicamentos agendados', '12', primaryColor),
          _buildSummaryCard('Medicamentos cadastrados', '8', toastSuccessColor),
          _buildSummaryCard('Agendamentos ativos', '5', toastInfoColor),
        ],
      ),
    ));
  }

  Widget _buildQuickAccessCard(BuildContext context, String title, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
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
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
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
