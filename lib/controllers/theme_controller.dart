import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/controllers/global_state_controller.dart';

// Enum para clareza e segurança de tipos ao escolher o tema.
enum AppThemeMode { light, dark, system }

class ThemeController extends GetxController {
  static const String _themeKey = 'themeMode';
  var themeMode = AppThemeMode.system.obs;

  // Um getter para saber se o modo escuro está ativo,
  // seja por escolha direta ou pelo sistema.
  bool get isDarkMode {
    if (themeMode.value == AppThemeMode.system) {
      // Retorna o brilho atual da plataforma.
      return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    } else {
      // Retorna a escolha explícita do usuário.
      return themeMode.value == AppThemeMode.dark;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
    // Adiciona um listener que será notificado sempre que o tema do sistema operacional mudar.
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      // Se o usuário selecionou 'Padrão do Sistema', nós atualizamos o tema do app.
      if (themeMode.value == AppThemeMode.system) {
        _applyTheme();
      }
    };
  }

  /// Carrega a preferência de tema salva no dispositivo.
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Lê o índice salvo. Se não houver, usa o 'system' como padrão (índice 2).
    final savedThemeIndex = prefs.getInt(_themeKey) ?? AppThemeMode.system.index;
    themeMode.value = AppThemeMode.values[savedThemeIndex];
    _applyTheme();
  }

  /// Aplica o tema visual no app usando o GetX.
  void _applyTheme() {
    ThemeMode modeToApply;
    switch (themeMode.value) {
      case AppThemeMode.light:
        modeToApply = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        modeToApply = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        modeToApply = ThemeMode.system;
        break;
    }
    
    // Atualiza as cores dinâmicas globais ANTES de mudar o tema
    updateTheme(isDarkMode);
    
    // NOTIFICA SISTEMA GLOBAL DE MUDANÇA DE TEMA
    try {
      final globalState = Get.find<GlobalStateController>();
      globalState.notifyThemeUpdate();
    } catch (e) {
      print('GlobalStateController não encontrado: $e');
    }

    // Notifica a status bar do sistema operacional
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: isDarkMode ? Colors.black : Colors.white,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
    
    // SOLUÇÃO MAIS RADICAL: Força restart completo do GetMaterialApp
    Get.forceAppUpdate();
    
    // Esta é a função correta do GetX para mudar o tema de forma reativa.
    Get.changeThemeMode(modeToApply);
    
    // Força refresh dos observables
    themeMode.refresh();
    
    // 'update()' notifica os widgets que usam GetBuilder sobre a mudança
    update();
    
    // Múltiplos rebuilds para garantir propagação IMEDIATA
    Future.delayed(const Duration(milliseconds: 5), () {
      Get.forceAppUpdate();
      update();
      themeMode.refresh();
    });
    
    Future.delayed(const Duration(milliseconds: 25), () {
      Get.forceAppUpdate();
      update();
    });
    
    Future.delayed(const Duration(milliseconds: 75), () {
      update();
      themeMode.refresh();
    });
  }

  /// Define o modo de tema e salva a preferência.
  Future<void> setThemeMode(AppThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    _applyTheme();
  }
  
  /// Alterna entre os temas: Claro -> Escuro -> Sistema -> Claro...
  Future<void> toggleTheme() async {
    final nextIndex = (themeMode.value.index + 1) % AppThemeMode.values.length;
    final nextMode = AppThemeMode.values[nextIndex];
    await setThemeMode(nextMode);
  }

  /// Retorna o nome do tema atual para ser exibido na UI.
  String get currentThemeName {
    switch (themeMode.value) {
      case AppThemeMode.light:
        return 'Tema Claro';
      case AppThemeMode.dark:
        return 'Tema Escuro';
      case AppThemeMode.system:
        return 'Padrão do Sistema';
    }
  }
}
