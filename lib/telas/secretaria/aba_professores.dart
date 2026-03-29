import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

// ==========================================
// ABA 4: LISTAGEM DE PROFESSORES
// ==========================================
class AbaProfessores extends StatelessWidget {
  const AbaProfessores({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('professores')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar dados.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum professor cadastrado.'));
          }

          final professoresDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: professoresDocs.length,
            itemBuilder: (context, index) {
              final profData =
                  professoresDocs[index].data() as Map<String, dynamic>;
              final docId = professoresDocs[index].id;

              final nome = profData['nome'] ?? 'Sem Nome';
              final disciplina = profData['disciplina'] ?? 'Não informada';
              final fotoUrl = profData['fotoUrl'] as String?;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: fotoUrl != null && fotoUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(fotoUrl),
                          radius: 25,
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          radius: 25,
                          child: const Icon(Icons.school, color: Colors.teal),
                        ),
                  title: Text(
                    nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Disciplina: $disciplina'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Visualizar',
                        onPressed: () =>
                            _mostrarDetalhesProfessor(context, profData),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Editar',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) => _ModalCadastroProfessor(
                              profId: docId,
                              profData: profData,
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
            builder: (_) => const _ModalCadastroProfessor(),
          );
        },
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo Professor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja apagar este professor?'),
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
                  .collection('professores')
                  .doc(docId)
                  .delete();
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Professor apagado!')),
                );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL DE VISUALIZAÇÃO DO PROFESSOR
  // ==========================================
  void _mostrarDetalhesProfessor(
    BuildContext context,
    Map<String, dynamic> prof,
  ) {
    final fotoUrl = prof['fotoUrl'] as String?;
    final contatoRaw = prof['contato']?.toString() ?? '';
    final contatoLimpo = contatoRaw.replaceAll(RegExp(r'[^0-9]'), '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Perfil do Professor',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: fotoUrl != null && fotoUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(fotoUrl),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal.shade50,
                      child: const Icon(
                        Icons.school,
                        size: 50,
                        color: Colors.teal,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              prof['nome'] ?? 'Sem Nome',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              prof['disciplina'] ?? 'Disciplina não informada',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 30),

            _linhaVisualizacao(Icons.email, 'E-mail', prof['email']),
            _linhaVisualizacao(Icons.location_on, 'Endereço', prof['endereco']),

            const SizedBox(height: 16),
            if (contatoLimpo.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () async {
                      final Uri url = Uri.parse('tel:$contatoLimpo');
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    icon: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Ligar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      final Uri url = Uri.parse(
                        'https://wa.me/55$contatoLimpo',
                      );
                      if (await canLaunchUrl(url))
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                    },
                    icon: const Icon(
                      Icons.message,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Nenhum contacto telefónico registado.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
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

  Widget _linhaVisualizacao(IconData icone, String titulo, dynamic valor) {
    final texto = (valor == null || valor.toString().isEmpty)
        ? 'Não informado'
        : valor.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
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
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MODAL DE CADASTRO E EDIÇÃO DO PROFESSOR
// ==========================================
class _ModalCadastroProfessor extends StatefulWidget {
  final String? profId;
  final Map<String, dynamic>? profData;

  const _ModalCadastroProfessor({this.profId, this.profData});

  @override
  State<_ModalCadastroProfessor> createState() =>
      _ModalCadastroProfessorState();
}

class _ModalCadastroProfessorState extends State<_ModalCadastroProfessor> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contatoCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _disciplinaCtrl = TextEditingController();

  final _mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final ImagePicker _selecionadorImagem = ImagePicker();
  Uint8List? _imagemBytes;
  String? _fotoUrlExistente;
  bool _estaSalvando = false;

  bool get _isEdicao => widget.profId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) _carregarDadosEdicao();
  }

  void _carregarDadosEdicao() {
    final dados = widget.profData!;
    _nomeCtrl.text = dados['nome'] ?? '';
    _emailCtrl.text = dados['email'] ?? '';
    _contatoCtrl.text = dados['contato'] ?? '';
    _enderecoCtrl.text = dados['endereco'] ?? '';
    _disciplinaCtrl.text = dados['disciplina'] ?? '';

    setState(() {
      _fotoUrlExistente = dados['fotoUrl'];
    });
  }

  // ==========================================
  // FUNÇÕES DE FOTO
  // ==========================================
  Future<void> _capturarImagem(ImageSource fonte) async {
    try {
      final XFile? imagem = await _selecionadorImagem.pickImage(
        source: fonte,
        imageQuality: 70,
      );
      if (imagem != null) {
        final bytes = await imagem.readAsBytes();
        setState(() {
          _imagemBytes = bytes;
          _fotoUrlExistente = null;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao anexar foto: $e')));
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
                  'Anexar Foto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _capturarImagem(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar Foto (Câmera)'),
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
                    _isEdicao ? 'Editar Professor' : 'Novo Professor',
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
              const Divider(height: 16),

              // ÁREA DA FOTO
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
                              Icon(
                                Icons.add_a_photo,
                                color: Colors.grey,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Anexar Foto\n(Toque aqui)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contatoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contato (Telefone/WhatsApp)',
                ),
                inputFormatters: [_mascaraTelefone],
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _enderecoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Endereço Completo',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _disciplinaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Disciplina (Ex: Matemática, Inglês)',
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                  ),
                  onPressed: _estaSalvando ? null : _salvarProfessor,
                  child: _estaSalvando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEdicao
                              ? 'ATUALIZAR PROFESSOR'
                              : 'SALVAR PROFESSOR',
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

  void _salvarProfessor() async {
    if (_nomeCtrl.text.isEmpty || _disciplinaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha pelo menos o Nome e a Disciplina!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _estaSalvando = true);

    try {
      String docId =
          widget.profId ??
          FirebaseFirestore.instance.collection('professores').doc().id;
      String? linkFotoFinal = _fotoUrlExistente;

      // Se anexou foto nova, faz upload para o Storage
      if (_imagemBytes != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'fotos_professores/$docId.jpg',
        );
        await storageRef.putData(_imagemBytes!);
        linkFotoFinal = await storageRef.getDownloadURL();
      }

      Map<String, dynamic> dadosProf = {
        'nome': _nomeCtrl.text,
        'email': _emailCtrl.text,
        'contato': _contatoCtrl.text,
        'endereco': _enderecoCtrl.text,
        'disciplina': _disciplinaCtrl.text,
        'fotoUrl': linkFotoFinal,
      };

      if (_isEdicao) {
        await FirebaseFirestore.instance
            .collection('professores')
            .doc(docId)
            .update(dadosProf);
      } else {
        dadosProf['dataCadastro'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('professores')
            .doc(docId)
            .set(dadosProf);
      }

      if (mounted) {
        Navigator.pop(context); // Fecha o modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Professor salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _estaSalvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
