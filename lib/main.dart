import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:gestao_escolar/nucleo/cores.dart';
import 'package:gestao_escolar/telas/tela_principal.dart'; // Caminho correto pelo seu print

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GestaoEscolarApp());
}

class GestaoEscolarApp extends StatelessWidget {
  const GestaoEscolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão Escolar - Domex Tech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: CoresDomex.cinzaFundo,
        useMaterial3: true,
        primaryColor: CoresDomex.azulPrincipal,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CoresDomex.azulPrincipal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          prefixIconColor: CoresDomex.azulPrincipal,
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const TelaPrincipal(),
    );
  }
}
