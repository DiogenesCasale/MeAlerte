import 'package:flutter/material.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/views/reports/doses_report_screen.dart';
import 'package:app_remedio/views/reports/usage_report_screen.dart';

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
