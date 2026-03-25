import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Importação necessária para podermos reaproveitar a lista de alunos
import 'package:gestao_escolar/telas/secretaria/aba_alunos.dart';

class AbaTurmas extends StatelessWidget {
  const AbaTurmas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('turmas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar turmas'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma turma cadastrada.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final turmasDocs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: turmasDocs.length,
            itemBuilder: (context, index) {
              final turmaData =
                  turmasDocs[index].data() as Map<String, dynamic>;

              final nome = turmaData['nome'] ?? 'Turma Sem Nome';
              final professor = turmaData['professor'] ?? 'Prof. não definido';
              final qtdAlunos = turmaData['quantidade_alunos'] ?? 0;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TelaAlunosPorTurma(nomeTurma: nome),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.meeting_room,
                          size: 40,
                          color: Colors.blue[900],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          nome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$qtdAlunos alunos',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          professor,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Abrindo tela de Cadastro de Turma...'),
            ),
          );
        },
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nova Turma',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Subtela que abre quando clica no Card de uma Turma
class TelaAlunosPorTurma extends StatelessWidget {
  final String nomeTurma;
  const TelaAlunosPorTurma({super.key, required this.nomeTurma});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alunos: $nomeTurma'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      // Reaproveitando a lista completa de alunos.
      // No futuro, podemos passar um filtro para a AbaAlunos exibir só os dessa turma!
      body: const AbaAlunos(),
    );
  }
}
