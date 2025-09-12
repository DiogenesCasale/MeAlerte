enum MedicationType {
  comprimido('Comprimido', 'comp.'),
  liquido('Líquido', 'ml'),
  injecao('Injeção', 'amp.');

  const MedicationType(this.displayName, this.unit);
  final String displayName;
  final String unit;
}

class Medication {
  final int? id;
  final String nome;
  final int estoque;
  final MedicationType tipo;
  final bool deletado;
  final int idPerfil;
  final String? caminhoImagem;
  final String? observacao;
  final String? dataCriacao;
  final String? dataAtualizacao;

  Medication({
    this.id,
    required this.nome,
    required this.estoque,
    this.tipo = MedicationType.comprimido,
    this.deletado = false,
    required this.idPerfil,
    this.caminhoImagem,
    this.observacao,
    this.dataCriacao,
    this.dataAtualizacao,
  });

  // Construtor para ler dados do banco
  static Medication fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      nome: map['nome'],
      estoque: map['estoque'] ?? map['quantidade'] ?? 0, // Compatibilidade
      tipo: _getMedicationTypeFromString(map['tipo'] ?? 'comprimido'),
      deletado: (map['deletado'] ?? 0) == 1,
      idPerfil: map['idPerfil'],
      caminhoImagem: map['caminhoImagem'],
      observacao: map['observacao'],
      dataCriacao: map['data_criacao'] ?? map['dataCriacao'],
      dataAtualizacao: map['data_atualizacao'] ?? map['dataAtualizacao'],
    );
  }

  static MedicationType _getMedicationTypeFromString(String type) {
    switch (type) {
      case 'liquido':
        return MedicationType.liquido;
      case 'injecao':
        return MedicationType.injecao;
      default:
        return MedicationType.comprimido;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'estoque': estoque,
      'tipo': tipo.name,
      'deletado': deletado ? 1 : 0,
      'idPerfil': idPerfil,
      'caminhoImagem': caminhoImagem,
      'observacao': observacao,
      'dataCriacao': dataCriacao ?? DateTime.now().toIso8601String(),
      'dataAtualizacao': dataAtualizacao ?? DateTime.now().toIso8601String(),
    };
  }

  Medication copyWith({int? id}) {
    return Medication(
      id: id ?? this.id,
      nome: nome,
      estoque: estoque,
      tipo: tipo,
      deletado: deletado,
      idPerfil: idPerfil,
      caminhoImagem: caminhoImagem,
      observacao: observacao,
      dataCriacao: dataCriacao,
      dataAtualizacao: dataAtualizacao,
    );
  }
}
