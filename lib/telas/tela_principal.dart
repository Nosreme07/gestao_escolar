import 'package:flutter/material.dart';
import 'package:gestao_escolar/nucleo/cores.dart';
import 'package:gestao_escolar/telas/secretaria/gerenciamento_alunos.dart';

// Importações prontas para as suas novas pastas!
// Descomente essas linhas conforme for criando os arquivos dentro de cada pasta.
// import 'package:gestao_escolar/telas/painel_secretaria/inicio_secretaria_tela.dart';
// import 'package:gestao_escolar/telas/painel_professor/inicio_professor_tela.dart';
// import 'package:gestao_escolar/telas/painel_aluno/inicio_aluno_tela.dart';
// import 'package:gestao_escolar/telas/painel_responsavel/inicio_responsavel_tela.dart';

class TelaPrincipal extends StatelessWidget {
  const TelaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domex Tech'),
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // O BOTÃO DE PERFIL QUE VOCÊ PEDIU
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            tooltip: 'Meu Perfil',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abrindo configurações de Perfil...'),
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

            // LISTA DOS 4 MÓDULOS (PASTAS)
            Expanded(
              child: ListView(
                children: [
                  // 1. MÓDULO SECRETARIA
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Secretaria',
                    subtitulo: 'Gestão de alunos, matrículas e relatórios',
                    icone: Icons.admin_panel_settings,
                    cor: CoresDomex.azulPrincipal,
                    aoClicar: () {
                      // Removemos o SnackBar e colocamos a navegação real!
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GerenciamentoAlunosTela(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. MÓDULO PROFESSOR
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Professor',
                    subtitulo: 'Diário de classe, notas e frequências',
                    icone: Icons.school,
                    cor: Colors.teal,
                    aoClicar: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => const InicioProfessorTela()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Navegando para o Painel do Professor...',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. MÓDULO ALUNO
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Aluno',
                    subtitulo: 'Meu boletim, horários e atividades',
                    icone: Icons.face,
                    cor: CoresDomex.laranjaAcao,
                    aoClicar: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => const InicioAlunoTela()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navegando para o Painel do Aluno...'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. MÓDULO RESPONSÁVEL
                  _construirBotaoPerfil(
                    context,
                    titulo: 'Responsável pelo Aluno',
                    subtitulo: 'Acompanhamento escolar e financeiro',
                    icone: Icons.family_restroom,
                    cor: Colors.purple,
                    aoClicar: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => const InicioResponsavelTela()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Navegando para o Painel do Responsável...',
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

  // Widget reutilizável para deixar os 4 botões com um visual padrão, limpo e elegante
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
              color: Colors.black.withOpacity(0.05),
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
                color: cor.withOpacity(0.1),
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
