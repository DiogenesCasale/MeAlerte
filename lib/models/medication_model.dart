class Medication {
  final int? id;
  final String nome;
  final int quantidadeEstoque;
  final String? observacao;

  Medication({
    this.id,
    required this.nome,
    required this.quantidadeEstoque,
    this.observacao,
  });

  // Construtor para ler dados do banco
  static Medication fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      nome: map['nome'],
      quantidadeEstoque: map['quantidade_estoque'],
      observacao: map['observacao'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'quantidade_estoque': quantidadeEstoque,
      'observacao': observacao,
    };
  }

  Medication copyWith({int? id}) {
    return Medication(
      id: id ?? this.id,
      nome: nome,
      quantidadeEstoque: quantidadeEstoque,
      observacao: observacao,
    );
  }
}
