import 'package:flutter/material.dart';
import 'package:app_remedio/views/schedules/schedule_list_screen.dart';
import 'package:app_remedio/views/medication/medication_list_screen.dart';
import 'package:app_remedio/views/profile/profile_screen.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/widgets/bottom_navigation_widget.dart';
import 'package:get/get.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = -1});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late int _initialIndex;

  final List<Widget> _screens = [
    const ScheduleListScreen(showAppBar: false),
    const MedicationListScreen(showAppBar: false),
    const ProfileScreen(showBackButton: false),
  ];

  void _onTabTapped(int index) {
    _checkProfile();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfile();
    });

    _initialIndex = widget.initialIndex;
    if (_initialIndex != -1) {
      _currentIndex = _initialIndex;
    }
  }

  void _checkProfile() {
    // Esta função permanece igual
    final profileController = Get.find<ProfileController>();
    if (profileController.currentProfile.value == null) {
      Get.off(() => const ProfileScreen(showBackButton: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    
    return Obx(() {
      // Observa mudanças no perfil atual
      final currentProfile = profileController.currentProfile.value;
      
      // Se não há perfil, vai para a tela de perfil
      if (currentProfile == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.off(() => const ProfileScreen(showBackButton: false));
        });
      }
      
      return Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: currentProfile != null 
          ? BottomNavigationWidget(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            )
          : null,
      );
    });
  }
}
