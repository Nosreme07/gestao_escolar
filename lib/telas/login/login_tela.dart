import 'package:flutter/material.dart';
// Altere 'gestao_escolar' para o nome exato do seu projeto no pubspec.yaml
import 'package:gestao_escolar/nucleo/cores.dart';
import 'package:gestao_escolar/telas/professor/inicio_professor_tela.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // Para esta fase de desenvolvimento, vamos usar um Dropdown para simular os perfis
  String _perfilSelecionado = 'Secretária';
  final List<String> _perfis = [
    'Secretária',
    'Diretor',
    'Professor',
    'Responsável',
    'Aluno',
  ];

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
                "GESTAO_ESCOLAR", // Nome temporário conforme sua pasta
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
                style: TextStyle(color: CoresDomex.textoSecundario),
              ),

              const SizedBox(height: 50),

              // Campo E-mail
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "E-mail ou Matrícula (RA)",
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Senha
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Sua Senha",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Dropdown para Simulação de Perfil (Crucial para o fluxo que você quer)
              DropdownButtonFormField<String>(
                value: _perfilSelecionado,
                decoration: const InputDecoration(
                  labelText: "Entrar como:",
                  prefixIcon: Icon(Icons.person_pin_outlined),
                ),
                items: _perfis.map((String perfil) {
                  return DropdownMenuItem(value: perfil, child: Text(perfil));
                }).toList(),
                onChanged: (String? novoPerfil) {
                  setState(() {
                    _perfilSelecionado = novoPerfil!;
                  });
                },
              ),

              const SizedBox(height: 30),

              // Botão Entrar
              ElevatedButton(
                onPressed: () {
                  // Aqui simularemos o fluxo de login
                  _simularAcessoAoPainel(context, _perfilSelecionado);
                },
                child: const Text(
                  "ENTRAR",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),

              const Spacer(),

              const Text(
                "Plataforma desenvolvida por Domex Tech",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CoresDomex.textoSecundario,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _simularAcessoAoPainel(BuildContext context, String perfil) {
    // Esta lógica simula o redirecionamento para as pastas que você criou
    switch (perfil) {
      case 'Secretária':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bem-vinda, Secretaria! Indo para o Cadastro de Alunos...',
            ),
          ),
        );
        // Descomente quando criar a tela na pasta painel_secretaria
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InicioSecretariaTela()));
        break;
      case 'Professor':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InicioProfessorTela()),
        );
        break;
        ;
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login como $perfil (Painel em desenvolvimento)'),
          ),
        );
    }
  }
}
