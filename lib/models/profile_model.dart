class Profile {
  final int? id;
  final String nome;
  final String? dataNascimento;
  final String? genero;
  final double? peso;
  final String? caminhoImagem;
  final bool deletado;
  final String? dataCriacao;
  final String? dataAtualizacao;

  Profile({
    this.id,
    required this.nome,
    this.dataNascimento,
    this.genero,
    this.peso,
    this.caminhoImagem,
    this.deletado = false,
    this.dataCriacao,
    this.dataAtualizacao,
  });

  static Profile fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      nome: map['nome'],
      dataNascimento: map['dataNascimento'],
      genero: map['genero'],
      peso: map['peso']?.toDouble(),
      caminhoImagem: map['caminhoImagem'],
      deletado: (map['deletado'] ?? 0) == 1,
      dataCriacao: map['data_criacao'] ?? map['dataCriacao'],
      dataAtualizacao: map['data_atualizacao'] ?? map['dataAtualizacao'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'dataNascimento': dataNascimento,
      'genero': genero,
      'peso': peso,
      'deletado': deletado ? 1 : 0,
      'caminhoImagem': caminhoImagem,
      'dataCriacao': dataCriacao ?? DateTime.now().toIso8601String(),
      'dataAtualizacao': DateTime.now().toIso8601String(),
    };
  }

  Profile copyWith({
    int? id,
    String? nome,
    String? dataNascimento,
    String? genero,
    double? peso,
    String? caminhoImagem,
    bool? deletado,
    String? dataCriacao,
    String? dataAtualizacao,
  }) {
    return Profile(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      genero: genero ?? this.genero,
      peso: peso ?? this.peso,
      caminhoImagem: caminhoImagem ?? this.caminhoImagem,
      deletado: deletado ?? this.deletado,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }

  // Verifica se o perfil tem uma imagem válida
  bool get hasImage => caminhoImagem != null && caminhoImagem!.isNotEmpty;

  // Retorna a idade baseada na data de nascimento
  int? get idade {
    if (dataNascimento == null) return null;
    try {
      final nascimento = DateTime.parse(dataNascimento!);
      final hoje = DateTime.now();
      int idade = hoje.year - nascimento.year;
      if (hoje.month < nascimento.month || 
          (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
        idade--;
      }
      return idade;
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'Profile(id: $id, nome: $nome, dataNascimento: $dataNascimento, genero: $genero, peso: $peso, caminhoImagem: $caminhoImagem, deletado: $deletado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
