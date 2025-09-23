import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/controllers/global_state_controller.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() {
      // Forçar rebuild quando tema muda
      themeController.isDarkMode;
      
      // Forçar rebuild quando perfil muda
      try {
        final globalController = Get.find<GlobalStateController>();
        globalController.profileUpdateCounter;
      } catch (e) {
        // GlobalStateController não está disponível
      }
      
      return Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(
              color: textColor.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                  isActive: currentIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.medication_outlined,
                  activeIcon: Icons.medication,
                  label: 'Medicamentos',
                  index: 1,
                  isActive: currentIndex == 1,
                ),
                _buildNavItem(
                  icon: Icons.person_outlined,
                  activeIcon: Icons.person,
                  label: 'Perfil',
                  index: 2,
                  isActive: currentIndex == 2,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? primaryColor : textColor.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? primaryColor : textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 