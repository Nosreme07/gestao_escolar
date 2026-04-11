import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:gestao_escolar/nucleo/cores.dart';
import 'package:gestao_escolar/telas/secretaria/tela_secretaria.dart';
import 'package:gestao_escolar/telas/professor/inicio_professor_tela.dart';
import 'package:gestao_escolar/telas/login/login_tela.dart';

// ==========================================
// TELA PRINCIPAL (DASHBOARD/MENU)
// Esta é a tela central do aplicativo, exibida logo após o login.
// Ela direciona o utilizador para o módulo correto dependendo do que ele precisa acessar.
// ==========================================
class TelaPrincipal extends StatelessWidget {
  // Recebe o ID do usuário logado (vindo da tela de Login) para buscar os dados de perfil depois.
  final String? usuarioId;

  const TelaPrincipal({super.key, this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- BARRA SUPERIOR (APP BAR) ---
      appBar: AppBar(
        title: const Text('Domex Tech'),
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
        elevation:
            0, // Zero elevation remove a sombra, deixando o design mais plano e moderno
        actions: [
          // Botão para acessar o Perfil do Utilizador
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            tooltip: 'Meu Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelaPerfil(usuarioId: usuarioId),
                ),
              );
            },
          ),

          // --- NOVO BOTÃO DE LOGOUT ---
          IconButton(
            icon: const Icon(Icons.exit_to_app, size: 28),
            tooltip: 'Sair do Sistema',
            onPressed: () {
              // Exibe um pop-up de confirmação antes de sair
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
                        Navigator.pop(ctx); // Fecha o pop-up

                        // Volta para a Tela de Login e limpa todo o histórico (evita que o botão "Voltar" do telemóvel funcione)
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
          const SizedBox(width: 8), // Um pequeno respiro no canto direito
        ],
      ),

