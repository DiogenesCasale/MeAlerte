import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_remedio/views/main_layout.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/utils/constants.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurações da barra de status
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  // Inicializa os controllers globais
  // IMPORTANTE: ProfileController deve ser inicializado PRIMEIRO
  Get.put(ThemeController());
  Get.put(ProfileController());
  Get.put(MedicationController());
  Get.put(SchedulesController());
  
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
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _startSplashScreen();
  }

  void _startSplashScreen() {
    _animationController.forward();
    
    Timer(const Duration(seconds: 3), () {
      Get.off(() => const MainLayout(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500));
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
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
                            color: primaryColor.withValues(alpha: 0.3),
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
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seu lembrete de medicamentos',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
