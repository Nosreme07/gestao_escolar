import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Altere os imports abaixo para o caminho correto do seu projeto
import 'package:gestao_escolar/nucleo/cores.dart';
import 'package:gestao_escolar/telas/tela_principal.dart'; // Tela onde ficam as 4 pastas/módulos
// Se já tiver a tela do professor criada, deixe o import. Se der erro, comente.
import 'package:gestao_escolar/telas/professor/inicio_professor_tela.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _estaCarregando = false;
  bool _mostrarSenha = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área do Logo (Simbolizada pelo Ícone)
              const Icon(
                Icons.school_outlined,
                size: 90,
                color: CoresDomex.azulPrincipal,
              ),
              const SizedBox(height: 10),

              const Text(
                "GESTAO_ESCOLAR",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: CoresDomex.azulPrincipal,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Sua escola conectada.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 50),

              // CAMPO DE LOGIN (Email ou RA)
              TextField(
                controller: _loginController,
                decoration: const InputDecoration(
                  labelText: "E-mail ou Matrícula (RA)",
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // CAMPO DE SENHA
              TextField(
                controller: _senhaController,
                obscureText: !_mostrarSenha,
                decoration: InputDecoration(
                  labelText: "Sua Senha",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarSenha ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarSenha = !_mostrarSenha;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // BOTÃO ENTRAR
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _estaCarregando
                      ? null
                      : () => _fazerLoginNoFirebase(context),
                  child: _estaCarregando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "ENTRAR",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const Spacer(),

              const Text(
                "Plataforma desenvolvida por Domex Tech",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LÓGICA REAL DE LOGIN NO FIREBASE
  // ==========================================
  Future<void> _fazerLoginNoFirebase(BuildContext context) async {
    final String loginDigitado = _loginController.text.trim();
    final String senhaDigitada = _senhaController.text.trim();

    if (loginDigitado.isEmpty || senhaDigitada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o Login e a Senha!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _estaCarregando = true);

    try {
      // 1. Vai no Firestore e busca na coleção 'usuarios' se existe alguém com aquele 'login' exato
      final QuerySnapshot resultado = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('login', isEqualTo: loginDigitado)
          .limit(1)
          .get();

      // 2. Se a lista de resultados for vazia, o login não existe
      if (resultado.docs.isEmpty) {
        setState(() => _estaCarregando = false);
        _mostrarErro('Usuário não encontrado. Verifique seu E-mail ou RA.');
        return;
      }

      // 3. Pegamos os dados do usuário encontrado e o ID DELE NO BANCO
      final docId = resultado.docs.first.id; // <--- SEGREDO ESTÁ AQUI
      final dadosUsuario = resultado.docs.first.data() as Map<String, dynamic>;

      final String senhaCorreta = dadosUsuario['senha'] ?? '';
      final String perfil = dadosUsuario['perfil'] ?? '';
      final String nome = dadosUsuario['nome'] ?? '';

      // 4. Verificamos se a senha digitada bate com a que está salva lá
      if (senhaDigitada != senhaCorreta) {
        setState(() => _estaCarregando = false);
        _mostrarErro('Senha incorreta! Tente novamente.');
        return;
      }

      // LOGIN APROVADO! Redirecionamento por perfil
      setState(() => _estaCarregando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bem-vindo(a), $nome!'),
          backgroundColor: Colors.green,
        ),
      );

      // Passamos o perfil e o ID único do usuário logado
      _redirecionarPorPerfil(context, perfil, docId);
    } catch (e) {
      setState(() => _estaCarregando = false);
      _mostrarErro('Erro de conexão: $e');
    }
  }

  void _mostrarErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
      );
    }
  }

  // Recebe o ID e envia para a Tela Principal
  void _redirecionarPorPerfil(
    BuildContext context,
    String perfil,
    String docId,
  ) {
    switch (perfil) {
      case 'Secretaria':
      case 'Diretor':
        Navigator.pushReplacement(
          context,
          // AQUI: Enviando o ID para a TelaPrincipal para o botão "Perfil" puxar os dados certos
          MaterialPageRoute(builder: (_) => TelaPrincipal(usuarioId: docId)),
        );
        break;

      case 'Professor':
        // Quando for para a tela do professor, lembre de passar o ID assim:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InicioProfessorTela(usuarioId: docId),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navegando para o painel do Professor...'),
          ),
        );
        break;

      case 'Aluno':
      case 'Responsável pelo aluno':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navegando para o painel do $perfil...')),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil não reconhecido pelo sistema.')),
        );
    }
  }
}
