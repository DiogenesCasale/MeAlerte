class Profile {
  final int? id;
  final String nome;
  final String? dataNascimento;
  final String? genero;
  final String? caminhoImagem;
  final bool deletado;
  final String? dataCriacao;
  final String? dataAtualizacao;
  final bool perfilPadrao;
  final String? mensagemCompartilhar;

  Profile({
    this.id,
    required this.nome,
    this.dataNascimento,
    this.genero,
    this.caminhoImagem,
    this.deletado = false,
    this.dataCriacao,
    this.dataAtualizacao,
    this.perfilPadrao = false,
    this.mensagemCompartilhar,
  });

  static Profile fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      nome: map['nome'],
      dataNascimento: map['dataNascimento'],
      genero: map['genero'],
      caminhoImagem: map['caminhoImagem'],
      deletado: (map['deletado'] ?? 0) == 1,
      dataCriacao: map['data_criacao'] ?? map['dataCriacao'],
      dataAtualizacao: map['data_atualizacao'] ?? map['dataAtualizacao'],
      perfilPadrao: (map['perfilPadrao'] ?? 0) == 1,
      mensagemCompartilhar: map['mensagemCompartilhar'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'dataNascimento': dataNascimento,
      'genero': genero,
      'deletado': deletado ? 1 : 0,
      'caminhoImagem': caminhoImagem,
      'dataCriacao': dataCriacao ?? DateTime.now().toIso8601String(),
      'dataAtualizacao': DateTime.now().toIso8601String(),
      'perfilPadrao': perfilPadrao ? 1 : 0,
      'mensagemCompartilhar': mensagemCompartilhar,
    };
  }

  Profile copyWith({
    int? id,
    String? nome,
    String? dataNascimento,
    String? genero,
    String? caminhoImagem,
    bool? deletado,
    String? dataCriacao,
    String? dataAtualizacao,
    bool? perfilPadrao,
    String? mensagemCompartilhar,
  }) {
    return Profile(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      genero: genero ?? this.genero,
      caminhoImagem: caminhoImagem ?? this.caminhoImagem,
      deletado: deletado ?? this.deletado,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      perfilPadrao: perfilPadrao ?? this.perfilPadrao,
      mensagemCompartilhar: mensagemCompartilhar ?? this.mensagemCompartilhar,
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
    return 'Profile(id: $id, nome: $nome, dataNascimento: $dataNascimento, genero: $genero, caminhoImagem: $caminhoImagem, deletado: $deletado, perfilPadrao: $perfilPadrao, mensagemCompartilhar: $mensagemCompartilhar)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Profile &&
        other.id == id &&
        other.nome == nome &&
        other.dataNascimento == dataNascimento &&
        other.genero == genero &&
        other.caminhoImagem == caminhoImagem &&
        other.deletado == deletado &&
        other.perfilPadrao == perfilPadrao &&
        other.mensagemCompartilhar == mensagemCompartilhar;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        dataNascimento.hashCode ^
        genero.hashCode ^
        caminhoImagem.hashCode ^
        deletado.hashCode ^
        perfilPadrao.hashCode ^
        mensagemCompartilhar.hashCode;
  }
}
