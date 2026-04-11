import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestao_escolar/telas/secretaria/cadastro_aluno.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Importamos a aba de alunos para reaproveitar a tela de visualização do perfil!
import 'package:gestao_escolar/telas/secretaria/aba_alunos.dart';

// ==========================================
// ABA 2: LISTAGEM DE TURMAS (Formato Lista Compacta)
// ==========================================
class AbaTurmas extends StatelessWidget {
  const AbaTurmas({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestão de Turmas',
          style: TextStyle(fontSize: 18, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () => _gerarRelatorioGeralAlunos(context),
              icon: const Icon(Icons.print, color: Colors.blue),
              label: const Text(
                'Lista Geral',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('turmas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return const Center(child: Text('Erro ao carregar turmas.'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text('Nenhuma turma cadastrada.'));

          final turmasDocs = snapshot.data!.docs.toList();
          turmasDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            int pesoTurmaA = _pesoDaTurma(dataA['nome'] ?? '');
            int pesoTurmaB = _pesoDaTurma(dataB['nome'] ?? '');
            if (pesoTurmaA == pesoTurmaB)
              return _pesoDoTurno(
                dataA['turno'] ?? '',
              ).compareTo(_pesoDoTurno(dataB['turno'] ?? ''));
            return pesoTurmaA.compareTo(pesoTurmaB);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: turmasDocs.length,
            itemBuilder: (context, index) {
              final turmaData =
                  turmasDocs[index].data() as Map<String, dynamic>;
              final docId = turmasDocs[index].id;

              final nome = turmaData['nome'] ?? 'Turma Sem Nome';
              final turno = turmaData['turno'] ?? 'Sem Turno';

              // Verifica se tem grade estruturada ou mostra que não tem
              final gradeLista =
                  turmaData['gradeLista'] as List<dynamic>? ?? [];

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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Turno: $turno'),
                          Text(
                            gradeLista.isNotEmpty
                                ? 'Grade: ${gradeLista.length} horários'
                                : 'Grade não definida',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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

  // ==========================================
  // RELATÓRIO GERAL (Omitido para manter o tamanho reduzido, o seu código continua intacto)
  // ==========================================
  Future<void> _gerarRelatorioGeralAlunos(BuildContext context) async {
    // Aqui continua todo o seu código de impressão em PDF intacto
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Gerando Lista Geral...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final snap = await FirebaseFirestore.instance.collection('alunos').get();
      final alunos = snap.docs.map((d) => d.data()).toList();
      Map<String, List<Map<String, dynamic>>> alunosAgrupados = {};

      for (var aluno in alunos) {
        String turma = aluno['turma'] ?? 'Sem Turma';
        String turno = aluno['turno'] ?? 'Sem Turno';
        String chaveGrupo = '$turma - $turno';
        if (!alunosAgrupados.containsKey(chaveGrupo))
          alunosAgrupados[chaveGrupo] = [];
        alunosAgrupados[chaveGrupo]!.add(aluno);
      }

      List<String> chavesOrdenadas = alunosAgrupados.keys.toList();
      chavesOrdenadas.sort((a, b) {
        if (_pesoDaTurma(a) == _pesoDaTurma(b))
          return _pesoDoTurno(a).compareTo(_pesoDoTurno(b));
        return _pesoDaTurma(a).compareTo(_pesoDaTurma(b));
      });

      final pdf = pw.Document();
      final headers = [
        'Matrícula (RA)',
        'Nome Completo',
        'Contato de Emergência',
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pdfContext) {
            List<pw.Widget> conteudoPdf = [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'GESTAO ESCOLAR - DOMEX TECH',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.Text(
                            'Sistema Integrado de Secretaria',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Data: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 2, color: PdfColors.blue900),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Lista Geral de Alunos (Por Turma)',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Total de alunos: ${alunos.length}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],
              ),
            ];

            for (String chave in chavesOrdenadas) {
              List<Map<String, dynamic>> alunosDaTurma =
                  alunosAgrupados[chave]!;
              alunosDaTurma.sort(
                (a, b) => (a['nomeCompleto'] ?? '').compareTo(
                  b['nomeCompleto'] ?? '',
                ),
              );

              final data = alunosDaTurma.map((a) {
                String contatoEmergencia = 'Não informado';
                final emergenciaLista = a['emergencia'] as List<dynamic>?;
                if (emergenciaLista != null && emergenciaLista.isNotEmpty)
                  contatoEmergencia =
                      '${emergenciaLista[0]['nome'] ?? ''} (${emergenciaLista[0]['telefone'] ?? ''})';
                return [
                  a['ra']?.toString() ?? '-',
                  a['nomeCompleto']?.toString() ?? '-',
                  contatoEmergencia,
                ];
              }).toList();

              conteudoPdf.add(pw.SizedBox(height: 15));
              conteudoPdf.add(
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.all(6),
                  width: double.infinity,
                  child: pw.Text(
                    'Turma: $chave (${alunosDaTurma.length} alunos)',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
              conteudoPdf.add(pw.SizedBox(height: 5));
              conteudoPdf.add(
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: data,
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue900,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellAlignment: pw.Alignment.center,
                  cellPadding: const pw.EdgeInsets.all(6),
                  oddRowDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                  ),
                ),
              );
            }
            return conteudoPdf;
          },
        ),
      );

      if (context.mounted) Navigator.pop(context);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Lista_Geral_Turmas.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ==========================================
// TELA: DETALHES DA TURMA (Exibindo a Tabela e Alunos)
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

    // Recupera a lista de horários salva (ou vazia se for turma antiga)
    final List<dynamic> gradeLista = turmaData['gradeLista'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('$nome - $turno', style: const TextStyle(fontSize: 16)),
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
          // ==========================================
          // GRADE DE AULAS (VISUALIZAÇÃO EM TABELA)
          // ==========================================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Grade de Aulas:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (gradeLista.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Nenhuma grade definida para esta turma.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection:
                        Axis.horizontal, // Permite arrastar pro lado no celular
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.teal.shade50,
                      ), // Corzinha bonitinha pro topo
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Horário',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Segunda',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Terça',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Quarta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Quinta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Sexta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Sábado',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: gradeLista.map((linha) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                linha['horario'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text(linha['seg'] ?? '')),
                            DataCell(Text(linha['ter'] ?? '')),
                            DataCell(Text(linha['qua'] ?? '')),
                            DataCell(Text(linha['qui'] ?? '')),
                            DataCell(Text(linha['sex'] ?? '')),
                            DataCell(Text(linha['sab'] ?? '')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // PROFESSORES
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

          // ALUNOS MATRICULADOS
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(child: Text('Nenhum aluno matriculado.'));

                final alunosOrdenados = snapshot.data!.docs.toList();
                alunosOrdenados.sort(
                  (a, b) =>
                      ((a.data() as Map<String, dynamic>)['nomeCompleto'] ?? '')
                          .toString()
                          .toLowerCase()
                          .compareTo(
                            ((b.data()
                                        as Map<
                                          String,
                                          dynamic
                                        >)['nomeCompleto'] ??
                                    '')
                                .toString()
                                .toLowerCase(),
                          ),
                );

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: alunosOrdenados.length,
                  itemBuilder: (context, index) {
                    final alunoData =
                        alunosOrdenados[index].data() as Map<String, dynamic>;
                    final docId = alunosOrdenados[index].id;
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
// MODAL DE CADASTRO/EDIÇÃO DE TURMA (Tabela Editável)
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
  ];
  final List<String> _turnosOpcoes = ['Manhã', 'Tarde', 'Noite'];

  String? _turmaSelecionada;
  String? _turnoSelecionado;

  // VARIÁVEIS DA TABELA DE GRADE
  final List<Map<String, TextEditingController>> _controladoresGrade = [];

  List<Map<String, dynamic>> _professoresDoBanco = [];
  List<Map<String, dynamic>> _professoresSelecionados = [];

  bool _carregandoProfessores = false;
  bool _salvando = false;

  bool get _isEdicao => widget.turmaId != null;

  @override
  void initState() {
    super.initState();
    _buscarProfessoresNoBanco().then((_) {
      if (_isEdicao) {
        _carregarDadosEdicao();
      } else {
        // Se for uma turma nova, já adiciona 5 horários (linhas) padrão para facilitar
        for (int i = 0; i < 5; i++) {
          _adicionarLinhaNaGrade();
        }
      }
    });
  }

  @override
  void dispose() {
    // É importante limpar os controladores da memória ao fechar a janela
    for (var linha in _controladoresGrade) {
      linha.values.forEach((ctrl) => ctrl.dispose());
    }
    super.dispose();
  }

  void _carregarDadosEdicao() {
    final dados = widget.turmaData!;
    setState(() {
      if (_turmasOpcoes.contains(dados['nome']))
        _turmaSelecionada = dados['nome'];
      if (_turnosOpcoes.contains(dados['turno']))
        _turnoSelecionado = dados['turno'];

      if (dados['professores'] != null) {
        _professoresSelecionados = List<Map<String, dynamic>>.from(
          dados['professores'],
        );
      }

      // Carregar a grade salva (Tabela)
      if (dados['gradeLista'] != null &&
          (dados['gradeLista'] as List).isNotEmpty) {
        for (var linha in dados['gradeLista']) {
          _adicionarLinhaNaGrade(dadosIniciais: linha);
        }
      } else {
        // Turmas antigas podem não ter, coloca umas em branco
        for (int i = 0; i < 5; i++) _adicionarLinhaNaGrade();
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
        _professoresDoBanco = snap.docs
            .map(
              (doc) => {
                'id': doc.id,
                'nome': doc.data()['nome'] ?? 'Prof. Sem Nome',
                'disciplina': doc.data()['disciplina'] ?? 'Geral',
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Erro ao buscar professores: $e');
    } finally {
      setState(() => _carregandoProfessores = false);
    }
  }

  void _alternarProfessor(Map<String, dynamic> prof) {
    setState(() {
      final index = _professoresSelecionados.indexWhere(
        (p) => p['id'] == prof['id'],
      );
      if (index >= 0)
        _professoresSelecionados.removeAt(index);
      else
        _professoresSelecionados.add(prof);
    });
  }

  // =====================================
  // FUNÇÕES PARA MANIPULAR A TABELA
  // =====================================
  void _adicionarLinhaNaGrade({Map<dynamic, dynamic>? dadosIniciais}) {
    setState(() {
      _controladoresGrade.add({
        'horario': TextEditingController(text: dadosIniciais?['horario'] ?? ''),
        'seg': TextEditingController(text: dadosIniciais?['seg'] ?? ''),
        'ter': TextEditingController(text: dadosIniciais?['ter'] ?? ''),
        'qua': TextEditingController(text: dadosIniciais?['qua'] ?? ''),
        'qui': TextEditingController(text: dadosIniciais?['qui'] ?? ''),
        'sex': TextEditingController(text: dadosIniciais?['sex'] ?? ''),
        'sab': TextEditingController(text: dadosIniciais?['sab'] ?? ''),
      });
    });
  }

  void _removerLinhaDaGrade(int index) {
    setState(() {
      // Limpa os controladores antes de remover para não dar leak de memória
      _controladoresGrade[index].values.forEach((c) => c.dispose());
      _controladoresGrade.removeAt(index);
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
              // TABELA DA GRADE DE AULAS EDITÁVEL
              // ====================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grade de Aulas:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _adicionarLinhaNaGrade(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Linha'),
                  ),
                ],
              ),

              // O Container cria uma caixa para a tabela com barra de rolagem horizontal
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 12,
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(label: Text('Horário (Ex: 07:30 - 08:20)')),
                      DataColumn(label: Text('Segunda')),
                      DataColumn(label: Text('Terça')),
                      DataColumn(label: Text('Quarta')),
                      DataColumn(label: Text('Quinta')),
                      DataColumn(label: Text('Sexta')),
                      DataColumn(label: Text('Sábado')),
                      DataColumn(label: Text('')), // Coluna da Lixeira
                    ],
                    rows: _controladoresGrade.asMap().entries.map((entrada) {
                      int index = entrada.key;
                      var controladores = entrada.value;

                      // Função rápida para padronizar as caixas de texto
                      Widget celulaTexto(
                        TextEditingController ctrl, {
                        double largura = 100,
                      }) {
                        return SizedBox(
                          width: largura,
                          child: TextField(
                            controller: ctrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.all(8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        );
                      }

                      return DataRow(
                        cells: [
                          DataCell(
                            celulaTexto(
                              controladores['horario']!,
                              largura: 130,
                            ),
                          ),
                          DataCell(celulaTexto(controladores['seg']!)),
                          DataCell(celulaTexto(controladores['ter']!)),
                          DataCell(celulaTexto(controladores['qua']!)),
                          DataCell(celulaTexto(controladores['qui']!)),
                          DataCell(celulaTexto(controladores['sex']!)),
                          DataCell(celulaTexto(controladores['sab']!)),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _removerLinhaDaGrade(index),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Vincular Professores:',
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
                  'Nenhum professor cadastrado.',
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
                      onSelected: (bool selected) => _alternarProfessor(prof),
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

    // Converte a lista de controladores de volta para texto puro para o Firebase
    List<Map<String, String>> gradeParaSalvar = _controladoresGrade.map((
      ctrls,
    ) {
      return {
        'horario': ctrls['horario']!.text.trim(),
        'seg': ctrls['seg']!.text.trim(),
        'ter': ctrls['ter']!.text.trim(),
        'qua': ctrls['qua']!.text.trim(),
        'qui': ctrls['qui']!.text.trim(),
        'sex': ctrls['sex']!.text.trim(),
        'sab': ctrls['sab']!.text.trim(),
      };
    }).toList();

    // Filtra para não salvar linhas que estejam completamente vazias (sem horário e sem matérias)
    gradeParaSalvar.removeWhere(
      (linha) =>
          linha['horario']!.isEmpty &&
          linha['seg']!.isEmpty &&
          linha['ter']!.isEmpty &&
          linha['qua']!.isEmpty &&
          linha['qui']!.isEmpty &&
          linha['sex']!.isEmpty &&
          linha['sab']!.isEmpty,
    );

    Map<String, dynamic> dadosTurma = {
      'nome': _turmaSelecionada,
      'turno': _turnoSelecionado,
      'professores': _professoresSelecionados,
      'gradeLista': gradeParaSalvar, // A Tabela vai para o banco como Lista
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
              Navigator.pop(ctx);
              Navigator.pop(context);
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
