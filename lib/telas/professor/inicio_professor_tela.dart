import 'package:flutter/material.dart';
import 'package:gestao_escolar/nucleo/cores.dart';
import 'package:gestao_escolar/telas/professor/chamada_tela.dart';

class InicioProfessorTela extends StatelessWidget {
  const InicioProfessorTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Olá, Prof. Silva',
        ), // Futuramente virá do banco de dados
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suas Turmas Hoje',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CoresDomex.textoPrincipal,
              ),
            ),
            const SizedBox(height: 16),

            // Lista de Turmas do Dia
            Card(
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: CoresDomex.azulPrincipal,
                  child: Text('1ºA', style: TextStyle(color: Colors.white)),
                ),
                title: const Text(
                  '1º Ano A - Matemática',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('07:30 às 08:20'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Abre a tela de chamada específica desta turma
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChamadaTela(turmaNome: '1º Ano A'),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CoresDomex.textoPrincipal,
              ),
            ),
            const SizedBox(height: 16),

            // Grid de Ações
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _construirBotao(
                    icone: Icons.fact_check_outlined,
                    titulo: 'Lançar Notas',
                    cor: CoresDomex.laranjaAcao,
                    aoClicar: () {},
                  ),
                  _construirBotao(
                    icone: Icons.calendar_month,
                    titulo: 'Meu Horário',
                    cor: Colors.teal,
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

  Widget _construirBotao({
    required IconData icone,
    required String titulo,
    required Color cor,
    required VoidCallback aoClicar,
  }) {
    return InkWell(
      onTap: aoClicar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 40, color: cor),
            const SizedBox(height: 12),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
