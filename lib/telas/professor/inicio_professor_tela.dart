import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestao_escolar/nucleo/cores.dart';
import 'package:gestao_escolar/telas/tela_principal.dart'; // Para o Perfil
import 'package:gestao_escolar/telas/secretaria/aba_alunos.dart'; // Para visualizar o aluno
import 'package:url_launcher/url_launcher.dart'; // Para o WhatsApp
import 'package:gestao_escolar/telas/login/login_tela.dart';

// ==========================================
// TELA: PAINEL DO PROFESSOR (DASHBOARD) E ACESSO SECRETARIA
// ==========================================
class InicioProfessorTela extends StatefulWidget {
  final String usuarioId;

  const InicioProfessorTela({super.key, required this.usuarioId});

  @override
  State<InicioProfessorTela> createState() => _InicioProfessorTelaState();
}

class _InicioProfessorTelaState extends State<InicioProfessorTela> {
  Map<String, dynamic>? _dadosUsuario;
  bool _carregando = true;

  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuario();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _buscarDadosUsuario() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuarioId)
          .get();

      if (doc.exists) {
        setState(() {
          _dadosUsuario = doc.data();
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar usuário logado: $e');
      setState(() => _carregando = false);
    }
  }

  int _pesoDaTurma(String nomeDaTurma) {
    final ordemCorreta = [
      'Maternal',
      'Jardim I',
      'Jardim II',
      '1º Ano (Fund I)',
      '2º Ano (Fund I)',
      '3º Ano (Fund I)',
      '4º Ano (Fund I)',
      '5º Ano (Fund I)',
      '6º Ano (Fund II)',
      '7º Ano (Fund II)',
      '8º Ano (Fund II)',
      '9º Ano (Fund II)',
      '1º Ano (Ens. Médio)',
      '2º Ano (Ens. Médio)',
      '3º Ano (Ens. Médio)',
      '1º Ano (Fundamental I)',
      '2º Ano (Fundamental I)',
      '3º Ano (Fundamental I)',
      '4º Ano (Fundamental I)',
      '5º Ano (Fundamental I)',
      '6º Ano (Fundamental II)',
      '7º Ano (Fundamental II)',
      '8º Ano (Fundamental II)',
      '9º Ano (Fundamental II)',
    ];
    for (int i = 0; i < ordemCorreta.length; i++) {
      if (nomeDaTurma.contains(ordemCorreta[i])) return i;
    }
    return 99;
  }

  int _pesoDoTurno(String nomeDoTurno) {
    if (nomeDoTurno.contains('Manhã')) return 0;
    if (nomeDoTurno.contains('Tarde')) return 1;
    if (nomeDoTurno.contains('Noite')) return 2;
    return 3;
  }

  // ==========================================
  // MODAL: CONFIGURAR INÍCIO DA AULA
  // ==========================================
  void _mostrarModalIniciarAula(
    BuildContext context,
    Map<String, dynamic> turmaData,
    String nomeUsuario,
    String turmaId,
    bool isSecretaria,
  ) {
    final professoresDaTurma = turmaData['professores'] as List<dynamic>? ?? [];

    Set<String> disciplinasDisponiveis = {};

    // 1. Adiciona as disciplinas que o professor está vinculado (se houver)
    if (!isSecretaria) {
      disciplinasDisponiveis.addAll(
        professoresDaTurma
            .where((p) => p['nome'] == nomeUsuario)
            .map((p) => p['disciplina'].toString()),
      );
    }

    // 2. Adiciona a lista padrão com a nova inteligência de Chamada Unificada
    disciplinasDisponiveis.addAll([
      'Chamada Unificada do Dia (Polivalente)',
      'Artes',
      'Educação Física',
      'Inglês',
      'Espanhol',
      'Ensino Religioso / Ética',
      'Linguagens / Português',
      'Matemática',
      'História',
      'Geografia',
      'Ciências / Biologia',
    ]);

    final listaDisciplinas = disciplinasDisponiveis.toList();
    String disciplinaSelecionada = listaDisciplinas.first;
    final dataAtualFormatada =
        '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Iniciar Aula',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CoresDomex.azulPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Turma: ${turmaData['nome']} - ${turmaData['turno']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const Divider(height: 32),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          'Data da Aula: $dataAtualFormatada',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Qual disciplina você vai lecionar agora?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: disciplinaSelecionada,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                    items: listaDisciplinas
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => disciplinaSelecionada = val);
                      }
                    },
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TelaChamadaAula(
                              turmaData: turmaData,
                              turmaId: turmaId,
                              disciplina: disciplinaSelecionada,
                              nomeProfessor: isSecretaria
                                  ? 'Secretaria ($nomeUsuario)'
                                  : nomeUsuario,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text(
                        'ABRIR DIÁRIO DE CLASSE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeUsuario = _dadosUsuario?['nome'] ?? 'Usuário';
    final perfilUsuario = _dadosUsuario?['perfil'] ?? '';
    final fotoUrl = _dadosUsuario?['fotoUrl'] as String?;

    final bool isSecretaria =
        perfilUsuario == 'Secretaria' || perfilUsuario == 'Diretor';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            fotoUrl != null && fotoUrl.isNotEmpty
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(fotoUrl),
                  )
                : const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSecretaria ? 'Acesso Administrativo:' : 'Bem-vindo(a),',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    nomeUsuario,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // BOTÃO DE PERFIL
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Meu Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelaPerfil(usuarioId: widget.usuarioId),
                ),
              );
            },
          ),
          // BOTÃO DE LOGOUT
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Sair do Sistema',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text(
                    'Sair do Sistema',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    'Deseja realmente encerrar a sua sessão?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginTela()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: const Text(
                        'Sair',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABEÇALHO INFORMATIVO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: const BoxDecoration(
                    color: CoresDomex.azulPrincipal,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Text(
                    isSecretaria
                        ? 'Você está no modo Secretaria. Tem acesso aos Diários de Classe de todas as turmas.'
                        : 'Selecione uma turma para acessar o Diário de Classe, Lançar Notas e Frequência.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),

                // BARRA DE PESQUISA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: TextField(
                    controller: _buscaController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por Turma ou Professor',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _termoBusca.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _buscaController.clear();
                                setState(() {
                                  _termoBusca = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (valor) {
                      setState(() {
                        _termoBusca = valor.toLowerCase();
                      });
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    isSecretaria
                        ? 'Todas as Turmas da Escola'
                        : 'Minhas Turmas',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // LISTA DE TURMAS COM FILTRO CORRIGIDO
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('turmas')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma turma cadastrada na escola.'),
                        );
                      }

                      final turmasExibidas = snapshot.data!.docs.where((
                        turmaDoc,
                      ) {
                        final dadosTurma =
                            turmaDoc.data() as Map<String, dynamic>;
                        final professores =
                            dadosTurma['professores'] as List<dynamic>? ?? [];

                        final nomeProfessorLogado = nomeUsuario
                            .trim()
                            .toLowerCase();

                        bool temAcesso =
                            isSecretaria ||
                            professores.any((prof) {
                              final nomeProfessorTurma = (prof['nome'] ?? '')
                                  .toString()
                                  .trim()
                                  .toLowerCase();
                              return nomeProfessorTurma == nomeProfessorLogado;
                            });

                        if (!temAcesso) return false;

                        if (_termoBusca.isEmpty) return true;

                        final nomeTurma = (dadosTurma['nome'] ?? '')
                            .toString()
                            .toLowerCase();
                        final nomesProfessoresString = professores
                            .map(
                              (p) => (p['nome'] ?? '').toString().toLowerCase(),
                            )
                            .join(' ');

                        return nomeTurma.contains(_termoBusca) ||
                            nomesProfessoresString.contains(_termoBusca);
                      }).toList();

                      if (turmasExibidas.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _termoBusca.isNotEmpty
                                    ? 'Nenhuma turma encontrada para esta busca.'
                                    : 'Você ainda não foi vinculado a nenhuma turma.\nSolicite à Secretaria.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      turmasExibidas.sort((a, b) {
                        final dataA = a.data() as Map<String, dynamic>;
                        final dataB = b.data() as Map<String, dynamic>;
                        int pesoA = _pesoDaTurma(dataA['nome'] ?? '');
                        int pesoB = _pesoDaTurma(dataB['nome'] ?? '');
                        if (pesoA == pesoB) {
                          return _pesoDoTurno(
                            dataA['turno'] ?? '',
                          ).compareTo(_pesoDoTurno(dataB['turno'] ?? ''));
                        }
                        return pesoA.compareTo(pesoB);
                      });

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        itemCount: turmasExibidas.length,
                        itemBuilder: (context, index) {
                          final turmaData =
                              turmasExibidas[index].data()
                                  as Map<String, dynamic>;
                          final turmaId = turmasExibidas[index].id;

                          final nomeTurma = turmaData['nome'] ?? 'Turma';
                          final turnoTurma = turmaData['turno'] ?? '';
                          final professoresList =
                              turmaData['professores'] as List<dynamic>? ?? [];

                          final nomesProfessores = professoresList
                              .map((p) => p['nome'])
                              .join(', ');

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              onTap: () {
                                _mostrarModalIniciarAula(
                                  context,
                                  turmaData,
                                  nomeUsuario,
                                  turmaId,
                                  isSecretaria,
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade100,
                                child: const Icon(
                                  Icons.meeting_room,
                                  color: Colors.teal,
                                ),
                              ),
                              title: Text(
                                nomeTurma,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Turno: $turnoTurma'),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Prof(s): ${nomesProfessores.isEmpty ? 'Nenhum vinculado' : nomesProfessores}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
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
// TELA: DIÁRIO DE CLASSE (CHAMADA E PRESENÇA)
// ==========================================
class TelaChamadaAula extends StatefulWidget {
  final Map<String, dynamic> turmaData;
  final String turmaId;
  final String disciplina;
  final String nomeProfessor;

  const TelaChamadaAula({
    super.key,
    required this.turmaData,
    required this.turmaId,
    required this.disciplina,
    required this.nomeProfessor,
  });

  @override
  State<TelaChamadaAula> createState() => _TelaChamadaAulaState();
}

class _TelaChamadaAulaState extends State<TelaChamadaAula> {
  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = '';

  // Mapa para guardar quem está presente ou faltou.
  final Map<String, bool> _presencas = {};
  bool _salvandoChamada = false;
  bool _chamadaSalvaComSucesso = false;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // --- LÓGICA V4 GGE: DISTRIBUIÇÃO AUTOMÁTICA USANDO BATCH ---
  void _salvarChamadaNoBanco(List<QueryDocumentSnapshot> alunosDocs) async {
    setState(() => _salvandoChamada = true);

    try {
      List<Map<String, dynamic>> listaFrequencia = [];
      for (var doc in alunosDocs) {
        final alunoId = doc.id;
        final estaPresente = _presencas[alunoId] ?? true;

        listaFrequencia.add({
          'id': alunoId,
          'nome': doc['nomeCompleto'],
          'ra': doc['ra'],
          'presente': estaPresente,
        });
      }

      List<String> disciplinasParaSalvar = [];

      if (widget.disciplina == 'Chamada Unificada do Dia (Polivalente)') {
        // Se for polivalente, replica a chamada para a grade principal inteira
        disciplinasParaSalvar = [
          'Linguagens / Português',
          'Matemática',
          'Ciências / Biologia',
          'História',
          'Geografia',
        ];
      } else {
        // Se for especialista (ex: Inglês, Ed. Física), salva apenas na matéria dele
        disciplinasParaSalvar = [widget.disciplina];
      }

      // Usamos um WriteBatch do Firebase para salvar tudo de uma vez
      final batch = FirebaseFirestore.instance.batch();
      final colecaoChamadas = FirebaseFirestore.instance.collection('chamadas');

      for (String disciplinaFinal in disciplinasParaSalvar) {
        final docRef = colecaoChamadas.doc(); // Cria um ID único novo
        batch.set(docRef, {
          'turmaNome': widget.turmaData['nome'],
          'turmaTurno': widget.turmaData['turno'],
          'turmaId': widget.turmaId,
          'disciplina': disciplinaFinal,
          'tipoChamada':
              widget.disciplina == 'Chamada Unificada do Dia (Polivalente)'
              ? 'Unificada'
              : 'Especialista',
          'professor': widget.nomeProfessor,
          'dataAula': FieldValue.serverTimestamp(),
          'alunos': listaFrequencia,
        });
      }

      await batch.commit(); // Executa todos os salvamentos simultaneamente

      if (mounted) {
        setState(() {
          _salvandoChamada = false;
          _chamadaSalvaComSucesso = true; // Muda o botão para verde
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chamada salva e distribuída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvandoChamada = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar chamada: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // MODAL PARA ENVIAR AVISO GERAL PARA A TURMA
  void _abrirModalAvisoTurma(BuildContext context) {
    final TextEditingController avisoCtrl = TextEditingController();
    bool enviando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Aviso para a Turma',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Disciplina: ${widget.disciplina}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: avisoCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mensagem, trabalho, exercício...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: enviando
                        ? null
                        : () async {
                            if (avisoCtrl.text.trim().isEmpty) return;
                            setModalState(() => enviando = true);

                            try {
                              await FirebaseFirestore.instance
                                  .collection('avisos_turma')
                                  .add({
                                    'turmaId': widget.turmaId,
                                    'turmaNome': widget.turmaData['nome'],
                                    'disciplina': widget.disciplina,
                                    'professor': widget.nomeProfessor,
                                    'mensagem': avisoCtrl.text.trim(),
                                    'dataEnvio': FieldValue.serverTimestamp(),
                                  });
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Aviso enviado!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => enviando = false);
                            }
                          },
                    child: enviando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'PUBLICAR AVISO',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // MODAL PARA REGISTRO INDIVIDUAL DO ALUNO
  void _abrirModalRegistroAluno(
    BuildContext context,
    String alunoId,
    String nomeAluno,
    Map<String, dynamic> alunoData,
  ) {
    final TextEditingController descCtrl = TextEditingController();
    final TextEditingController notaCtrl = TextEditingController();

    String tipoRegistro = 'Lançar Nota';
    String disciplinaRegistro = widget.disciplina;
    bool salvandoRegistro = false;

    String telefoneResp = '';
    final resp = alunoData['responsaveis'] ?? {};
    final mae = resp['mae'] ?? {};
    final pai = resp['pai'] ?? {};

    if (mae['telefone'] != null && mae['telefone'].toString().isNotEmpty) {
      telefoneResp = mae['telefone'];
    } else if (pai['telefone'] != null &&
        pai['telefone'].toString().isNotEmpty) {
      telefoneResp = pai['telefone'];
    }
    final numeroTelefoneLimpo = telefoneResp.replaceAll(RegExp(r'[^0-9]'), '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Registro: $nomeAluno',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: tipoRegistro,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Registro',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                              'Lançar Nota',
                              'Observação de Comportamento',
                              'Aviso aos Pais',
                              'Aviso ao Aluno',
                            ]
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          tipoRegistro = val;
                          descCtrl.clear();
                          notaCtrl.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  if (tipoRegistro == 'Lançar Nota') ...[
                    TextFormField(
                      initialValue: disciplinaRegistro,
                      decoration: const InputDecoration(
                        labelText: 'Disciplina',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => disciplinaRegistro = val,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor da Nota (Apenas Números)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else if (tipoRegistro == 'Aviso ao Aluno') ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Funcionalidade "Aviso ao Aluno" em breve.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: tipoRegistro == 'Aviso aos Pais'
                            ? 'Digite o aviso para os responsáveis...'
                            : 'Detalhes da observação...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (tipoRegistro != 'Aviso ao Aluno')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: salvandoRegistro
                                ? null
                                : () async {
                                    String descricaoFinal = '';

                                    if (tipoRegistro == 'Lançar Nota') {
                                      if (notaCtrl.text.trim().isEmpty) return;
                                      descricaoFinal =
                                          'Nota: ${notaCtrl.text.trim()}';
                                    } else {
                                      if (descCtrl.text.trim().isEmpty) return;
                                      descricaoFinal = descCtrl.text.trim();
                                    }

                                    setModalState(
                                      () => salvandoRegistro = true,
                                    );

                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('registros_alunos')
                                          .add({
                                            'alunoId': alunoId,
                                            'alunoNome': nomeAluno,
                                            'turmaId': widget.turmaId,
                                            'disciplina':
                                                tipoRegistro == 'Lançar Nota'
                                                ? disciplinaRegistro
                                                : widget.disciplina,
                                            'professor': widget.nomeProfessor,
                                            'tipoRegistro': tipoRegistro,
                                            'descricao': descricaoFinal,
                                            'dataRegistro':
                                                FieldValue.serverTimestamp(),
                                          });
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Registro salvo no sistema!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(
                                        () => salvandoRegistro = false,
                                      );
                                    }
                                  },
                            child: salvandoRegistro
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'SALVAR NO SISTEMA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        if (tipoRegistro == 'Aviso aos Pais') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () async {
                                if (descCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Digite o aviso antes de enviar.',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                if (numeroTelefoneLimpo.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Aluno sem telefone de responsável cadastrado na ficha.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final textoWhatsApp =
                                    'Olá, sou o professor(a) ${widget.nomeProfessor} e tenho um aviso aos responsáveis por $nomeAluno:\n\n${descCtrl.text.trim()}';
                                final url = Uri.parse(
                                  'https://wa.me/55$numeroTelefoneLimpo?text=${Uri.encodeComponent(textoWhatsApp)}',
                                );

                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.message,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'ENVIAR VIA WHATSAPP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeTurma = widget.turmaData['nome'] ?? 'Turma';
    final turnoTurma = widget.turmaData['turno'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diário: $nomeTurma', style: const TextStyle(fontSize: 16)),
            Text(
              widget.disciplina,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            tooltip: 'Aviso para Turma',
            onPressed: () => _abrirModalAvisoTurma(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                labelText: 'Pesquisar Aluno',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _termoBusca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaController.clear();
                          setState(() => _termoBusca = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _termoBusca = val.toLowerCase()),
            ),
          ),

          // CABEÇALHO DE INSTRUÇÃO DINÂMICO
          Container(
            color: widget.disciplina == 'Chamada Unificada do Dia (Polivalente)'
                ? Colors.blue.shade50
                : Colors.amber.shade50,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  widget.disciplina == 'Chamada Unificada do Dia (Polivalente)'
                      ? Icons.auto_awesome
                      : Icons.info_outline,
                  color:
                      widget.disciplina ==
                          'Chamada Unificada do Dia (Polivalente)'
                      ? Colors.blue
                      : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.disciplina ==
                            'Chamada Unificada do Dia (Polivalente)'
                        ? 'CHAMADA UNIFICADA: Ao salvar, o sistema distribuirá automaticamente esta presença para Português, Matemática, Ciências, História e Geografia.'
                        : 'CHAMADA DE ESPECIALISTA: Todos os alunos recebem PRESENÇA por padrão. Desmarque os que faltaram na sua aula.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          widget.disciplina ==
                              'Chamada Unificada do Dia (Polivalente)'
                          ? Colors.blue.shade800
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Alunos vindos do Firebase
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alunos')
                  .where('turma', isEqualTo: nomeTurma)
                  .where('turno', isEqualTo: turnoTurma)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum aluno matriculado nesta turma.'),
                  );
                }

                final todosAlunosDocs = snapshot.data!.docs;

                final alunosExibidos = todosAlunosDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome = (data['nomeCompleto'] ?? '')
                      .toString()
                      .toLowerCase();
                  return nome.contains(_termoBusca);
                }).toList();

                alunosExibidos.sort((a, b) {
                  final nomeA =
                      ((a.data() as Map<String, dynamic>)['nomeCompleto'] ?? '')
                          .toString()
                          .toLowerCase();
                  final nomeB =
                      ((b.data() as Map<String, dynamic>)['nomeCompleto'] ?? '')
                          .toString()
                          .toLowerCase();
                  return nomeA.compareTo(nomeB);
                });

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: alunosExibidos.length,
                        itemBuilder: (context, index) {
                          final alunoDoc = alunosExibidos[index];
                          final alunoData =
                              alunoDoc.data() as Map<String, dynamic>;
                          final alunoId = alunoDoc.id;

                          final nomeAluno =
                              alunoData['nomeCompleto'] ?? 'Sem Nome';
                          final fotoUrl = alunoData['fotoUrl'] as String?;

                          final estaPresente = _presencas[alunoId] ?? true;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            elevation: 1,
                            child: ListTile(
                              leading: fotoUrl != null && fotoUrl.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(fotoUrl),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Colors.blue.shade50,
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.blue,
                                      ),
                                    ),
                              title: Text(
                                nomeAluno,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  InkWell(
                                    onTap: () => _abrirModalRegistroAluno(
                                      context,
                                      alunoId,
                                      nomeAluno,
                                      alunoData,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.only(
                                        top: 4.0,
                                        right: 8.0,
                                        bottom: 4.0,
                                      ),
                                      child: Text(
                                        'Registros / Notas',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Switch(
                                value: estaPresente,
                                activeColor: Colors.green,
                                activeTrackColor: Colors.green.shade200,
                                inactiveThumbColor: Colors.red,
                                inactiveTrackColor: Colors.red.shade200,
                                onChanged: (valor) {
                                  setState(() {
                                    _presencas[alunoId] = valor;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // PAINEL INFERIOR COM OS DOIS BOTÕES
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _chamadaSalvaComSucesso
                                    ? Colors.green
                                    : Colors.teal,
                              ),
                              onPressed: _salvandoChamada
                                  ? null
                                  : () =>
                                        _salvarChamadaNoBanco(todosAlunosDocs),
                              icon: _salvandoChamada
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _chamadaSalvaComSucesso
                                          ? Icons.check_circle
                                          : Icons.how_to_reg,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _chamadaSalvaComSucesso
                                    ? 'CHAMADA SALVA'
                                    : 'SALVAR CHAMADA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text(
                                'ENCERRAR AULA DO DIA',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
