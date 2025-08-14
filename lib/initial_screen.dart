import 'package:flutter/material.dart';
import 'medication_register_screen.dart';

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                // botão que leva ao cadastro de medicamentos
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicationRegisterScreen(),
                  ),
                );
              },
              child: const Text('Cadastro de Medicamentos'),
            ),
          ],
        ),
      ),
    );
  }
}
