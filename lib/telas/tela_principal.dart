import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:gestao_escolar/nucleo/cores.dart';
import 'package:gestao_escolar/telas/secretaria/tela_secretaria.dart';

// ==========================================
// TELA PRINCIPAL (DASHBOARD/MENU)
// ==========================================
class TelaPrincipal extends StatelessWidget {
  final String? usuarioId; // ID do usuário logado (vindo da tela de Login)

  const TelaPrincipal({super.key, this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domex Tech'),
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Acesso ao Sistema',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CoresDomex.azulPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione o módulo que deseja acessar:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView(
                children: [
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Secretaria',
                    subtitulo: 'Gestão de alunos, matrículas e relatórios',
                    icone: Icons.admin_panel_settings,
                    cor: CoresDomex.azulPrincipal,
                    aoClicar: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TelaSecretaria(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Professor',
                    subtitulo: 'Diário de classe, notas e frequências',
                    icone: Icons.school,
                    cor: Colors.teal,
                    aoClicar: () {},
                  ),
                  const SizedBox(height: 16),
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Aluno',
                    subtitulo: 'Meu boletim, horários e atividades',
                    icone: Icons.face,
                    cor: CoresDomex.laranjaAcao,
                    aoClicar: () {},
                  ),
                  const SizedBox(height: 16),
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Responsável pelo Aluno',
                    subtitulo: 'Acompanhamento escolar e financeiro',
                    icone: Icons.family_restroom,
                    cor: Colors.purple,
                    aoClicar: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBotaoPerfil(
    BuildContext context, {
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required VoidCallback aoClicar,
  }) {
    return InkWell(
      onTap: aoClicar,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 32, color: cor),
            ),
            const SizedBox(width: 20),
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
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TELA: MEU PERFIL (Edição de Dados e Senha)
// ==========================================
class TelaPerfil extends StatefulWidget {
  final String? usuarioId;

  const TelaPerfil({super.key, this.usuarioId});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  // Controladores Dados Básicos
  final _nomeCtrl = TextEditingController(); // Apenas visualização
  final _loginCtrl = TextEditingController(); // Apenas visualização
  final _telefoneCtrl = TextEditingController();

  // Controladores Endereço
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();

  // Segurança
  final _senhaCtrl = TextEditingController();
  bool _mostrarSenha = false;
  bool _editandoSenha = false; // Controla se o campo de senha está desbloqueado

  final _mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final ImagePicker _selecionadorImagem = ImagePicker();
  Uint8List? _imagemBytes;
  String? _fotoUrlExistente;

  bool _carregando = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.usuarioId != null) {
      _carregarDadosPerfil();
    }
  }

  Future<void> _carregarDadosPerfil() async {
    setState(() => _carregando = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuarioId)
          .get();

      if (doc.exists) {
        final dados = doc.data() as Map<String, dynamic>;

        // Dados Pessoais
        _nomeCtrl.text = dados['nome'] ?? 'Não informado';
        _loginCtrl.text = dados['login'] ?? 'Não informado';
        _telefoneCtrl.text = dados['telefone'] ?? '';
        _senhaCtrl.text = dados['senha'] ?? '';

        // Endereço
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

  // Função de Foto com Crop Integrado
  Future<void> _capturarImagem(ImageSource fonte) async {
    try {
      final XFile? imagem = await _selecionadorImagem.pickImage(
        source: fonte,
        imageQuality: 80,
      );

      if (imagem != null) {
        if (!mounted) return;

        CroppedFile? imagemCortada = await ImageCropper().cropImage(
          sourcePath: imagem.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Enquadrar Foto',
              toolbarColor: Colors.blue[900],
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
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
          final bytes = await imagemCortada.readAsBytes();
          setState(() {
            _imagemBytes = bytes;
            _fotoUrlExistente = null;
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
        );
      },
    );
  }

  Future<void> _salvarPerfil() async {
    if (widget.usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Modo de Teste: Suas alterações visuais funcionaram! (Falta linkar o ID do Login)',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => _salvando = true);

    try {
      String? linkFotoFinal = _fotoUrlExistente;

      if (_imagemBytes != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'fotos_usuarios/${widget.usuarioId}.jpg',
        );
        await storageRef.putData(_imagemBytes!);
        linkFotoFinal = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuarioId)
          .update({
            // Nome não é atualizado, apenas contato, senha e foto
            'telefone': _telefoneCtrl.text,
            'senha': _senhaCtrl.text,
            'fotoUrl': linkFotoFinal,
            'endereco': {
              'rua': _ruaCtrl.text,
              'numero': _numeroCtrl.text,
              'bairro': _bairroCtrl.text,
              'cidade': _cidadeCtrl.text,
              'pontoReferencia': _referenciaCtrl.text,
            },
          });

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
                  // ÁREA DA FOTO
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
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
                  // 1. DADOS PESSOAIS
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

                  // Nome Completo (Apenas visualização, bloqueado)
                  TextFormField(
                    controller: _nomeCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.black54),
                    decoration: InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login (Apenas visualização, bloqueado)
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
                  // 2. ENDEREÇO
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

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
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
                        flex: 1,
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

                  TextFormField(
                    controller: _referenciaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ponto de Referência (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // 3. SEGURANÇA E SENHA
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

                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: !_mostrarSenha,
                    readOnly:
                        !_editandoSenha, // Fica bloqueado até clicar em Alterar
                    decoration: InputDecoration(
                      labelText: 'Sua Senha de Acesso',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      filled: !_editandoSenha,
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
                        onPressed: () =>
                            setState(() => _mostrarSenha = !_mostrarSenha),
                      ),
                    ),
                  ),

                  // Botão de Alterar Senha (some quando clicado)
                  if (!_editandoSenha) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _editandoSenha = true;
                            _mostrarSenha =
                                true; // Revela para a pessoa ver o que está digitando
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

                  // BOTÃO SALVAR
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
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
