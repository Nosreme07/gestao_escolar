class AlunoModelo {
  // O ID interno do banco de dados (ex: Firebase gera um código gigante e oculto)
  final String? id;

  // A sua ideia: A Matrícula amigável para o login (ex: 2026001)
  final String ra;

  // Dados do Aluno
  final String nome;
  final String dataNascimento;
  final String turma;

  // Dados do Responsável
  final String nomeResponsavel;
  final String cpfResponsavel;
  final String telefoneResponsavel;
  final String?
  emailResponsavel; // A interrogação (?) significa que pode ser nulo/vazio

  // Construtor
  AlunoModelo({
    this.id,
    required this.ra,
    required this.nome,
    required this.dataNascimento,
    required this.turma,
    required this.nomeResponsavel,
    required this.cpfResponsavel,
    required this.telefoneResponsavel,
    this.emailResponsavel,
  });

  // --- LÓGICA DE GERAÇÃO DE RA (MATRÍCULA) ---
  // Esta função simula a criação da matrícula baseada no ano atual e num sequencial
  static String gerarNovaMatricula(int quantidadeAlunosAtuais) {
    final anoAtual = DateTime.now().year; // Pega o ano atual (ex: 2026)

    // O próximo número será a quantidade atual + 1
    final proximoNumero = quantidadeAlunosAtuais + 1;

    // Transforma o número em um formato de 4 dígitos (ex: 1 vira 0001)
    final numeroFormatado = proximoNumero.toString().padLeft(4, '0');

    // Resultado: "20260001"
    return "$anoAtual$numeroFormatado";
  }

  // --- PREPARAÇÃO PARA O BANCO DE DADOS ---
  // Transforma o Aluno em um "Mapa" (JSON) para salvar no Firebase depois
  Map<String, dynamic> toMap() {
    return {
      'ra': ra,
      'nome': nome,
      'dataNascimento': dataNascimento,
      'turma': turma,
      'nomeResponsavel': nomeResponsavel,
      'cpfResponsavel': cpfResponsavel,
      'telefoneResponsavel': telefoneResponsavel,
      'emailResponsavel': emailResponsavel ?? '', // Salva vazio se não tiver
    };
  }
}
