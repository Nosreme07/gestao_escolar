import 'dart:typed_data'; // <-- IMPORT ADICIONADO PARA LER A IMAGEM
import 'package:flutter/material.dart';
import 'package:gestao_escolar/nucleo/cores.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // <-- IMPORT DO IMAGE PICKER ADICIONADO

class CadastroAlunoTela extends StatefulWidget {
  const CadastroAlunoTela({super.key});

  @override
  State<CadastroAlunoTela> createState() => _CadastroAlunoTelaState();
}

class _CadastroAlunoTelaState extends State<CadastroAlunoTela> {
  int _passoAtual = 0;

  // --- CONFIGURAÇÃO DAS MÁSCARAS ---
  final _mascaraData = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _mascaraCPF = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // --- VARIÁVEIS DA FOTO ---
  final ImagePicker _selecionadorImagem = ImagePicker();
  Uint8List?
  _imagemBytes; // Usamos Uint8List pois funciona bem na Web e no Celular

  // --- CONTROLADORES: PASSO 1 (Identificação) ---
  final _nomeAlunoCtrl = TextEditingController();
  final _dataNascCtrl = TextEditingController();
  String _sexo = 'Masculino';
  String? _turmaSelecionada;
  String? _turnoSelecionado;

  bool _temIrmao = false;
  String? _irmaoSelecionado;

