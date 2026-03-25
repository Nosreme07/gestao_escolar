import 'package:flutter/material.dart';

// Importando os novos arquivos das abas que vamos criar
import 'package:gestao_escolar/telas/secretaria/aba_alunos.dart';
import 'package:gestao_escolar/telas/secretaria/aba_turmas.dart';
import 'package:gestao_escolar/telas/secretaria/aba_relatorios.dart';
import 'package:gestao_escolar/telas/secretaria/aba_professores.dart';
import 'package:gestao_escolar/telas/secretaria/aba_usuarios.dart'; // A NOVA ABA

class TelaSecretaria extends StatelessWidget {
  const TelaSecretaria({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // <-- Mudamos para 5 abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestão da Secretaria'),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.orange,
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Alunos'),
              Tab(icon: Icon(Icons.meeting_room), text: 'Turmas'),
              Tab(icon: Icon(Icons.analytics), text: 'Relatórios'),
              Tab(icon: Icon(Icons.badge), text: 'Professores'),
              Tab(
                icon: Icon(Icons.manage_accounts),
                text: 'Usuários',
              ), // NOVA ABA
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AbaAlunos(),
            AbaTurmas(),
            AbaRelatorios(),
            AbaProfessores(),
            AbaUsuarios(), // NOVA ABA AQUI
          ],
        ),
      ),
    );
  }
}
