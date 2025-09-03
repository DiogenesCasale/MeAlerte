import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_remedio/utils/constants.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';
  var isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_themeKey) ?? false;
    updateTheme(isDarkMode.value);
  }

  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    updateTheme(isDarkMode.value);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode.value);
    
    // Força a atualização da UI
    Get.forceAppUpdate();
  }
} 