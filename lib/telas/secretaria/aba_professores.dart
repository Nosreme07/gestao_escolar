import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AbaProfessores extends StatelessWidget {
  const AbaProfessores({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('professores')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar professores'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum professor cadastrado.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final professoresDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: professoresDocs.length,
            itemBuilder: (context, index) {
              final profData =
                  professoresDocs[index].data() as Map<String, dynamic>;

              final nome =
                  profData['nomeCompleto'] ?? profData['nome'] ?? 'Sem Nome';
              final disciplinas = profData['disciplinas'] ?? 'Não informadas';

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(Icons.school, color: Colors.teal),
                  ),
                  title: Text(
                    nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Disciplinas: $disciplinas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Abrindo perfil do professor(a) $nome...',
                        ),
                      ),
                    );
                  },
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
              content: Text('Abrindo tela de Cadastro de Professor...'),
            ),
          );
        },
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo Professor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