  // Listas para os Dropdowns
  final List<String> _turmas = [
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
  final List<String> _turnos = ['Manhã', 'Tarde', 'Noite'];
  final List<String> _alunosCadastradosMock = [
    '2025001 - João Silva',
    '2025089 - Maria Souza',
  ];

  // --- CONTROLADORES: PASSO 2 (Endereço) ---
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();

  // --- CONTROLADORES: PASSO 3 (Responsáveis) ---
  String _responsavelFinanceiro = 'Mãe';
  bool _podeSairSozinho = false;

  final _nomeMaeCtrl = TextEditingController();
  final _cpfMaeCtrl = TextEditingController();
  final _telMaeCtrl = TextEditingController();
  final _emailMaeCtrl = TextEditingController();

  final _nomePaiCtrl = TextEditingController();
  final _cpfPaiCtrl = TextEditingController();
  final _telPaiCtrl = TextEditingController();
  final _emailPaiCtrl = TextEditingController();

  // --- CONTROLADORES: PASSO 4 (Saúde e Emergência) ---
  bool _temProblemaSaude = false;
  final _problemaSaudeCtrl = TextEditingController();

  bool _tomaMedicamento = false;
  final _medicamentoCtrl = TextEditingController();

  bool _temAlergia = false;
  final _alergiaCtrl = TextEditingController();

  final _observacaoSaudeCtrl = TextEditingController();

  final _emergenciaNome1Ctrl = TextEditingController();
  final _emergenciaTel1Ctrl = TextEditingController();
  final _emergenciaNome2Ctrl = TextEditingController();
  final _emergenciaTel2Ctrl = TextEditingController();

  // ==========================================
  // FUNÇÕES DA CÂMERA E GALERIA
  // ==========================================
  Future<void> _capturarImagem(ImageSource fonte) async {
    try {
      final XFile? imagem = await _selecionadorImagem.pickImage(
        source: fonte,
        imageQuality: 70, // Reduz a qualidade para economizar espaço
      );

      if (imagem != null) {
        // Lemos como bytes para garantir compatibilidade Web/Mobile
        final bytes = await imagem.readAsBytes();
        setState(() {
          _imagemBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar a imagem: $e')));
    }
  }

  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Escolha a foto do aluno',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: CoresDomex.azulPrincipal,
                  ),
                  title: const Text('Escolher da Galeria'),
                  onTap: () {
                    Navigator.of(context).pop(); // Fecha o menu
                    _capturarImagem(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: CoresDomex.azulPrincipal,
                  ),
                  title: const Text('Tirar Foto (Câmera)'),
                  onTap: () {
                    Navigator.of(context).pop(); // Fecha o menu
                    _capturarImagem(ImageSource.camera);
                  },
                ),
                if (_imagemBytes != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Remover Foto',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _imagemBytes = null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Matrícula'),
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        type: StepperType.vertical,
        physics: const ClampingScrollPhysics(),
        currentStep: _passoAtual,
        onStepTapped: (passo) => setState(() => _passoAtual = passo),
        onStepContinue: () {
          if (_passoAtual < 3) {
            setState(() => _passoAtual += 1);
          } else {
            _mostrarPopupConfirmacao();
          }
        },
        onStepCancel: () {
          if (_passoAtual > 0) setState(() => _passoAtual -= 1);
        },
        controlsBuilder: (context, details) {
          final isUltimo = _passoAtual == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUltimo
                          ? CoresDomex.verdeSucesso
                          : CoresDomex.azulPrincipal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isUltimo ? 'REVISAR E SALVAR' : 'PRÓXIMO PASSO',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_passoAtual > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text(
                      'Voltar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          _construirPassoIdentificacao(),
          _construirPassoEndereco(),
          _construirPassoResponsaveis(),
          _construirPassoSaude(),
        ],
      ),
    );
  }

  // ==========================================
  // PASSO 1: IDENTIFICAÇÃO DO ALUNO
  // ==========================================
  Step _construirPassoIdentificacao() {
    return Step(
      isActive: _passoAtual >= 0,
      title: const Text(
        'Identificação do Aluno(a)',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área de Foto ATUALIZADA
          Center(
            child: InkWell(
              onTap: _mostrarOpcoesFoto,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  // Se tiver imagem, mostra ela no fundo
                  image: _imagemBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_imagemBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                // Só mostra o ícone e o texto se a foto for NULA
                child: _imagemBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Anexar Foto\n(Toque aqui)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      )
                    : null, // Se tem foto, o filho é nulo (fica só o fundo)
              ),
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _nomeAlunoCtrl,
            decoration: const InputDecoration(labelText: 'Nome Completo'),
          ),
          const SizedBox(height: 16),

          const Text(
            'Sexo:',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Row(
            children: [
              Radio(
                value: 'Masculino',
                groupValue: _sexo,
                onChanged: (val) => setState(() => _sexo = val.toString()),
              ),
              const Text('Masculino'),
              const SizedBox(width: 16),
              Radio(
                value: 'Feminino',
                groupValue: _sexo,
                onChanged: (val) => setState(() => _sexo = val.toString()),
              ),
              const Text('Feminino'),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _dataNascCtrl,
            decoration: const InputDecoration(
              labelText: 'Data de Nascimento (DD/MM/AAAA)',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [_mascaraData],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _turmaSelecionada,
            decoration: const InputDecoration(labelText: 'Turma'),
            items: _turmas
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) => setState(() => _turmaSelecionada = val),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _turnoSelecionado,
            decoration: const InputDecoration(labelText: 'Turno'),
            items: _turnos
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) => setState(() => _turnoSelecionado = val),
          ),
          const SizedBox(height: 24),

          const Text(
            'O aluno tem algum irmão na escola?',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Row(
            children: [
              Radio(
                value: true,
                groupValue: _temIrmao,
                onChanged: (val) => setState(() => _temIrmao = val as bool),
              ),
              const Text('Sim'),
              const SizedBox(width: 16),
              Radio(
                value: false,
                groupValue: _temIrmao,
                onChanged: (val) => setState(() => _temIrmao = val as bool),
              ),
              const Text('Não'),
            ],
          ),
          if (_temIrmao) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _irmaoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Selecione o irmão cadastrado',
              ),
              items: _alunosCadastradosMock
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (val) => setState(() => _irmaoSelecionado = val),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // PASSO 2: ENDEREÇO
  // ==========================================
  Step _construirPassoEndereco() {
    return Step(
      isActive: _passoAtual >= 1,
      title: const Text(
        'Endereço',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Column(
        children: [
          TextFormField(
            controller: _ruaCtrl,
            decoration: const InputDecoration(labelText: 'Rua'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _numeroCtrl,
                  decoration: const InputDecoration(labelText: 'Nº'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _bairroCtrl,
                  decoration: const InputDecoration(labelText: 'Bairro'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cidadeCtrl,
            decoration: const InputDecoration(labelText: 'Cidade'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PASSO 3: RESPONSÁVEIS E AUTORIZAÇÃO
  // ==========================================
  Step _construirPassoResponsaveis() {
    return Step(
      isActive: _passoAtual >= 2,
      title: const Text(
        'Responsáveis',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quem é o Responsável Financeiro?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Radio(
                      value: 'Mãe',
                      groupValue: _responsavelFinanceiro,
                      onChanged: (v) =>
                          setState(() => _responsavelFinanceiro = v.toString()),
                    ),
                    const Text('Mãe'),
                    const SizedBox(width: 16),
                    Radio(
                      value: 'Pai',
                      groupValue: _responsavelFinanceiro,
                      onChanged: (v) =>
                          setState(() => _responsavelFinanceiro = v.toString()),
                    ),
                    const Text('Pai'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Dados da Mãe',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: CoresDomex.azulPrincipal,
            ),
          ),
          const Divider(),
          TextFormField(
            controller: _nomeMaeCtrl,
            decoration: const InputDecoration(labelText: 'Nome Completo'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cpfMaeCtrl,
            decoration: const InputDecoration(
              labelText: 'CPF (xxx.xxx.xxx-xx)',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [_mascaraCPF],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telMaeCtrl,
            decoration: const InputDecoration(
              labelText: 'Telefone: (xx)xxxxx-xxxx',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [_mascaraTelefone],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailMaeCtrl,
            decoration: const InputDecoration(labelText: 'E-mail'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),

          const Text(
            'Dados do Pai',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: CoresDomex.azulPrincipal,
            ),
          ),
          const Divider(),
          TextFormField(
            controller: _nomePaiCtrl,
            decoration: const InputDecoration(labelText: 'Nome Completo'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cpfPaiCtrl,
            decoration: const InputDecoration(
              labelText: 'CPF (xxx.xxx.xxx-xx)',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [_mascaraCPF],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telPaiCtrl,
            decoration: const InputDecoration(
              labelText: 'Telefone: (xx)xxxxx-xxxx',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [_mascaraTelefone],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailPaiCtrl,
            decoration: const InputDecoration(labelText: 'E-mail'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SwitchListTile(
              title: const Text(
                'Autorização de Saída',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Autorizo o aluno a sair sozinho da escola.',
              ),
              value: _podeSairSozinho,
              activeColor: Colors.red,
              onChanged: (val) => setState(() => _podeSairSozinho = val),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PASSO 4: FICHA MÉDICA E EMERGÊNCIA
  // ==========================================
  Step _construirPassoSaude() {
    return Step(
      isActive: _passoAtual >= 3,
      title: const Text(
        'Ficha Médica e Emergência',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ficha Médica',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: CoresDomex.azulPrincipal,
            ),
          ),
          const Divider(),

          SwitchListTile(
            title: const Text('Possui problema de saúde?'),
            value: _temProblemaSaude,
            onChanged: (v) => setState(() => _temProblemaSaude = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_temProblemaSaude) ...[
            TextFormField(
              controller: _problemaSaudeCtrl,
              decoration: const InputDecoration(labelText: 'Qual problema?'),
            ),
            const SizedBox(height: 16),
          ],

          SwitchListTile(
            title: const Text('Toma algum medicamento?'),
            value: _tomaMedicamento,
            onChanged: (v) => setState(() => _tomaMedicamento = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_tomaMedicamento) ...[
            TextFormField(
              controller: _medicamentoCtrl,
              decoration: const InputDecoration(labelText: 'Qual medicamento?'),
            ),
            const SizedBox(height: 16),
          ],

          SwitchListTile(
            title: const Text('Tem alguma alergia?'),
            value: _temAlergia,
            onChanged: (v) => setState(() => _temAlergia = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_temAlergia) ...[
            TextFormField(
              controller: _alergiaCtrl,
              decoration: const InputDecoration(labelText: 'Qual alergia?'),
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _observacaoSaudeCtrl,
            decoration: const InputDecoration(
              labelText: 'Observações Gerais (Opcional)',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          const Text(
            'Em caso de emergência, avisar:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _emergenciaNome1Ctrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _emergenciaTel1Ctrl,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_mascaraTelefone],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _emergenciaNome2Ctrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _emergenciaTel2Ctrl,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_mascaraTelefone],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TELA DE REVISÃO E SALVAMENTO NO FIREBASE
  // ==========================================
  void _mostrarPopupConfirmacao() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Revisar Dados',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _linhaResumo('Aluno:', _nomeAlunoCtrl.text),
                _linhaResumo('Nascimento:', _dataNascCtrl.text),
                _linhaResumo('Turma:', _turmaSelecionada ?? 'Não definida'),
                _linhaResumo('Turno:', _turnoSelecionado ?? 'Não definido'),
                const Divider(),
                _linhaResumo('Resp. Financeiro:', _responsavelFinanceiro),
                _linhaResumo('Nome da Mãe:', _nomeMaeCtrl.text),
                _linhaResumo('Nome do Pai:', _nomePaiCtrl.text),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('EDITAR', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CoresDomex.verdeSucesso,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _finalizarMatricula();
              },
              child: const Text('CONFIRMAR'),
            ),
          ],
        );
      },
    );
  }

  Widget _linhaResumo(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$titulo ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: valor.isEmpty ? 'Não informado' : valor),
          ],
        ),
      ),
    );
  }

  void _finalizarMatricula() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: CoresDomex.azulPrincipal),
      ),
    );

    try {
      final anoAtual = DateTime.now().year;
      final sequencial = (DateTime.now().millisecondsSinceEpoch % 10000)
          .toString()
          .padLeft(4, '0');
      final raGerado = "$anoAtual$sequencial";

      final nomeAluno = _nomeAlunoCtrl.text.isEmpty
          ? "Aluno Sem Nome"
          : _nomeAlunoCtrl.text;

      // ATENÇÃO: Se quiser salvar a foto (_imagemBytes) online, será necessário
      // usar o Firebase Storage para fazer o upload do arquivo primeiro, e depois
      // salvar a URL da imagem aqui no Firestore.

      Map<String, dynamic> dadosAluno = {
        'ra': raGerado,
        'nomeCompleto': nomeAluno,
        'dataNascimento': _dataNascCtrl.text,
        'sexo': _sexo,
        'turma': _turmaSelecionada,
        'turno': _turnoSelecionado,
        'temIrmaoNaEscola': _temIrmao,
        'irmaoVinculado': _irmaoSelecionado,
        'endereco': {
          'rua': _ruaCtrl.text,
          'numero': _numeroCtrl.text,
          'bairro': _bairroCtrl.text,
          'cidade': _cidadeCtrl.text,
        },
        'responsaveis': {
          'responsavelFinanceiro': _responsavelFinanceiro,
          'autorizadoSairSozinho': _podeSairSozinho,
          'mae': {
            'nome': _nomeMaeCtrl.text,
            'cpf': _cpfMaeCtrl.text,
            'telefone': _telMaeCtrl.text,
            'email': _emailMaeCtrl.text,
          },
          'pai': {
            'nome': _nomePaiCtrl.text,
            'cpf': _cpfPaiCtrl.text,
            'telefone': _telPaiCtrl.text,
            'email': _emailPaiCtrl.text,
          },
        },
        'saude': {
          'temProblemaSaude': _temProblemaSaude,
          'qualProblema': _problemaSaudeCtrl.text,
          'tomaMedicamento': _tomaMedicamento,
          'qualMedicamento': _medicamentoCtrl.text,
          'temAlergia': _temAlergia,
          'qualAlergia': _alergiaCtrl.text,
          'observacoes': _observacaoSaudeCtrl.text,
        },
        'emergencia': [
          {
            'nome': _emergenciaNome1Ctrl.text,
            'telefone': _emergenciaTel1Ctrl.text,
          },
          {
            'nome': _emergenciaNome2Ctrl.text,
            'telefone': _emergenciaTel2Ctrl.text,
          },
        ],
        'dataMatricula': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('alunos')
          .doc(raGerado)
          .set(dadosAluno);

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: CoresDomex.verdeSucesso,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Matrícula Concluída!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Os dados foram salvos no Firebase com sucesso.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aluno(a):',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    nomeAluno,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Número da Matrícula (RA):',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      raGerado,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: CoresDomex.azulPrincipal,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresDomex.azulPrincipal,
                  ),
                  child: const Text('VOLTAR AO PAINEL'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar no Firebase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
