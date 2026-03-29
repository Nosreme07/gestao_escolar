import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

// ==========================================
// ABA 5: LISTAGEM DE USUÁRIOS
// ==========================================
class AbaUsuarios extends StatelessWidget {
  const AbaUsuarios({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar usuários.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum usuário cadastrado.'));
          }

          final usuariosDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usuariosDocs.length,
            itemBuilder: (context, index) {
              final user = usuariosDocs[index].data() as Map<String, dynamic>;
              final docId = usuariosDocs[index].id;

              final nome = user['nome'] ?? 'Sem Nome';
              final perfil = user['perfil'] ?? 'Sem Perfil';
              final login = user['login'] ?? 'Sem Login';
              final alunoVinculado = user['nomeAlunoVinculado'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _corPorPerfil(perfil),
                    child: Icon(_iconePorPerfil(perfil), color: Colors.white),
                  ),
                  title: Text(
                    nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Perfil: $perfil'),
                      if (alunoVinculado.isNotEmpty)
                        Text(
                          'Vinculado a: $alunoVinculado',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Visualizar',
                        onPressed: () {
                          // Abre pop-up simples de visualização
                          _mostrarDetalhesUsuario(context, user);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Editar',
                        onPressed: () {
                          // Abre o modal passando os dados para edição
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) => _ModalCadastroUsuario(
                              usuarioId: docId,
                              usuarioData: user,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Excluir',
                        onPressed: () => _confirmarExclusao(context, docId),
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
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const _ModalCadastroUsuario(),
          );
        },
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Novo Cadastro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _corPorPerfil(String perfil) {
    switch (perfil) {
      case 'Secretaria':
        return Colors.blue;
      case 'Professor':
        return Colors.teal;
      case 'Responsável pelo aluno':
        return Colors.purple;
      case 'Aluno':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _iconePorPerfil(String perfil) {
    switch (perfil) {
      case 'Secretaria':
        return Icons.admin_panel_settings;
      case 'Professor':
        return Icons.school;
      case 'Responsável pelo aluno':
        return Icons.family_restroom;
      case 'Aluno':
        return Icons.face;
      default:
        return Icons.person;
    }
  }

  // ==========================================
  // MODAL DE VISUALIZAÇÃO DO USUÁRIO
  // ==========================================
  void _mostrarDetalhesUsuario(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _iconePorPerfil(user['perfil'] ?? ''),
              color: _corPorPerfil(user['perfil'] ?? ''),
            ),
            const SizedBox(width: 8),
            const Text(
              'Dados do Usuário',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaVisualizacao('Nome', user['nome']),
            _linhaVisualizacao('Perfil', user['perfil']),
            _linhaVisualizacao('Telefone', user['telefone']),
            _linhaVisualizacao('E-mail', user['email']),
            const Divider(),
            _linhaVisualizacao('Login de Acesso', user['login']),
            _linhaVisualizacao(
              'Senha Atual',
              user['senha'],
            ), // Mostra a senha atual (pode ser a padrão ou modificada)
            if (user['nomeAlunoVinculado'] != null &&
                user['nomeAlunoVinculado'] != '') ...[
              const SizedBox(height: 8),
              _linhaVisualizacao('Aluno Vinculado', user['nomeAlunoVinculado']),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  Widget _linhaVisualizacao(String titulo, dynamic valor) {
    final texto = (valor == null || valor.toString().isEmpty)
        ? 'Não informado'
        : valor.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$titulo: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: texto),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
          'Tem certeza que deseja apagar este usuário do sistema?',
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
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(docId)
                  .delete();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MODAL INTELIGENTE DE CADASTRO E EDIÇÃO
// ==========================================
class _ModalCadastroUsuario extends StatefulWidget {
  final String? usuarioId;
  final Map<String, dynamic>? usuarioData;

  const _ModalCadastroUsuario({this.usuarioId, this.usuarioData});

  @override
  State<_ModalCadastroUsuario> createState() => _ModalCadastroUsuarioState();
}

class _ModalCadastroUsuarioState extends State<_ModalCadastroUsuario> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final List<String> _perfis = [
    'Secretaria',
    'Professor',
    'Responsável pelo aluno',
    'Aluno',
  ];
  String? _perfilSelecionado;

  List<Map<String, dynamic>> _alunosDoBanco = [];
  Map<String, dynamic>? _alunoVinculado;

  String _tipoLogin = 'email';
  bool _carregandoAlunos = false;

  bool get _isEdicao => widget.usuarioId != null;

  @override
  void initState() {
    super.initState();
    _buscarAlunosNoBanco().then((_) {
      if (_isEdicao) {
        _carregarDadosEdicao();
      }
    });
  }

  void _carregarDadosEdicao() {
    final dados = widget.usuarioData!;
    _nomeCtrl.text = dados['nome'] ?? '';
    _emailCtrl.text = dados['email'] ?? '';
    _telefoneCtrl.text = dados['telefone'] ?? '';

    setState(() {
      _perfilSelecionado = dados['perfil'];
      // Se ele faz login com algo que é igual ao e-mail, foi e-mail. Senão foi RA.
      _tipoLogin = (dados['login'] == dados['email'] && dados['email'] != '')
          ? 'email'
          : 'ra';

      // Se tinha aluno vinculado, tenta achar na lista que baixamos do banco
      if (dados['idAlunoVinculado'] != null &&
          dados['idAlunoVinculado'] != '') {
        try {
          _alunoVinculado = _alunosDoBanco.firstWhere(
            (aluno) => aluno['id'] == dados['idAlunoVinculado'],
          );
        } catch (e) {
          // Se não achou na lista por algum motivo
        }
      }
    });
  }

  Future<void> _buscarAlunosNoBanco() async {
    setState(() => _carregandoAlunos = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('alunos').get();
      setState(() {
        _alunosDoBanco = snap.docs.map((doc) {
          return {
            'id': doc.id,
            'nomeCompleto': doc.data()['nomeCompleto'] ?? 'Sem nome',
            'ra': doc.data()['ra'] ?? '',
            'dataNascimento': doc.data()['dataNascimento'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Erro ao buscar alunos: $e');
    } finally {
      setState(() => _carregandoAlunos = false);
    }
  }

  String _gerarSenhaPadrao() {
    if (_alunoVinculado != null && _alunoVinculado!['dataNascimento'] != null) {
      String data = _alunoVinculado!['dataNascimento'].toString();
      return data.replaceAll('/', ''); // 22/06/1990 vira 22061990
    }
    return '123456';
  }

  // Função para zerar a senha do usuário em edição
  void _zerarSenha() async {
    String novaSenha = _gerarSenhaPadrao();
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuarioId)
          .update({'senha': novaSenha});
      if (mounted) {
        Navigator.pop(context); // Fecha o modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha zerada para o padrão com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao zerar senha: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
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
                    _isEdicao ? 'Editar Usuário' : 'Novo Usuário',
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

              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
              ),
              const SizedBox(height: 16),

              // E-mail (Agora Opcional, e usa onChanged para atualizar a tela)
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'E-mail (Opcional)',
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) {
                  // Se o tipo de login for e-mail, atualiza a tela enquanto digita
                  if (_tipoLogin == 'email') setState(() {});
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _telefoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefone'),
                inputFormatters: [_mascaraTelefone],
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _perfilSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Perfil de Acesso',
                ),
                items: _perfis
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _perfilSelecionado = val;
                    if (val != 'Responsável pelo aluno' && val != 'Aluno') {
                      _alunoVinculado = null; // Reseta se não for pai/aluno
                      _tipoLogin =
                          'email'; // Força ser e-mail se for secretaria/prof
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              // ====================================================
              // CAMPO DE PESQUISA DE ALUNOS
              // ====================================================
              if (_perfilSelecionado == 'Responsável pelo aluno' ||
                  _perfilSelecionado == 'Aluno') ...[
                const Text(
                  'Vincular ao Aluno:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),

                if (_carregandoAlunos)
                  const LinearProgressIndicator()
                else
                  Autocomplete<Map<String, dynamic>>(
                    // Se estiver editando, tentamos iniciar o campo com o nome do aluno que já estava lá
                    initialValue: TextEditingValue(
                      text: _alunoVinculado?['nomeCompleto'] ?? '',
                    ),
                    displayStringForOption: (aluno) =>
                        '${aluno['nomeCompleto']} (RA: ${aluno['ra']})',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty)
                        return const Iterable<Map<String, dynamic>>.empty();
                      return _alunosDoBanco.where((aluno) {
                        return aluno['nomeCompleto']
                            .toString()
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (alunoSelecionado) {
                      setState(() => _alunoVinculado = alunoSelecionado);
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onEditingComplete: onEditingComplete,
                            decoration: InputDecoration(
                              labelText:
                                  'Digite o nome do aluno para pesquisar...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                  ),
                const SizedBox(height: 24),
              ],

              // ====================================================
              // CONFIGURAÇÃO DE ACESSO E EXIBIÇÃO EM TEMPO REAL
              // ====================================================
              if (_perfilSelecionado != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuração de Acesso',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Só dá opção de RA se tiver aluno vinculado. Secretária/Professor entra com e-mail (ou CPF no futuro).
                      if (_alunoVinculado != null) ...[
                        const Text(
                          'O usuário usará o que para entrar?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Row(
                          children: [
                            Radio(
                              value: 'email',
                              groupValue: _tipoLogin,
                              onChanged: (v) =>
                                  setState(() => _tipoLogin = v.toString()),
                            ),
                            const Expanded(child: Text('E-mail')),
                            Radio(
                              value: 'ra',
                              groupValue: _tipoLogin,
                              onChanged: (v) =>
                                  setState(() => _tipoLogin = v.toString()),
                            ),
                            const Expanded(child: Text('Matrícula (RA)')),
                          ],
                        ),
                        const Divider(),
                      ],

                      // EXIBIÇÃO DINÂMICA DO LOGIN
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Login de Acesso: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              // Lógica de exibição:
                              text: _tipoLogin == 'email'
                                  ? (_emailCtrl.text.isEmpty
                                        ? '(Digite um e-mail acima)'
                                        : _emailCtrl.text)
                                  : (_alunoVinculado?['ra'] ??
                                        '(Selecione o aluno)'),
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // SENHA PADRÃO
                      if (!_isEdicao) ...[
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Senha Provisória: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: _gerarSenhaPadrao(),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_alunoVinculado != null)
                          const Text(
                            '*A senha padrão é a data de nascimento do aluno sem as barras.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],

                      // BOTÃO ZERAR SENHA (SÓ NA EDIÇÃO)
                      if (_isEdicao) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _zerarSenha,
                          icon: const Icon(Icons.lock_reset, color: Colors.red),
                          label: const Text(
                            'Zerar Senha para Padrão',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _salvarUsuario,
                  child: Text(
                    _isEdicao ? 'ATUALIZAR USUÁRIO' : 'SALVAR NOVO USUÁRIO',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _salvarUsuario() async {
    if (_nomeCtrl.text.isEmpty || _perfilSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o Nome e o Perfil!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tipoLogin == 'email' && _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você escolheu login por E-mail, então o E-mail não pode ficar vazio!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((_perfilSelecionado == 'Responsável pelo aluno' ||
            _perfilSelecionado == 'Aluno') &&
        _alunoVinculado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você deve pesquisar e selecionar um aluno!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Define qual será o login salvo no banco
    String loginFinal = _emailCtrl.text;
    if (_tipoLogin == 'ra' && _alunoVinculado != null) {
      loginFinal = _alunoVinculado!['ra'];
    }

    Map<String, dynamic> dadosUsuario = {
      'nome': _nomeCtrl.text,
      'email': _emailCtrl.text, // Email salvo mesmo que não seja o login
      'telefone': _telefoneCtrl.text,
      'perfil': _perfilSelecionado,
      'login': loginFinal,
      'idAlunoVinculado': _alunoVinculado?['id'] ?? '',
      'nomeAlunoVinculado': _alunoVinculado?['nomeCompleto'] ?? '',
    };

    try {
      if (_isEdicao) {
        // Na edição, não sobrescrevemos a senha se já existe, só os dados
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.usuarioId)
            .update(dadosUsuario);
      } else {
        // No cadastro novo, salvamos a senha gerada
        dadosUsuario['senha'] = _gerarSenhaPadrao();
        dadosUsuario['dataCriacao'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('usuarios')
            .add(dadosUsuario);
      }

      if (mounted) {
        Navigator.pop(context); // Fecha o modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
    }
  }
}
