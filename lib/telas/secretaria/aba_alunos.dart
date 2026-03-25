import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestao_escolar/telas/secretaria/cadastro_aluno.dart';

// ==========================================
// ABA 1: LISTAGEM DE ALUNOS
// ==========================================
class AbaAlunos extends StatelessWidget {
  const AbaAlunos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('alunos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar dados.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum aluno cadastrado.'));
          }

          final alunosDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alunosDocs.length,
            itemBuilder: (context, index) {
              final alunoData =
                  alunosDocs[index].data() as Map<String, dynamic>;
              final docId = alunosDocs[index].id;

              final nome = alunoData['nomeCompleto'] ?? 'Sem Nome';
              final matricula = alunoData['ra'] ?? 'Sem RA';
              final turma = alunoData['turma'] ?? 'Sem Turma';
              final fotoUrl =
                  alunoData['fotoUrl']
                      as String?; // Pega o link da foto do banco

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: fotoUrl != null && fotoUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(fotoUrl),
                        ) // Foto real
                      : CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(
                            Icons.person,
                            color: Colors.blue,
                          ), // Ícone padrão
                        ),
                  title: Text(
                    nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Matrícula: $matricula | Turma: $turma'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Visualizar',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TelaDetalhesAluno(
                                docId: docId,
                                alunoData: alunoData,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Editar',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CadastroAlunoTela(
                                alunoIdAEditar: docId,
                                alunoDataAEditar: alunoData,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Excluir',
                        onPressed: () =>
                            _confirmarExclusao(context, docId, 'alunos'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Sem o null, chamando como uma matrícula zerada
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CadastroAlunoTela()),
          );
        },
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo Aluno',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, String docId, String colecao) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja apagar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseFirestore.instance
                  .collection(colecao)
                  .doc(docId)
                  .delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registro apagado!')),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TELA: DETALHES DO ALUNO (Visualização)
