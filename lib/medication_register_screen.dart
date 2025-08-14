import 'package:flutter/material.dart';

class MedicationRegisterScreen extends StatelessWidget {
  const MedicationRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Cadastro de Medicamentos'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          children: <Widget>[

            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                // código para voltar
                Navigator.pop(context);
              },
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}