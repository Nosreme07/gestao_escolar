import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ==========================================
// ABA 6: RELATÓRIOS DA ESCOLA
// ==========================================
class AbaRelatorios extends StatelessWidget {
  const AbaRelatorios({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Central de Relatórios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Selecione o relatório que deseja gerar. O documento será criado em formato PDF.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // CARTÃO 1: LISTA GERAL DE ALUNOS
          _CartaoRelatorio(
            titulo: 'Lista Geral de Alunos',
            descricao:
                'Alunos separados por Turma/Turno na ordem correta (Maternal ao E.M.). Mostra RA, Nome e Contato.',
            icone: Icons.format_list_bulleted,
            cor: Colors.blue,
            aoClicar: () => _gerarRelatorioGeralAlunos(context),
          ),

          // CARTÃO 2: RELATÓRIO POR TURMA
          _CartaoRelatorio(
            titulo: 'Relatório por Turma',
            descricao:
                'Selecione uma turma específica para gerar a lista de alunos matriculados.',
            icone: Icons.meeting_room,
            cor: Colors.orange,
            aoClicar: () => _abrirPopupRelatorioTurma(context),
          ),

          // CARTÃO 3: PROFESSORES
          _CartaoRelatorio(
            titulo: 'Lista de Professores',
            descricao:
                'Gera um PDF com o Nome Completo, Disciplina e Contato de todos os professores.',
            icone: Icons.school,
            cor: Colors.teal,
            aoClicar: () => _gerarRelatorioProfessores(context),
          ),

          // CARTÃO 4: USUÁRIOS
          _CartaoRelatorio(
            titulo: 'Usuários do Sistema',
            descricao:
                'Relação de todos os usuários cadastrados, Perfil de acesso e Login.',
            icone: Icons.admin_panel_settings,
            cor: Colors.purple,
            aoClicar: () => _gerarRelatorioUsuarios(context),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FUNÇÕES GERADORAS DE PDF E ORDENAÇÃO
  // ==========================================

  // Função para dar o "peso" correto para cada turma (ordem cronológica)
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
    ];

    for (int i = 0; i < ordemCorreta.length; i++) {
      if (nomeDaTurma.contains(ordemCorreta[i])) return i;
    }
    return 99; // Se for uma turma desconhecida, vai para o final
  }

  // Função para dar peso aos turnos
  int _pesoDoTurno(String nomeDoTurno) {
    if (nomeDoTurno.contains('Manhã')) return 0;
    if (nomeDoTurno.contains('Tarde')) return 1;
    if (nomeDoTurno.contains('Noite')) return 2;
    return 3;
  }

  // 1. RELATÓRIO GERAL DE ALUNOS (Agrupado por Turma/Turno e Ordenado)
  Future<void> _gerarRelatorioGeralAlunos(BuildContext context) async {
    _mostrarCarregando(context);
    try {
      final snap = await FirebaseFirestore.instance.collection('alunos').get();
      final alunos = snap.docs.map((d) => d.data()).toList();

      // Agrupa os alunos por "Turma - Turno"
      Map<String, List<Map<String, dynamic>>> alunosAgrupados = {};

      for (var aluno in alunos) {
        String turma = aluno['turma'] ?? 'Sem Turma';
        String turno = aluno['turno'] ?? 'Sem Turno';
        String chaveGrupo = '$turma - $turno';

        if (!alunosAgrupados.containsKey(chaveGrupo)) {
          alunosAgrupados[chaveGrupo] = [];
        }
        alunosAgrupados[chaveGrupo]!.add(aluno);
      }

      // Ordena as turmas pela regra cronológica e depois pelo turno
      List<String> chavesOrdenadas = alunosAgrupados.keys.toList();
      chavesOrdenadas.sort((a, b) {
        int pesoTurmaA = _pesoDaTurma(a);
        int pesoTurmaB = _pesoDaTurma(b);
        if (pesoTurmaA == pesoTurmaB) {
          return _pesoDoTurno(a).compareTo(_pesoDoTurno(b));
        }
        return pesoTurmaA.compareTo(pesoTurmaB);
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
          build: (pw.Context context) {
            List<pw.Widget> conteudoPdf = [
              _cabecalhoPadrao(
                'Lista Geral de Alunos (Por Turma)',
                alunos.length,
              ),
            ];

            for (String chave in chavesOrdenadas) {
              // Ordena os alunos alfabeticamente dentro da turma
              List<Map<String, dynamic>> alunosDaTurma =
                  alunosAgrupados[chave]!;
              alunosDaTurma.sort(
                (a, b) => (a['nomeCompleto'] ?? '').compareTo(
                  b['nomeCompleto'] ?? '',
                ),
              );

              // Prepara os dados para a tabela
              final data = alunosDaTurma.map((a) {
                String contatoEmergencia = 'Não informado';
                final emergenciaLista = a['emergencia'] as List<dynamic>?;
                if (emergenciaLista != null && emergenciaLista.isNotEmpty) {
                  contatoEmergencia =
                      '${emergenciaLista[0]['nome'] ?? ''} (${emergenciaLista[0]['telefone'] ?? ''})';
                }

                return [
                  a['ra']?.toString() ?? '-',
                  a['nomeCompleto']?.toString() ?? '-',
                  contatoEmergencia,
                ];
              }).toList();

              // Adiciona o título da Turma e a Tabela CENTRALIZADA
              conteudoPdf.add(pw.SizedBox(height: 15));
              conteudoPdf.add(
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.all(6),
                  width: double.infinity,
                  child: pw.Text(
                    'Turma: $chave',
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
                  cellAlignment:
                      pw.Alignment.center, // <--- TUDO CENTRALIZADO AQUI
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

      Navigator.pop(context); // Fecha o loading
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Relatorio_Geral_Alunos.pdf',
      );
    } catch (e) {
      Navigator.pop(context);
      _mostrarErro(context, e.toString());
    }
  }

  // 2. RELATÓRIO POR TURMA (Pop-up de seleção)
  void _abrirPopupRelatorioTurma(BuildContext context) {
    String? turmaTurnoSelecionado;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Relatório por Turma'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selecione a turma desejada:'),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('turmas')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();

                    final turmasDocs = snapshot.data!.docs;
                    if (turmasDocs.isEmpty)
                      return const Text('Nenhuma turma cadastrada.');

                    List<String> opcoesTurma = turmasDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return '${data['nome']} - ${data['turno']}';
                    }).toList();

                    // Ordena o Dropdown também de forma cronológica
                    opcoesTurma.sort((a, b) {
                      int pesoTurmaA = _pesoDaTurma(a);
                      int pesoTurmaB = _pesoDaTurma(b);
                      if (pesoTurmaA == pesoTurmaB)
                        return _pesoDoTurno(a).compareTo(_pesoDoTurno(b));
                      return pesoTurmaA.compareTo(pesoTurmaB);
                    });

                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: turmaTurnoSelecionado,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Escolha uma turma'),
                      items: opcoesTurma
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => turmaTurnoSelecionado = val),
                    );
                  },
                ),
              ],
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
                  backgroundColor: Colors.blue[900],
                ),
                onPressed: () {
                  if (turmaTurnoSelecionado != null) {
                    Navigator.pop(ctx);
                    _gerarRelatorioTurmaEspecifica(
                      context,
                      turmaTurnoSelecionado!,
                    );
                  }
                },
                child: const Text(
                  'GERAR PDF',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _gerarRelatorioTurmaEspecifica(
    BuildContext context,
    String turmaTurno,
  ) async {
    _mostrarCarregando(context);
    try {
      final partes = turmaTurno.split(' - ');
      final nomeTurma = partes[0];
      final turno = partes.length > 1 ? partes[1] : '';

      final snap = await FirebaseFirestore.instance
          .collection('alunos')
          .where('turma', isEqualTo: nomeTurma)
          .where('turno', isEqualTo: turno)
          .get();

      final alunos = snap.docs.map((d) => d.data()).toList();
      alunos.sort(
        (a, b) => (a['nomeCompleto'] ?? '').compareTo(b['nomeCompleto'] ?? ''),
      );

      final pdf = pw.Document();
      final headers = [
        'Matrícula (RA)',
        'Nome Completo',
        'Contato de Emergência',
      ];

      final data = alunos.map((a) {
        String contatoEmergencia = 'Não informado';
        final emergenciaLista = a['emergencia'] as List<dynamic>?;
        if (emergenciaLista != null && emergenciaLista.isNotEmpty) {
          contatoEmergencia =
              '${emergenciaLista[0]['nome'] ?? ''} (${emergenciaLista[0]['telefone'] ?? ''})';
        }
        return [
          a['ra']?.toString() ?? '-',
          a['nomeCompleto']?.toString() ?? '-',
          contatoEmergencia,
        ];
      }).toList();

      pdf.addPage(
        _criarPaginaPDFSimples(
          'Relatório da Turma: $turmaTurno',
          headers,
          data,
          alunos.length,
        ),
      );

      Navigator.pop(context);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Relatorio_Turma.pdf',
      );
    } catch (e) {
      Navigator.pop(context);
      _mostrarErro(context, e.toString());
    }
  }

  // 3. RELATÓRIO DE PROFESSORES
  Future<void> _gerarRelatorioProfessores(BuildContext context) async {
    _mostrarCarregando(context);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('professores')
          .orderBy('nome')
          .get();
      final professores = snap.docs.map((d) => d.data()).toList();

      final pdf = pw.Document();
      final headers = ['Nome Completo', 'Disciplina', 'Contato'];

      final data = professores
          .map(
            (p) => [
              p['nome']?.toString() ?? '-',
              p['disciplina']?.toString() ?? '-',
              p['contato']?.toString() ?? '-',
            ],
          )
          .toList();

      pdf.addPage(
        _criarPaginaPDFSimples(
          'Relatório Geral de Professores',
          headers,
          data,
          professores.length,
        ),
      );

      Navigator.pop(context);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Relatorio_Professores.pdf',
      );
    } catch (e) {
      Navigator.pop(context);
      _mostrarErro(context, e.toString());
    }
  }

  // 4. RELATÓRIO DE USUÁRIOS
  Future<void> _gerarRelatorioUsuarios(BuildContext context) async {
    _mostrarCarregando(context);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .orderBy('nome')
          .get();
      final usuarios = snap.docs.map((d) => d.data()).toList();

      final pdf = pw.Document();
      final headers = [
        'Nome do Usuário',
        'Perfil de Acesso',
        'Login Escolhido',
      ];

      final data = usuarios
          .map(
            (u) => [
              u['nome']?.toString() ?? '-',
              u['perfil']?.toString() ?? '-',
              u['login']?.toString() ?? '-',
            ],
          )
          .toList();

      pdf.addPage(
        _criarPaginaPDFSimples(
          'Relação de Usuários do Sistema',
          headers,
          data,
          usuarios.length,
        ),
      );

      Navigator.pop(context);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Relatorio_Usuarios.pdf',
      );
    } catch (e) {
      Navigator.pop(context);
      _mostrarErro(context, e.toString());
    }
  }

  // ==========================================
  // MOLDURAS PADRÃO DO PDF (Centralizadas)
  // ==========================================

  pw.Widget _cabecalhoPadrao(String tituloRelatorio, int totalRegistros) {
    final hoje = DateTime.now();
    final dataFormatada =
        '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';

    return pw.Column(
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
              'Data: $dataFormatada',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue900),
        pw.SizedBox(height: 10),
        pw.Text(
          tituloRelatorio,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Total de registros: $totalRegistros',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Page _criarPaginaPDFSimples(
    String tituloRelatorio,
    List<String> headers,
    List<List<String>> data,
    int totalRegistros,
  ) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          _cabecalhoPadrao(tituloRelatorio, totalRegistros),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment:
                pw.Alignment.center, // <--- TUDO CENTRALIZADO AQUI TAMBÉM
            cellPadding: const pw.EdgeInsets.all(6),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ];
      },
    );
  }

  // ==========================================
  // FUNÇÕES AUXILIARES
  // ==========================================
  void _mostrarCarregando(BuildContext context) {
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
                Text('Gerando documento PDF...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarErro(BuildContext context, String erro) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao gerar relatório: $erro'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ==========================================
// WIDGET DO CARTÃO DE RELATÓRIO
// ==========================================
class _CartaoRelatorio extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;
  final VoidCallback aoClicar;

  const _CartaoRelatorio({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
    required this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: aoClicar,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, size: 32, color: cor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'GERAR',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
