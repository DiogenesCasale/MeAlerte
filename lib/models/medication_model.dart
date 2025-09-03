class Medication {
  final int? id;
  final String nome;
  final int quantidade;
  final String? observacao;
  final String? dataCriacao;

  Medication({
    this.id,
    required this.nome,
    required this.quantidade,
    this.observacao,
    this.dataCriacao,
  });

  // Construtor para ler dados do banco
  static Medication fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      nome: map['nome'],
      quantidade: map['quantidade'],
      observacao: map['observacao'],
      dataCriacao: map['data_criacao'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'quantidade': quantidade,
      'observacao': observacao,
      'data_criacao': dataCriacao ?? DateTime.now().toIso8601String(),
    };
  }

  Medication copyWith({int? id}) {
    return Medication(
      id: id ?? this.id,
      nome: nome,
      quantidade: quantidade,
      observacao: observacao,
      dataCriacao: dataCriacao,
    );
  }
}
