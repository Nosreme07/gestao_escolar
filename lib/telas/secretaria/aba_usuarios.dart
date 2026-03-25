import 'package:flutter/material.dart';

class AbaUsuarios extends StatelessWidget {
  const AbaUsuarios({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'Módulo de Usuários (Em Desenvolvimento)',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Abrindo tela de Cadastro de Usuário...'),
            ),
          );
        },
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Novo Usuário',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
