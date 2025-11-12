import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/backup_controller.dart';
import 'package:app_remedio/utils/constants.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backupController = Get.put(BackupController());

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Backup e Restauração',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Operações de Backup'),
            const SizedBox(height: 12),
            _buildBackupCard(backupController),
            const SizedBox(height: 24),
            _buildSectionHeader('Zona de Perigo'),
            const SizedBox(height: 12),
            _buildDangerCard(backupController),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Sobre o Backup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'O backup cria um arquivo JSON com todos os seus dados:\n'
            '• Perfis\n'
            '• Medicamentos e agendamentos\n'
            '• Dados de saúde\n'
            '• Anotações\n'
            '• Histórico de estoque\n\n'
            'Você pode compartilhar este arquivo ou salvá-lo em um local seguro.',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildBackupCard(BackupController controller) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.backup,
            iconColor: primaryColor,
            title: 'Criar Backup',
            subtitle: 'Exporta todos os dados para um arquivo JSON',
            onTap: () => controller.exportBackup(),
            controller: controller,
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.restore,
            iconColor: Colors.blue,
            title: 'Restaurar Backup',
            subtitle: 'Importa dados de um arquivo de backup',
            onTap: () => controller.importBackup(),
            controller: controller,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerCard(BackupController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.delete_forever,
            iconColor: Colors.red,
            title: 'Apagar Todos os Dados',
            subtitle: 'Remove permanentemente todos os dados do aplicativo',
            onTap: () => controller.clearAllData(),
            controller: controller,
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required BackupController controller,
    bool isDanger = false,
  }) {
    return Obx(
      () => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDanger ? Colors.red : textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: textColor.withOpacity(0.6),
          ),
        ),
        trailing: controller.isLoading.value
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(
                Icons.chevron_right,
                color: textColor.withOpacity(0.4),
              ),
        onTap: controller.isLoading.value ? null : onTap,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.withOpacity(0.2),
      indent: 88,
    );
  }
}

