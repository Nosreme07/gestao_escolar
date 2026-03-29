import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Importamos a aba de alunos para reaproveitar a tela de visualização do perfil!
import 'package:gestao_escolar/telas/secretaria/aba_alunos.dart';
import 'package:gestao_escolar/telas/secretaria/cadastro_aluno.dart';

// ==========================================
// ABA 2: LISTAGEM DE TURMAS (Formato Lista Compacta)
// ==========================================
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
            return const Center(child: Text('Erro ao carregar turmas.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma turma cadastrada.'));
          }

          final turmasDocs = snapshot.data!.docs;

          // Mudamos de GridView para ListView.builder
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: turmasDocs.length,
            itemBuilder: (context, index) {
              final turmaData =
                  turmasDocs[index].data() as Map<String, dynamic>;
              final docId = turmasDocs[index].id;

              final nome = turmaData['nome'] ?? 'Turma Sem Nome';
              final turno = turmaData['turno'] ?? 'Sem Turno';

              // StreamBuilder interno para contar os alunos dessa turma
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('alunos')
                    .where('turma', isEqualTo: nome)
                    .where('turno', isEqualTo: turno)
                    .snapshots(),
                builder: (context, alunoSnapshot) {
                  final qtdAlunos = alunoSnapshot.hasData
                      ? alunoSnapshot.data!.docs.length
                      : 0;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TelaDetalhesTurma(
                              turmaId: docId,
                              turmaData: turmaData,
                            ),
                          ),
                        );
                      },
                      // Ícone redondinho padrão igual aos alunos
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(
                          Icons.meeting_room,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text('Turno: $turno'),
                      // A pílula de quantidade de alunos fica no lado direito
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$qtdAlunos Alunos',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const _ModalCadastroTurma(),
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

// ==========================================
// TELA: DETALHES DA TURMA (Com Alunos e Professores)
// ==========================================
class TelaDetalhesTurma extends StatelessWidget {
  final String turmaId;
  final Map<String, dynamic> turmaData;

  const TelaDetalhesTurma({
    super.key,
    required this.turmaId,
    required this.turmaData,
  });

  @override
  Widget build(BuildContext context) {
    final nome = turmaData['nome'] ?? 'Turma Sem Nome';
    final turno = turmaData['turno'] ?? 'Sem Turno';
    final professores = List<Map<String, dynamic>>.from(
      turmaData['professores'] ?? [],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('$nome - $turno'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Turma',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) =>
                    _ModalCadastroTurma(turmaId: turmaId, turmaData: turmaData),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CABEÇALHO: PROFESSORES DA TURMA
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Professores Responsáveis:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                if (professores.isEmpty)
                  const Text(
                    'Nenhum professor vinculado a esta turma.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: professores.map((prof) {
                      return Chip(
                        avatar: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(
                            Icons.school,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        label: Text(prof['nome'] ?? ''),
                        backgroundColor: Colors.teal.shade50,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // CORPO: LISTA DE ALUNOS
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Alunos Matriculados:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alunos')
                  .where('turma', isEqualTo: nome)
                  .where('turno', isEqualTo: turno)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return const Center(child: Text('Erro ao carregar alunos.'));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum aluno matriculado nesta turma/turno.'),
                  );
                }

                final alunosDocs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: alunosDocs.length,
                  itemBuilder: (context, index) {
                    final alunoData =
                        alunosDocs[index].data() as Map<String, dynamic>;
                    final docId = alunosDocs[index].id;

                    final nomeAluno = alunoData['nomeCompleto'] ?? 'Sem Nome';
                    final matricula = alunoData['ra'] ?? 'Sem RA';
                    final fotoUrl = alunoData['fotoUrl'] as String?;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: fotoUrl != null && fotoUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(fotoUrl),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                ),
                              ),
                        title: Text(
                          nomeAluno,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('RA: $matricula'),
                        // AQUI ESTÁ A MÁGICA: Usamos um Row para colocar os dois botões
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.visibility,
                                color: Colors.blue,
                              ),
                              tooltip: 'Visualizar Perfil',
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
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              tooltip: 'Editar Aluno',
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
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MODAL DE CADASTRO/EDIÇÃO DE TURMA
// ==========================================
class _ModalCadastroTurma extends StatefulWidget {
  final String? turmaId;
  final Map<String, dynamic>? turmaData;

  const _ModalCadastroTurma({this.turmaId, this.turmaData});

  @override
  State<_ModalCadastroTurma> createState() => _ModalCadastroTurmaState();
}

class _ModalCadastroTurmaState extends State<_ModalCadastroTurma> {
  final List<String> _turmasOpcoes = [
    'Maternal',
    'Jardim I',
    'Jardim II',
    '1º Ano (Fundamental I)',
    '2º Ano (Fundamental I)',
    '3º Ano (Fundamental I)',
    '4º Ano (Fundamental I)',
    '5º Ano (Fundamental I)',
    '6º Ano (Fundamental II)',
    '7º Ano (Fundamental II)',
    '8º Ano (Fundamental II)',
    '9º Ano (Fundamental II)',
    '1º Ano (Ens. Médio)',
    '2º Ano (Ens. Médio)',
    '3º Ano (Ens. Médio)',
  ];
  final List<String> _turnosOpcoes = ['Manhã', 'Tarde', 'Noite'];

  String? _turmaSelecionada;
  String? _turnoSelecionado;

  // Lista com todos os professores que vieram do banco
  List<Map<String, dynamic>> _professoresDoBanco = [];
  // Lista com os professores que o utilizador selecionou nesta turma
  List<Map<String, dynamic>> _professoresSelecionados = [];

  bool _carregandoProfessores = false;
  bool _salvando = false;

  bool get _isEdicao => widget.turmaId != null;

  @override
  void initState() {
    super.initState();
    _buscarProfessoresNoBanco().then((_) {
      if (_isEdicao) _carregarDadosEdicao();
    });
  }

  void _carregarDadosEdicao() {
    final dados = widget.turmaData!;
    setState(() {
      if (_turmasOpcoes.contains(dados['nome']))
        _turmaSelecionada = dados['nome'];
      if (_turnosOpcoes.contains(dados['turno']))
        _turnoSelecionado = dados['turno'];

      // Carrega a lista de professores já vinculados
      if (dados['professores'] != null) {
        _professoresSelecionados = List<Map<String, dynamic>>.from(
          dados['professores'],
        );
      }
    });
  }

  Future<void> _buscarProfessoresNoBanco() async {
    setState(() => _carregandoProfessores = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('professores')
          .get();
      setState(() {
        _professoresDoBanco = snap.docs.map((doc) {
          return {
            'id': doc.id,
            'nome': doc.data()['nome'] ?? 'Prof. Sem Nome',
            'disciplina': doc.data()['disciplina'] ?? 'Geral',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Erro ao buscar professores: $e');
    } finally {
      setState(() => _carregandoProfessores = false);
    }
  }

  // Função para marcar/desmarcar um professor na lista de seleção múltipla
  void _alternarProfessor(Map<String, dynamic> prof) {
    setState(() {
      final index = _professoresSelecionados.indexWhere(
        (p) => p['id'] == prof['id'],
      );
      if (index >= 0) {
        _professoresSelecionados.removeAt(index); // Se já está, remove
      } else {
        _professoresSelecionados.add(prof); // Se não está, adiciona
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdicao ? 'Editar Turma' : 'Nova Turma',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              DropdownButtonFormField<String>(
                value: _turmaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Nome da Turma',
                  border: OutlineInputBorder(),
                ),
                items: _turmasOpcoes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _turmaSelecionada = val),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _turnoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Turno',
                  border: OutlineInputBorder(),
                ),
                items: _turnosOpcoes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _turnoSelecionado = val),
              ),
              const SizedBox(height: 24),

              // ====================================================
              // MULTI-SELEÇÃO DE PROFESSORES (FILTER CHIPS)
              // ====================================================
              const Text(
                'Vincular Professores (Pode escolher mais de um):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),

              if (_carregandoProfessores)
                const LinearProgressIndicator()
              else if (_professoresDoBanco.isEmpty)
                const Text(
                  'Nenhum professor cadastrado no sistema ainda.',
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _professoresDoBanco.map((prof) {
                    final estaSelecionado = _professoresSelecionados.any(
                      (p) => p['id'] == prof['id'],
                    );

                    return FilterChip(
                      label: Text(prof['nome']),
                      selected: estaSelecionado,
                      selectedColor: Colors.teal.shade200,
                      checkmarkColor: Colors.teal.shade900,
                      onSelected: (bool selected) {
                        _alternarProfessor(prof);
                      },
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                  ),
                  onPressed: _salvando ? null : _salvarTurma,
                  child: _salvando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEdicao ? 'ATUALIZAR TURMA' : 'SALVAR TURMA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isEdicao)
                Center(
                  child: TextButton.icon(
                    onPressed: () => _confirmarExclusao(context),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Excluir Turma',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _salvarTurma() async {
    if (_turmaSelecionada == null || _turnoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a Turma e o Turno!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    Map<String, dynamic> dadosTurma = {
      'nome': _turmaSelecionada,
      'turno': _turnoSelecionado,
      'professores':
          _professoresSelecionados, // Salva a lista de mapas inteira!
    };

    try {
      if (_isEdicao) {
        await FirebaseFirestore.instance
            .collection('turmas')
            .doc(widget.turmaId)
            .update(dadosTurma);
      } else {
        dadosTurma['dataCriacao'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('turmas').add(dadosTurma);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turma salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
          'Tem certeza que deseja apagar esta turma? Os alunos NÃO serão apagados, apenas a organização da turma sumirá.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Fecha popup
              Navigator.pop(context); // Fecha modal
              await FirebaseFirestore.instance
                  .collection('turmas')
                  .doc(widget.turmaId)
                  .delete();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
