import 'package:flutter/material.dart';
import 'package:app_remedio/views/home_screen.dart';
import 'package:app_remedio/utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeAlerteApp());
}

class MeAlerteApp extends StatelessWidget {
  const MeAlerteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeAlerte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
