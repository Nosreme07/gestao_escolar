import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart'; // PACOTE DE ENQUADRAMENTO

// Certifique-se de que o caminho para as suas cores está correto!
import 'package:gestao_escolar/nucleo/cores.dart';

class CadastroAlunoTela extends StatefulWidget {
  final String? alunoIdAEditar;
  final Map<String, dynamic>? alunoDataAEditar;

  const CadastroAlunoTela({
    super.key,
    this.alunoIdAEditar,
    this.alunoDataAEditar,
  });

  @override
  State<CadastroAlunoTela> createState() => _CadastroAlunoTelaState();
}

class _CadastroAlunoTelaState extends State<CadastroAlunoTela> {
  int _passoAtual = 0;
  bool _estaSalvando = false;

  // --- MÁSCARAS ---
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
  Uint8List? _imagemBytes;
  String? _fotoUrlExistente;

  // --- CONTROLADORES E VARIÁVEIS ---
  final _nomeAlunoCtrl = TextEditingController();
  final _dataNascCtrl = TextEditingController();
  String _sexo = 'Masculino';
  String? _turmaSelecionada;
  String? _turnoSelecionado;
  bool _temIrmao = false;
  String? _irmaoSelecionado;

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

  // Lista temporária (idealmente puxada do Firebase)
  final List<String> _alunosCadastradosMock = [
    '2025001 - João Silva',
    '2025089 - Maria Souza',
  ];

  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();

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

  bool get isEdicao => widget.alunoIdAEditar != null;

  @override
  void initState() {
    super.initState();
    _carregarDadosParaEdicao();
  }

  void _carregarDadosParaEdicao() {
    if (widget.alunoDataAEditar != null &&
        widget.alunoDataAEditar!.isNotEmpty) {
      final dados = widget.alunoDataAEditar!;

      _nomeAlunoCtrl.text = dados['nomeCompleto'] ?? '';
      _dataNascCtrl.text = dados['dataNascimento'] ?? '';

      setState(() {
        _sexo = dados['sexo'] ?? 'Masculino';
        if (_turmas.contains(dados['turma']))
          _turmaSelecionada = dados['turma'];
        if (_turnos.contains(dados['turno']))
          _turnoSelecionado = dados['turno'];
        _temIrmao = dados['temIrmaoNaEscola'] ?? false;
        _fotoUrlExistente = dados['fotoUrl'];
      });

      final endereco = dados['endereco'] ?? {};
      _ruaCtrl.text = endereco['rua'] ?? '';
      _numeroCtrl.text = endereco['numero'] ?? '';
      _bairroCtrl.text = endereco['bairro'] ?? '';
      _cidadeCtrl.text = endereco['cidade'] ?? '';

      final responsaveis = dados['responsaveis'] ?? {};
      setState(() {
        _responsavelFinanceiro = responsaveis['responsavelFinanceiro'] ?? 'Mãe';
        _podeSairSozinho = responsaveis['autorizadoSairSozinho'] ?? false;
      });

      final mae = responsaveis['mae'] ?? {};
      _nomeMaeCtrl.text = mae['nome'] ?? '';
      _cpfMaeCtrl.text = mae['cpf'] ?? '';
      _telMaeCtrl.text = mae['telefone'] ?? '';
      _emailMaeCtrl.text = mae['email'] ?? '';

      final pai = responsaveis['pai'] ?? {};
      _nomePaiCtrl.text = pai['nome'] ?? '';
      _cpfPaiCtrl.text = pai['cpf'] ?? '';
      _telPaiCtrl.text = pai['telefone'] ?? '';
      _emailPaiCtrl.text = pai['email'] ?? '';

      final saude = dados['saude'] ?? {};
      setState(() {
        _temProblemaSaude = saude['temProblemaSaude'] ?? false;
        _tomaMedicamento = saude['tomaMedicamento'] ?? false;
        _temAlergia = saude['temAlergia'] ?? false;
      });

      _problemaSaudeCtrl.text = saude['qualProblema'] ?? '';
      _medicamentoCtrl.text = saude['qualMedicamento'] ?? '';
      _alergiaCtrl.text = saude['qualAlergia'] ?? '';
      _observacaoSaudeCtrl.text = saude['observacoes'] ?? '';

      final emergencia = dados['emergencia'] as List<dynamic>?;
      if (emergencia != null && emergencia.isNotEmpty) {
        _emergenciaNome1Ctrl.text = emergencia[0]['nome'] ?? '';
        _emergenciaTel1Ctrl.text = emergencia[0]['telefone'] ?? '';
        if (emergencia.length > 1) {
          _emergenciaNome2Ctrl.text = emergencia[1]['nome'] ?? '';
          _emergenciaTel2Ctrl.text = emergencia[1]['telefone'] ?? '';
        }
      }
    }
  }

