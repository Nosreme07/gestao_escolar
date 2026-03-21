import 'package:flutter/material.dart';
import 'package:gestao_escolar/nucleo/cores.dart';

class ChamadaTela extends StatefulWidget {
  final String turmaNome;

  const ChamadaTela({super.key, required this.turmaNome});

  @override
  State<ChamadaTela> createState() => _ChamadaTelaState();
}

class _ChamadaTelaState extends State<ChamadaTela> {
  // Lista simulada de alunos do banco de dados
  final List<Map<String, dynamic>> _alunos = [
    {'ra': '2026001', 'nome': 'Ana Clara Souza', 'status': 'P'},
    {'ra': '2026002', 'nome': 'Bruno Mendes', 'status': 'P'},
    {'ra': '2026003', 'nome': 'Carlos Eduardo', 'status': 'P'},
    {'ra': '2026004', 'nome': 'Daniela Ferreira', 'status': 'P'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chamada: ${widget.turmaNome}'),
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data: Hoje',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'P = Presente | F = Falta',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Lista de Alunos
          Expanded(
            child: ListView.separated(
              itemCount: _alunos.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final aluno = _alunos[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Text(
                      aluno['nome'][0],
                      style: const TextStyle(color: CoresDomex.textoPrincipal),
                    ),
                  ),
                  title: Text(
                    aluno['nome'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('RA: ${aluno['ra']}'),

                  // Botões de Presença/Falta (Segmented Control Simples)
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _botaoStatus(index, 'P', Colors.green),
                      const SizedBox(width: 8),
                      _botaoStatus(index, 'F', Colors.red),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Botão Flutuante para Salvar a Chamada
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CoresDomex.azulPrincipal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save),
        label: const Text('Salvar Chamada'),
        onPressed: () {
          // Aqui os dados são enviados para o servidor
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Chamada salva com sucesso! O painel dos pais foi atualizado.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Volta para a tela anterior
        },
      ),
    );
  }

  // Lógica visual dos botões P e F
  Widget _botaoStatus(int index, String status, Color corAtiva) {
    bool isSelecionado = _alunos[index]['status'] == status;

    return InkWell(
      onTap: () {
        setState(() {
          _alunos[index]['status'] = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelecionado ? corAtiva : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isSelecionado ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
