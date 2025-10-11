class Annotation {
  final int? id;
  final int idPerfil;
  final String anotacao;
  final bool deletado;
  final String dataCriacao;
  final String dataAtualizacao;

  Annotation({
    this.id,
    required this.idPerfil,
    required this.anotacao,
    this.deletado = false,
    required this.dataCriacao,
    required this.dataAtualizacao,
  });

  // Converte um objeto Map (vindo do DB) para um objeto Annotation
  static Annotation fromMap(Map<String, dynamic> map) {
    return Annotation(
      id: map['id'],
      idPerfil: map['idPerfil'],
      anotacao: map['anotacao'],
      deletado: (map['deletado'] ?? 0) == 1,
      dataCriacao: map['dataCriacao'],
      dataAtualizacao: map['dataAtualizacao'],
    );
  }

  // Converte um objeto Annotation para um Map (para inserir no DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idPerfil': idPerfil,
      'anotacao': anotacao,
      'deletado': deletado ? 1 : 0,
      'dataCriacao': dataCriacao,
      'dataAtualizacao': dataAtualizacao,
    };
  }
  
  // Getter para facilitar a conversão da data para DateTime
  DateTime get dataCriacaoDateTime => DateTime.parse(dataCriacao);
}