  // ==========================================
  // FUNÇÕES DE FOTO COM ENQUADRAMENTO (CROP)
  // ==========================================
  Future<void> _capturarImagem(ImageSource fonte) async {
    try {
      final XFile? imagem = await _selecionadorImagem.pickImage(
        source: fonte,
        imageQuality: 80,
      );

      if (imagem != null) {
        // NOVO: Chama a tela de recorte antes de salvar
        CroppedFile? imagemCortada = await ImageCropper().cropImage(
          sourcePath: imagem.path,
          aspectRatio: const CropAspectRatio(
            ratioX: 1,
            ratioY: 1,
          ), // Obriga a ser quadrado
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Enquadrar Foto',
              toolbarColor: Colors.blue[900],
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: 'Enquadrar Foto',
              aspectRatioLockEnabled: true,
            ),
            WebUiSettings(context: context),
          ],
        );

        if (imagemCortada != null) {
          final bytes = await imagemCortada.readAsBytes();
          setState(() {
            _imagemBytes = bytes;
            _fotoUrlExistente = null; // Remove a antiga
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar a imagem: $e')),
        );
      }
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
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Escolher da Galeria e Recortar'),
                  onTap: () {
                    Navigator.pop(context);
                    _capturarImagem(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text('Tirar Foto e Recortar'),
                  onTap: () {
                    Navigator.pop(context);
                    _capturarImagem(ImageSource.camera);
                  },
                ),
                if (_imagemBytes != null || _fotoUrlExistente != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Remover Foto',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imagemBytes = null;
                        _fotoUrlExistente = null;
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

  // ==========================================
  // INTERFACE
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Aluno' : 'Nova Matrícula'),
        backgroundColor: Colors.blue[900], // CoresDomex.azulPrincipal
        foregroundColor: Colors.white,
      ),
      // BOTÃO FIXO DE SALVAR (Apenas no modo Edição)
      bottomNavigationBar: isEdicao
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // CoresDomex.verdeSucesso
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _estaSalvando ? null : _finalizarMatricula,
                  icon: _estaSalvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'SALVAR ALTERAÇÕES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          : null,
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
                          ? Colors.green
                          : Colors.blue[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isUltimo
                          ? (isEdicao ? 'IR PARA O FIM' : 'REVISAR E SALVAR')
                          : 'PRÓXIMO PASSO',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
          Center(
            child: InkWell(
              onTap: _mostrarOpcoesFoto,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  image: _imagemBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_imagemBytes!),
                          fit: BoxFit.cover,
                        )
                      : (_fotoUrlExistente != null &&
                                _fotoUrlExistente!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_fotoUrlExistente!),
                                fit: BoxFit.cover,
                              )
                            : null),
                ),
                child:
                    _imagemBytes == null &&
                        (_fotoUrlExistente == null ||
                            _fotoUrlExistente!.isEmpty)
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.crop_free, color: Colors.grey, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Anexar Foto\n(Toque aqui)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      )
                    : null,
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
                onChanged: (v) => setState(() => _sexo = v.toString()),
              ),
              const Text('Masculino'),
              const SizedBox(width: 16),
              Radio(
                value: 'Feminino',
                groupValue: _sexo,
                onChanged: (v) => setState(() => _sexo = v.toString()),
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
            onChanged: (v) => setState(() => _turmaSelecionada = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _turnoSelecionado,
            decoration: const InputDecoration(labelText: 'Turno'),
            items: _turnos
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _turnoSelecionado = v),
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
                onChanged: (v) => setState(() => _temIrmao = v as bool),
              ),
              const Text('Sim'),
              const SizedBox(width: 16),
              Radio(
                value: false,
                groupValue: _temIrmao,
                onChanged: (v) => setState(() => _temIrmao = v as bool),
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
              onChanged: (v) => setState(() => _irmaoSelecionado = v),
            ),
          ],
        ],
      ),
    );
  }

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
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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

  void _mostrarPopupConfirmacao() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Confirmar Dados',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Deseja salvar as informações no sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              _finalizarMatricula();
            },
            child: const Text('SALVAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SALVAMENTO NO FIREBASE (TEXTO E IMAGEM)
  // ==========================================
  void _finalizarMatricula() async {
    setState(() => _estaSalvando = true);

    // Popup visual de salvamento se for cadastro novo (se for edição, o botão gira)
    if (!isEdicao) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    try {
      final nomeAluno = _nomeAlunoCtrl.text.isEmpty
          ? "Aluno Sem Nome"
          : _nomeAlunoCtrl.text;

      String docId = widget.alunoIdAEditar ?? "";
      String raFinal = "";

      if (!isEdicao) {
        final anoAtual = DateTime.now().year;
        final sequencial = (DateTime.now().millisecondsSinceEpoch % 10000)
            .toString()
            .padLeft(4, '0');
        raFinal = "$anoAtual$sequencial";
        docId = raFinal;
      } else {
        raFinal = widget.alunoDataAEditar?['ra'] ?? "";
      }

      String? linkFotoFinal = _fotoUrlExistente;
      if (_imagemBytes != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'fotos_alunos/$docId.jpg',
        );
        await storageRef.putData(_imagemBytes!);
        linkFotoFinal = await storageRef.getDownloadURL();
      }

      Map<String, dynamic> dadosAluno = {
        'ra': raFinal,
        'nomeCompleto': nomeAluno,
        'dataNascimento': _dataNascCtrl.text,
        'sexo': _sexo,
        'turma': _turmaSelecionada,
        'turno': _turnoSelecionado,
        'temIrmaoNaEscola': _temIrmao,
        'irmaoVinculado': _irmaoSelecionado,
        'fotoUrl': linkFotoFinal,
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
      };

      if (isEdicao) {
        await FirebaseFirestore.instance
            .collection('alunos')
            .doc(docId)
            .update(dadosAluno);
      } else {
        dadosAluno['dataMatricula'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('alunos')
            .doc(docId)
            .set(dadosAluno);
      }

      if (!mounted) return;

      if (!isEdicao) Navigator.pop(context); // Tira o loading se for novo
      setState(() => _estaSalvando = false);
      Navigator.pop(context); // Volta pra lista

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (!isEdicao) Navigator.pop(context);
      setState(() => _estaSalvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
