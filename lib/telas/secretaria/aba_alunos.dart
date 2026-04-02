import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestao_escolar/telas/secretaria/cadastro_aluno.dart';
import 'package:url_launcher/url_launcher.dart'; // Para ligações e WhatsApp
import 'package:pdf/pdf.dart'; // Para montar o PDF
import 'package:pdf/widgets.dart' as pw; // Para desenhar o PDF
import 'package:printing/printing.dart'; // Para compartilhar o PDF

// ==========================================
// ABA 1: LISTAGEM DE ALUNOS
// ==========================================
class AbaAlunos extends StatefulWidget {
  const AbaAlunos({super.key});

  @override
  State<AbaAlunos> createState() => _AbaAlunosState();
}

class _AbaAlunosState extends State<AbaAlunos> {
  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 1. CAMPO DE BUSCA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                labelText: 'Buscar por Nome ou Matrícula',
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
          // 2. LISTA DE ALUNOS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alunos')
                  .snapshots(),
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

                // Filtrar os documentos com base no termo de busca
                var alunosDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome = (data['nomeCompleto'] ?? '')
                      .toString()
                      .toLowerCase();
                  final matricula = (data['ra'] ?? '').toString().toLowerCase();
                  return nome.contains(_termoBusca) ||
                      matricula.contains(_termoBusca);
                }).toList();

                if (alunosDocs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum aluno encontrado para esta busca.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: alunosDocs.length,
                  itemBuilder: (context, index) {
                    final alunoData =
                        alunosDocs[index].data() as Map<String, dynamic>;
                    final docId = alunosDocs[index].id;

                    final nome = alunoData['nomeCompleto'] ?? 'Sem Nome';
                    final matricula = alunoData['ra'] ?? 'Sem RA';
                    final turma = alunoData['turma'] ?? 'Sem Turma';
                    final fotoUrl = alunoData['fotoUrl'] as String?;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          // Abre o perfil do aluno ao clicar no Card
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
                            nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Matrícula: $matricula | Turma: $turma',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
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
            Center(
              child: fotoUrl != null && fotoUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(fotoUrl),
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
            const SizedBox(height: 24),

            // BOTÕES DE AÇÃO
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
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
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Editar',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _confirmarExclusao(context, docId, 'alunos'),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text(
                    'Excluir',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _construirBotaoAcao(
              context,
              icone: Icons.assignment_ind,
              titulo: 'Ficha Cadastral',
              cor: Colors.blue,
              aoClicar: () =>
                  _mostrarFichaCadastralCompleta(context, alunoData),
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
                Navigator.pop(context);
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
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ficha Cadastral',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                            ),
                            tooltip: 'Exportar PDF',
                            onPressed: () =>
                                _gerarECompartilharPDF(context, dados),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            tooltip: 'Fechar',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 10),

                  _tituloSecao('1. Identificação'),
                  _linhaDado('Nome', dados['nomeCompleto']),
                  _linhaDado('RA (Matrícula)', dados['ra']),
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

                  _tituloSecao('2. Endereço'),
                  _linhaDado('Rua', endereco['rua']),
                  _linhaDado('Nº', endereco['numero']),
                  _linhaDado('Bairro', endereco['bairro']),
                  _linhaDado('Cidade', endereco['cidade']),
                  _linhaDado(
                    'Referência',
                    endereco['pontoReferencia'],
                  ), // <-- EXIBIÇÃO NO APP AQUI
                  const SizedBox(height: 16),

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
                  _linhaTelefoneAcao('Telefone', mae['telefone']),
                  const SizedBox(height: 8),
                  const Text(
                    'Dados do Pai',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  _linhaDado('Nome', pai['nome']),
                  _linhaTelefoneAcao('Telefone', pai['telefone']),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // FUNÇÕES DE LIGAÇÃO E WHATSAPP
  // ==========================================
  Future<void> _fazerLigacao(String numero) async {
    final Uri url = Uri.parse('tel:$numero');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _abrirWhatsApp(String numero) async {
    final Uri url = Uri.parse('https://wa.me/55$numero');
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ==========================================
  // GERADOR DE PDF (ATUALIZADO COM REFERÊNCIA)
  // ==========================================
  Future<void> _gerarECompartilharPDF(
    BuildContext context,
    Map<String, dynamic> dados,
  ) async {
    // Popup de Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdf = pw.Document();

      final endereco = dados['endereco'] ?? {};
      final resp = dados['responsaveis'] ?? {};
      final mae = resp['mae'] ?? {};
      final pai = resp['pai'] ?? {};
      final saude = dados['saude'] ?? {};

      // 1. Tenta carregar a imagem do Firebase para o PDF
      pw.ImageProvider? imagemPdf;
      if (dados['fotoUrl'] != null && dados['fotoUrl'].toString().isNotEmpty) {
        try {
          imagemPdf = await networkImage(dados['fotoUrl']);
        } catch (e) {
          debugPrint('Erro ao puxar imagem pro PDF: $e');
        }
      }

      // 2. Cria a data e hora para o rodapé
      final hoje = DateTime.now();
      final dataHora =
          '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year} às ${hoje.hour.toString().padLeft(2, '0')}:${hoje.minute.toString().padLeft(2, '0')}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          // RODAPÉ INTELIGENTE
          footer: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Ficha cadastral gerada pelo sistema de gestão escolar - $dataHora',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              // CABEÇALHO E FOTO
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Ficha Cadastral do Aluno(a)',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          '1. IDENTIFICAÇÃO',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Nome Completo: ${dados['nomeCompleto'] ?? 'Não informado'}',
                        ),
                        pw.Text(
                          'Matrícula (RA): ${dados['ra'] ?? 'Não informado'}',
                        ),
                        pw.Text(
                          'Data Nascimento: ${dados['dataNascimento'] ?? 'Não informado'}',
                        ),
                        pw.Text(
                          'Turma: ${dados['turma'] ?? '-'} | Turno: ${dados['turno'] ?? '-'}',
                        ),
                        pw.Text('Sexo: ${dados['sexo'] ?? '-'}'),
                      ],
                    ),
                  ),
                  if (imagemPdf != null)
                    pw.Container(
                      height: 100,
                      width: 100,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey400,
                          width: 2,
                        ),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                        image: pw.DecorationImage(
                          image: imagemPdf,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 16),

              // ENDEREÇO
              pw.Text(
                '2. ENDEREÇO',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Rua: ${endereco['rua'] ?? ''}, Nº ${endereco['numero'] ?? ''} - ${endereco['bairro'] ?? ''}, ${endereco['cidade'] ?? ''}',
              ),
              // <-- EXIBIÇÃO NO PDF AQUI
              pw.Text(
                'Ponto de Referência: ${endereco['pontoReferencia'] ?? 'Não informado'}',
              ),
              pw.SizedBox(height: 16),

              // RESPONSÁVEIS
              pw.Text(
                '3. RESPONSÁVEIS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Responsável Financeiro: ${resp['responsavelFinanceiro'] ?? ''}',
              ),
              pw.Text(
                'Autorizado a sair sozinho: ${resp['autorizadoSairSozinho'] == true ? 'Sim' : 'Não'}',
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Mãe: ${mae['nome'] ?? '-'} | Tel: ${mae['telefone'] ?? '-'} | CPF: ${mae['cpf'] ?? '-'}',
              ),
              pw.Text(
                'Pai: ${pai['nome'] ?? '-'} | Tel: ${pai['telefone'] ?? '-'} | CPF: ${pai['cpf'] ?? '-'}',
              ),
              pw.SizedBox(height: 16),

              // SAÚDE E EMERGÊNCIA
              pw.Text(
                '4. SAÚDE E EMERGÊNCIA',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Problema de Saúde: ${saude['temProblemaSaude'] == true ? 'Sim (${saude['qualProblema']})' : 'Não'}',
              ),
              pw.Text(
                'Toma Medicamento: ${saude['tomaMedicamento'] == true ? 'Sim (${saude['qualMedicamento']})' : 'Não'}',
              ),
              pw.Text(
                'Alergia: ${saude['temAlergia'] == true ? 'Sim (${saude['qualAlergia']})' : 'Não'}',
              ),
              pw.Text('Observações: ${saude['observacoes'] ?? 'Nenhuma'}'),
            ];
          },
        ),
      );

      // Fecha o loading e compartilha
      if (context.mounted) Navigator.pop(context);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Ficha_Cadastral_${dados['ra'] ?? 'aluno'}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==========================================
  // HELPERS VISUAIS DA FICHA
  // ==========================================
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

  Widget _linhaTelefoneAcao(String label, dynamic valor) {
    final numeroRaw = valor?.toString() ?? '';
    if (numeroRaw.trim().isEmpty) return _linhaDado(label, 'Não informado');

    final numeroLimpo = numeroRaw.replaceAll(RegExp(r'[^0-9]'), '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: numeroRaw),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.blue),
            tooltip: 'Ligar',
            onPressed: () => _fazerLigacao(numeroLimpo),
          ),
          IconButton(
            icon: const Icon(Icons.message, color: Colors.green),
            tooltip: 'WhatsApp',
            onPressed: () => _abrirWhatsApp(numeroLimpo),
          ),
        ],
      ),
    );
  }
}
