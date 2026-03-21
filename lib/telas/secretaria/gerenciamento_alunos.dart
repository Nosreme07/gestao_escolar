import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestao_escolar/nucleo/cores.dart'; // Ajuste o caminho se necessário
import 'package:gestao_escolar/telas/secretaria/cadastro_aluno.dart'; // Ajuste para o caminho real da sua tela de cadastro

class GerenciamentoAlunosTela extends StatelessWidget {
  const GerenciamentoAlunosTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Alunos'),
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Buscando a coleção 'alunos' e ordenando em ordem alfabética pelo nome
        stream: FirebaseFirestore.instance
            .collection('alunos')
            .orderBy('nomeCompleto')
            .snapshots(),
        builder: (context, snapshot) {
          // Estado de carregamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: CoresDomex.azulPrincipal),
            );
          }

          // Tratamento de erro
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar os dados: ${snapshot.error}'),
            );
          }

          // Se não houver dados ou a lista estiver vazia
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum aluno cadastrado ainda.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Extraindo a lista de documentos
          final alunosDocs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alunosDocs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              // Pegando os dados de cada aluno
              var aluno = alunosDocs[index].data() as Map<String, dynamic>;

              String nome = aluno['nomeCompleto'] ?? 'Sem Nome';
              String ra = aluno['ra'] ?? 'S/N';
              String turma = aluno['turma'] ?? 'Turma não definida';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: CoresDomex.azulPrincipal.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    color: CoresDomex.azulPrincipal,
                  ),
                ),
                title: Text(
                  nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text('RA: $ra  •  $turma'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  // Futuramente você pode colocar a navegação para os DETALHES do aluno aqui
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Abrindo perfil de $nome...')),
                  );
                },
              );
            },
          );
        },
      ),
      // Botão Flutuante para Adicionar Novo Aluno
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo Aluno',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          // Navega para a tela de Cadastro que você me mandou
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastroAlunoTela()),
          );
        },
      ),
    );
  }
}
