import 'package:flutter/material.dart';
import 'initial_screen.dart';

void main() {
  // You should wrap your root widget in a MaterialApp
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Set InitialScreen as the home screen
      home: const InitialScreen(),
    );
  }
}
