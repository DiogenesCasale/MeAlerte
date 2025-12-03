import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_remedio/views/main_layout.dart';
import 'package:app_remedio/controllers/global_state_controller.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/controllers/health_data_controller.dart';
import 'package:app_remedio/controllers/settings_controller.dart';
import 'package:app_remedio/controllers/notification_controller.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/views/onboarding_screen.dart';
import 'package:app_remedio/utils/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurações da barra de status
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // NÃO MUDAR A ORDEM DE INICIALIZAÇÃO DOS CONTROLLERS
  Get.put(GlobalStateController());
  Get.put(ThemeController());
  Get.put(ProfileController());
  Get.put(NotificationController());
  Get.put(SettingsController());

  await NotificationService().init();

  Get.put(MedicationController());
  Get.put(SchedulesController());
  Get.put(HealthDataController());
  
  runApp(const MeAlerteApp());
}

class MeAlerteApp extends StatelessWidget {
  const MeAlerteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() => GetMaterialApp(
      title: 'MeAlerte',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColorLight,
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        // --- ADIÇÃO IMPORTANTE AQUI ---
        appBarTheme: const AppBarTheme(
          elevation: 0, // Estilo moderno sem sombra
          backgroundColor: Colors.white, // Cor de fundo da AppBar
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // Deixa a status bar transparente
            statusBarIconBrightness: Brightness.dark, // Ícones escuros na status bar
          ),
        ),
        // --- FIM DA ADIÇÃO ---
        timePickerTheme: TimePickerThemeData(
          backgroundColor: backgroundColorLight,
          hourMinuteTextColor: textColorLight,
          dialHandColor: primaryColorLight,
          dialBackgroundColor: backgroundColorLight,
          dialTextColor: textColorLight,
          entryModeIconColor: textColorLight,
          dayPeriodTextColor: textColorLight,
          dayPeriodColor: backgroundColorLight,
          helpTextStyle: TextStyle(color: textColorLight),
          hourMinuteTextStyle: TextStyle(color: textColorLight, fontSize: 24),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColorDark,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
        // --- ADIÇÃO IMPORTANTE AQUI ---
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.black, // ou outra cor escura que preferir
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light, // Ícones claros na status bar
          ),
        ),
        // --- FIM DA ADIÇÃO ---
        timePickerTheme: TimePickerThemeData(
          backgroundColor: backgroundColorDark,
          hourMinuteTextColor: textColorDark,
          dialHandColor: primaryColorDark,
          dialBackgroundColor: backgroundColorDark,
          dialTextColor: textColorDark,
          entryModeIconColor: textColorDark,
          dayPeriodTextColor: textColorDark,
          dayPeriodColor: backgroundColorDark,
          helpTextStyle: TextStyle(color: textColorDark),
          hourMinuteTextStyle: TextStyle(color: textColorDark, fontSize: 24),
        ),
      ),
      themeMode: _getThemeMode(themeController.themeMode.value),
      home: const SplashScreen(),
    ));
  }
  
  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Animação um pouco mais rápida
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Inicia a animação da splash
    _animationController.forward();

    // Dê um tempo mínimo para a splash screen ser exibida
    await Future.delayed(const Duration(seconds: 3));

    // Aguarda o ProfileController estar disponível (pode ter sido recriado após backup/restore)
    ProfileController? profileController;
    int attempts = 0;
    while (profileController == null && attempts < 20) {
      try {
        profileController = Get.find<ProfileController>();
      } catch (e) {
        print('Aguardando ProfileController... tentativa ${attempts + 1}');
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
    }

    if (profileController == null) {
      print('ERRO: ProfileController não encontrado após aguardar');
      // Fallback: vai para onboarding
      Get.off(() => const OnboardingScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500));
      return;
    }

    // Aguarda o controller terminar de carregar
    int loadingAttempts = 0;
    while (profileController.isLoading.value && loadingAttempts < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      loadingAttempts++;
    }

    // Acessa a lista de perfis. O Obx na ProfileListScreen já mostra 
    // que o controller carrega a lista no onInit.
    // Vamos verificar se a lista está vazia.
    if (profileController.profiles.isEmpty) {
      // Se não houver perfis, vai para a tela de onboarding
      Get.off(() => const OnboardingScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500));
    } else {
      // Se houver perfis, vai para a tela principal
      Get.off(() => const MainLayout(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // O resto do seu build da SplashScreen permanece o mesmo
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: isDark ? Colors.black : Colors.white,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo do app
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Nome do app
                      Text(
                        'MeAlerte',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seu lembrete de medicamentos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}