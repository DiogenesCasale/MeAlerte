import 'package:flutter/material.dart';
import 'package:app_remedio/views/medication_list_screen.dart';
import 'package:app_remedio/views/settings_screen.dart';
import 'package:app_remedio/widgets/bottom_navigation_widget.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MedicationListScreen(showAppBar: false),
    const SettingsScreen(showBackButton: false),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
} 