// ==========================================
class TelaDetalhesAluno extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> alunoData;

  const TelaDetalhesAluno({
    super.key,
    required this.docId,
    required this.alunoData,
  });

  @override
  Widget build(BuildContext context) {
    final nome = alunoData['nomeCompleto'] ?? 'Sem Nome';
    final matricula = alunoData['ra'] ?? 'Sem RA';
    final fotoUrl = alunoData['fotoUrl'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Aluno'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ÁREA DA FOTO (Lendo o link da internet)
            Center(
              child: fotoUrl != null && fotoUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                        fotoUrl,
                      ), // Carrega a foto real
                    )
                  : CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              nome,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Matrícula (RA): $matricula',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // BOTÕES SOLICITADOS
            _construirBotaoAcao(
              context,
              icone: Icons.assignment_ind,
              titulo: 'Ficha Cadastral',
              cor: Colors.blue,
              aoClicar: () {
                _mostrarFichaCadastralCompleta(context, alunoData);
              },
            ),
            _construirBotaoAcao(
              context,
              icone: Icons.calendar_today,
              titulo: 'Frequência',
              cor: Colors.teal,
              aoClicar: () {},
            ),
            _construirBotaoAcao(
              context,
              icone: Icons.attach_money,
              titulo: 'Financeiro',
              cor: Colors.green,
              aoClicar: () {},
            ),
            _construirBotaoAcao(
              context,
              icone: Icons.grading,
              titulo: 'Boletim',
              cor: Colors.orange,
              aoClicar: () {},
            ),
            _construirBotaoAcao(
              context,
              icone: Icons.history_edu,
              titulo: 'Histórico',
              cor: Colors.purple,
              aoClicar: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBotaoAcao(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required Color cor,
    required VoidCallback aoClicar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: aoClicar,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: cor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // POP-UP COM FICHA ORGANIZADA E ESPAÇADA
  // ==========================================
  void _mostrarFichaCadastralCompleta(
    BuildContext context,
    Map<String, dynamic> dados,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            // Extraindo os sub-mapas para facilitar a leitura
            final endereco = dados['endereco'] ?? {};
            final resp = dados['responsaveis'] ?? {};
            final mae = resp['mae'] ?? {};
            final pai = resp['pai'] ?? {};
            final saude = dados['saude'] ?? {};

            return Container(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: controller,
                children: [
                  const Text(
                    'Ficha Cadastral Completa',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 30),

                  // SEÇÃO 1: IDENTIFICAÇÃO
                  _tituloSecao('1. Identificação'),
                  _linhaDado('Nome', dados['nomeCompleto']),
                  _linhaDado('Sexo', dados['sexo']),
                  _linhaDado('Data de Nascimento', dados['dataNascimento']),
                  _linhaDado('Turma', dados['turma']),
                  _linhaDado('Turno', dados['turno']),
                  _linhaBooleano(
                    'Possui irmão na escola?',
                    dados['temIrmaoNaEscola'],
                  ),
                  if (dados['temIrmaoNaEscola'] == true)
                    _linhaDado('Irmão vinculado', dados['irmaoVinculado']),
                  const SizedBox(height: 16),

                  // SEÇÃO 2: ENDEREÇO
                  _tituloSecao('2. Endereço'),
                  _linhaDado('Rua', endereco['rua']),
                  _linhaDado('Nº', endereco['numero']),
                  _linhaDado('Bairro', endereco['bairro']),
                  _linhaDado('Cidade', endereco['cidade']),
                  const SizedBox(height: 16),

                  // SEÇÃO 3: RESPONSÁVEIS
                  _tituloSecao('3. Responsáveis'),
                  _linhaDado(
                    'Responsável Financeiro',
                    resp['responsavelFinanceiro'],
                  ),
                  _linhaBooleano(
                    'Autoriza a saída do aluno sair só',
                    resp['autorizadoSairSozinho'],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dados da Mãe',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  _linhaDado('Nome', mae['nome']),
                  _linhaDado('Telefone', mae['telefone']),
                  const SizedBox(height: 8),
                  const Text(
                    'Dados do Pai',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  _linhaDado('Nome', pai['nome']),
                  _linhaDado('Telefone', pai['telefone']),
                  const SizedBox(height: 16),

                  // SEÇÃO 4: SAÚDE
                  _tituloSecao('4. Saúde'),
                  _linhaBooleano(
                    'Possui problema de saúde?',
                    saude['temProblemaSaude'],
                  ),
                  if (saude['temProblemaSaude'] == true)
                    _linhaDado('Qual problema?', saude['qualProblema']),

                  _linhaBooleano(
                    'Toma algum medicamento?',
                    saude['tomaMedicamento'],
                  ),
                  if (saude['tomaMedicamento'] == true)
                    _linhaDado('Qual medicamento?', saude['qualMedicamento']),

                  _linhaBooleano('Tem alguma alergia?', saude['temAlergia']),
                  if (saude['temAlergia'] == true)
                    _linhaDado('Qual alergia?', saude['qualAlergia']),

                  _linhaDado('Observações de Saúde', saude['observacoes']),
                  const SizedBox(height: 32), // Respiro no final da ficha
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helpers visuais para a ficha cadastral
  Widget _tituloSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.blue,
        ),
      ),
    );
  }

  // Linha de texto normal (com espaçamento bottom: 12.0)
  Widget _linhaDado(String label, dynamic valor) {
    final textoValor = (valor == null || valor.toString().trim().isEmpty)
        ? 'Não informado'
        : valor.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: textoValor),
          ],
        ),
      ),
    );
  }

  // Linha específica para Sim/Não (com espaçamento bottom: 12.0)
  Widget _linhaBooleano(String label, dynamic valor) {
    final textoValor = (valor == true) ? 'Sim' : 'Não';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: textoValor),
          ],
        ),
      ),
    );
  }
}
