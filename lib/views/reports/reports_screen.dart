import 'package:flutter/material.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/views/reports/doses_report_screen.dart';
import 'package:app_remedio/views/reports/usage_report_screen.dart';
import 'package:get/get.dart';
import 'package:app_remedio/controllers/report_controller.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Relatórios', style: heading2Style),
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          centerTitle: true,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.download, color: primaryColor),
              onSelected: (value) {
                final reportController = Get.find<ReportController>();
                if (value == 'pdf') {
                  reportController.exportToPdf();
                } else if (value == 'csv') {
                  reportController.exportToCsv();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Exportar PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Exportar CSV'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            labelColor: primaryColor,
            unselectedLabelColor: textColor.withOpacity(0.5),
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'Doses'),
              Tab(text: 'Uso e Estoque'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [DosesReportScreen(isEmbedded: true), UsageReportScreen()],
        ),
      ),
    );
  }
}
