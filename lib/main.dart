import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. PACOTE DO FIREBASE
import 'package:gestao_escolar/telas/tela_principal.dart';
import 'firebase_options.dart'; // 2. ARQUIVO DE CHAVES DO FIREBASE

// Importante: Altere 'gestao_escolar' para o nome exato do seu projeto no pubspec.yaml
import 'package:gestao_escolar/nucleo/cores.dart';
import 'package:gestao_escolar/telas/login/login_tela.dart';
import 'package:gestao_escolar/telas/secretaria/cadastro_aluno.dart';
import 'package:gestao_escolar/telas/tela_principal.dart';

// 3. TRANSFORME O MAIN EM ASYNC
void main() async {
  // 4. GARANTE QUE O FLUTTER ESTÁ PRONTO ANTES DE CHAMAR O FIREBASE
  WidgetsFlutterBinding.ensureInitialized();

  // 5. INICIALIZA O FIREBASE COM AS CHAVES DO SEU PROJETO BLAZE
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

      // Definindo o Tema Base usando as CoresDomex
      theme: ThemeData(
        scaffoldBackgroundColor: CoresDomex.cinzaFundo,
        useMaterial3: true,
        primaryColor: CoresDomex.azulPrincipal,

        // Estilo padrão para Botões ElevatedButton
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

        // Estilo padrão para Input fields (E-mail/Senha)
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          prefixIconColor: CoresDomex.azulPrincipal,
          filled: true,
          fillColor: Colors.white,
        ),
      ),

      // A primeira tela que o app abre (perfeito para testar direto!)
      home: const TelaPrincipal(),
    );
  }
}