      // --- CORPO DA TELA (BODY) ---
      body: Padding(
        // Adiciona um respiro de 24 pixels de todos os lados da tela
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Estica os elementos para preencher a largura
          children: [
            // Título de boas-vindas
            const Text(
              'Acesso ao Sistema',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CoresDomex.azulPrincipal,
              ),
            ),
            const SizedBox(height: 8), // Espaçamento pequeno
            // Subtítulo explicativo
            const Text(
              'Selecione o módulo que deseja acessar:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(
              height: 40,
            ), // Espaçamento grande antes de começar a lista de botões
            // --- LISTA DE BOTÕES (MÓDULOS) ---
            // Expanded faz a lista ocupar todo o espaço restante disponível na tela
            Expanded(
              child: ListView(
                children: [
                  // 1. Botão da Secretaria
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Secretaria',
                    subtitulo: 'Gestão de alunos, matrículas e relatórios',
                    icone: Icons.admin_panel_settings,
                    cor: CoresDomex.azulPrincipal,
                    aoClicar: () {
                      // Abre a tela principal da Secretaria
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TelaSecretaria(),
                        ),
                      );
                    },
                  ),

                  // ESPAÇAMENTO PADRÃO DE 16 PIXELS ENTRE SECRETARIA E PROFESSOR
                  const SizedBox(height: 16),

                  // 2. Botão do Professor
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Professor',
                    subtitulo: 'Diário de classe, notas e frequências',
                    icone: Icons.school,
                    cor: Colors.teal, // Cor verde-água para diferenciar
                    aoClicar: () {
                      // Tratativa de erro: Se o ID sumir por algum bug, avisa o usuário
                      if (usuarioId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ID do usuário não encontrado. Faça login novamente.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      // Abre o painel do professor passando o ID de quem está logado
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InicioProfessorTela(usuarioId: usuarioId!),
                        ),
                      );
                    },
                  ),

                  // ESPAÇAMENTO PADRÃO DE 16 PIXELS ENTRE PROFESSOR E ALUNO
                  const SizedBox(height: 16),

                  // 3. Botão do Aluno
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Aluno',
                    subtitulo: 'Meu boletim, horários e atividades',
                    icone: Icons.face,
                    cor: CoresDomex.laranjaAcao,
                    aoClicar: () {
                      // Feedback provisório para módulos ainda não desenvolvidos
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Módulo Aluno em desenvolvimento...'),
                        ),
                      );
                    },
                  ),

                  // ESPAÇAMENTO PADRÃO DE 16 PIXELS ENTRE ALUNO E RESPONSÁVEL
                  const SizedBox(height: 16),

                  // 4. Botão do Responsável
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Responsável pelo Aluno',
                    subtitulo: 'Acompanhamento escolar e financeiro',
                    icone: Icons.family_restroom,
                    cor: Colors.purple,
                    aoClicar: () {
                      // Feedback provisório para módulos ainda não desenvolvidos
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Módulo Responsável em desenvolvimento...',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET HELPER: CONSTRUTOR DE BOTÕES DE MÓDULOS
  // Esta função cria o layout "Card" padronizado para todos os botões do menu.
  // Evita a repetição de código (Clean Code).
  // ==========================================
  Widget _construirBotaoPerfil(
    BuildContext context, {
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required VoidCallback aoClicar,
  }) {
    return InkWell(
      onTap: aoClicar, // Função executada ao tocar no botão
      borderRadius: BorderRadius.circular(
        16,
      ), // Deixa o clique com o mesmo arredondamento do botão
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200), // Borda fina e clara
          boxShadow: [
            // Efeito de sombra leve para parecer que o botão flutua na tela
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Círculo colorido que guarda o ícone
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withValues(
                  alpha: 0.1,
                ), // Pega a cor principal e deixa ela 90% transparente
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 32, color: cor),
            ),
            const SizedBox(width: 20), // Espaço entre o ícone e os textos
            // Área dos textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // Setinha no final para indicar que abre uma nova tela
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TELA: MEU PERFIL (Visualização e Edição)
// Permite ao usuário logado ver seus dados e alterar Senha/Telefone/Foto
// ==========================================
class TelaPerfil extends StatefulWidget {
  final String? usuarioId;

  const TelaPerfil({super.key, this.usuarioId});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  // Controladores de Texto - Identificação
  final _nomeCtrl = TextEditingController(); // Apenas leitura
  final _loginCtrl = TextEditingController(); // Apenas leitura
  final _telefoneCtrl = TextEditingController();

  // Controladores de Texto - Endereço
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();

  // Variáveis para Segurança (Alterar Senha)
  final _senhaCtrl = TextEditingController();
  bool _mostrarSenha = false; // Alterna a visualização da senha (olhinho)
  bool _editandoSenha =
      false; // Controla se o campo de senha está liberado para escrita

  // Máscara para garantir que o número fique formatado como (XX) XXXXX-XXXX
  final _mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Variáveis de Imagem
  final ImagePicker _selecionadorImagem = ImagePicker();
  Uint8List? _imagemBytes; // Imagem nova escolhida pelo usuário
  String? _fotoUrlExistente; // Link da foto antiga que já estava no banco

  bool _carregando = false; // Controla o loading de abertura da tela
  bool _salvando = false; // Controla o loading do botão de Salvar

  @override
  void initState() {
    super.initState();
    // Ao abrir a tela, se o usuário estiver logado, busca as informações dele
    if (widget.usuarioId != null) {
      _carregarDadosPerfil();
    }
  }

  // ==========================================
  // FUNÇÃO: BUSCAR DADOS DO FIREBASE
  // ==========================================
  Future<void> _carregarDadosPerfil() async {
    setState(() => _carregando = true);
    try {
      // Vai até a coleção "usuarios" e pega o documento do ID logado
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuarioId)
          .get();

      if (doc.exists) {
        final dados = doc.data() as Map<String, dynamic>;

        // Preenche os campos da tela com os dados do banco
        _nomeCtrl.text = dados['nome'] ?? 'Não informado';
        _loginCtrl.text = dados['login'] ?? 'Não informado';
        _telefoneCtrl.text = dados['telefone'] ?? '';
        _senhaCtrl.text = dados['senha'] ?? '';

        final endereco = dados['endereco'] ?? {};
        _ruaCtrl.text = endereco['rua'] ?? '';
        _numeroCtrl.text = endereco['numero'] ?? '';
        _bairroCtrl.text = endereco['bairro'] ?? '';
        _cidadeCtrl.text = endereco['cidade'] ?? '';
        _referenciaCtrl.text = endereco['pontoReferencia'] ?? '';

        setState(() {
          _fotoUrlExistente = dados['fotoUrl'];
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  // ==========================================
  // FUNÇÕES DE MANIPULAÇÃO DE FOTO (COM ENQUADRAMENTO/CROP)
  // ==========================================
  Future<void> _capturarImagem(ImageSource fonte) async {
    try {
      // Abre a câmera ou a galeria
      final XFile? imagem = await _selecionadorImagem.pickImage(
        source: fonte,
        imageQuality: 80,
      );

      if (imagem != null) {
        if (!mounted) return;

        // Chama o plugin de recortar a foto, forçando ela a ficar "quadrada" (1:1)
        CroppedFile? imagemCortada = await ImageCropper().cropImage(
          sourcePath: imagem.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Enquadrar Foto',
              toolbarColor: Colors.blue[900],
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Trava na proporção quadrada
            ),
            IOSUiSettings(
              title: 'Enquadrar Foto',
              aspectRatioLockEnabled: true,
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
            ),
          ],
        );

        if (imagemCortada != null) {
          // Converte a imagem cortada para bytes e avisa a tela para se reconstruir
          final bytes = await imagemCortada.readAsBytes();
          setState(() {
            _imagemBytes = bytes;
            _fotoUrlExistente =
                null; // Limpa a URL antiga, pois há uma foto nova
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  // Modal Inferior (Bottom Sheet) com opções de Câmera ou Galeria
  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Alterar Foto de Perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _capturarImagem(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Tirar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _capturarImagem(ImageSource.camera);
                },
              ),
              // Mostra a opção de apagar apenas se já existir alguma foto configurada
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
                      _fotoUrlExistente = null; // Apaga tudo
                    });
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // FUNÇÃO: SALVAR AS ALTERAÇÕES DO PERFIL
  // ==========================================
  Future<void> _salvarPerfil() async {
    if (widget.usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: ID não encontrado.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => _salvando = true); // Inicia a animação de girar o botão

    try {
      String? linkFotoFinal = _fotoUrlExistente;

      // 1. Se houver imagem nova em memória (_imagemBytes), envia para o Firebase Storage
      if (_imagemBytes != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'fotos_usuarios/${widget.usuarioId}.jpg',
        );
        await storageRef.putData(_imagemBytes!);
        // Recupera o link da internet para salvar no banco
        linkFotoFinal = await storageRef.getDownloadURL();
      }

      // 2. Salva as informações editáveis na coleção "usuarios" (O nome e login não mudam)
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuarioId)
          .update({
            'telefone': _telefoneCtrl.text,
            'senha':
                _senhaCtrl.text, // A senha é atualizada apenas se foi editada
            'fotoUrl': linkFotoFinal,
            'endereco': {
              'rua': _ruaCtrl.text,
              'numero': _numeroCtrl.text,
              'bairro': _bairroCtrl.text,
              'cidade': _cidadeCtrl.text,
              'pontoReferencia': _referenciaCtrl.text,
            },
          });

      // 3. Informa sucesso e volta para a tela inicial
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==========================================
  // INTERFACE DA TELA DE PERFIL
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ÁREA CIRCULAR DA FOTO ---
                  Center(
                    child: Stack(
                      alignment: Alignment
                          .bottomRight, // Coloca o ícone de câmera no canto inferior direito
                      children: [
                        InkWell(
                          onTap: _mostrarOpcoesFoto,
                          borderRadius: BorderRadius.circular(60),
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 3,
                              ),
                              // Mostra a foto recém tirada, ou a do banco, ou vazio
                              image: _imagemBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_imagemBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_fotoUrlExistente != null &&
                                            _fotoUrlExistente!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              _fotoUrlExistente!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                            ),
                            child:
                                _imagemBytes == null &&
                                    (_fotoUrlExistente == null ||
                                        _fotoUrlExistente!.isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.blue,
                                  )
                                : null,
                          ),
                        ),

                        // Ícone da Câmera por cima da foto (Para deixar óbvio que é editável)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // BLOCO 1: DADOS PESSOAIS
                  // ==========================================
                  const Text(
                    'Identificação',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // NOME E LOGIN SÃO PROTEGIDOS (Read Only). O utilizador não pode mudar o próprio nome, só a Secretaria.
                  TextFormField(
                    controller: _nomeCtrl,
                    readOnly: true,
                    style: const TextStyle(
                      color: Colors.black54,
                    ), // Texto mais cinza para indicar bloqueio
                    decoration: InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor:
                          Colors.grey.shade100, // Fundo cinza indica bloqueio
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _loginCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.black54),
                    decoration: InputDecoration(
                      labelText: 'Login de Acesso',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TELEFONE PODE EDITAR
                  TextFormField(
                    controller: _telefoneCtrl,
                    inputFormatters: [_mascaraTelefone],
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone / WhatsApp',
                      prefixIcon: Icon(Icons.phone_android),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // BLOCO 2: ENDEREÇO
                  // ==========================================
                  const Text(
                    'Endereço',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Rua e Número (Na mesma linha usando Row + Expanded)
                  Row(
                    children: [
                      Expanded(
                        flex: 2, // A rua ocupa 2 partes de espaço
                        child: TextFormField(
                          controller: _ruaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Rua',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1, // O número ocupa 1 parte
                        child: TextFormField(
                          controller: _numeroCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nº',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bairro e Cidade (Metade para cada)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bairroCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bairro',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cidadeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ponto de Referência
                  TextFormField(
                    controller: _referenciaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ponto de Referência (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // BLOCO 3: SEGURANÇA E SENHA
                  // ==========================================
                  const Text(
                    'Segurança',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Campo de Senha
                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: !_mostrarSenha, // Esconde os caracteres (***)
                    readOnly:
                        !_editandoSenha, // Fica bloqueado até clicar no botão "Alterar"
                    decoration: InputDecoration(
                      labelText: 'Sua Senha de Acesso',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      filled:
                          !_editandoSenha, // Fundo cinza se não estiver editando
                      fillColor: _editandoSenha
                          ? Colors.white
                          : Colors.grey.shade100,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: _editandoSenha ? Colors.blue : Colors.grey,
                        ),
                        // Mostra e oculta os caracteres da senha
                        onPressed: () =>
                            setState(() => _mostrarSenha = !_mostrarSenha),
                      ),
                    ),
                  ),

                  // Botão "Alterar Senha" (Desaparece depois que é clicado)
                  if (!_editandoSenha) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment
                          .centerRight, // Empurra o botão para a direita
                      child: TextButton.icon(
                        onPressed: () {
                          // Libera a edição e mostra a senha para a pessoa saber o que está digitando
                          setState(() {
                            _editandoSenha = true;
                            _mostrarSenha = true;
                          });
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text(
                          'Alterar Senha',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // ==========================================
                  // BOTÃO DE SALVAR FINAL
                  // ==========================================
                  SizedBox(
                    width: double.infinity, // Ocupa toda a largura
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      // Desabilita o botão se estiver salvando, para evitar cliques duplos
                      onPressed: _salvando ? null : _salvarPerfil,
                      icon: _salvando
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
                ],
              ),
            ),
    );
  }
}
