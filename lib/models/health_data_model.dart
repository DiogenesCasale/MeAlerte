class HealthData {
  final int? id;
  final int idPerfil;
  final String tipo;
  final double? valor;
  final double? valorSistolica;
  final double? valorDiastolica;
  final String? unidade;
  final String? observacao;
  final String dataRegistro;
  final bool deletado;
  final String? dataCriacao;
  final String? dataAtualizacao;

  HealthData({
    this.id,
    required this.idPerfil,
    required this.tipo,
    this.valor,
    this.valorSistolica,
    this.valorDiastolica,
    this.unidade,
    this.observacao,
    required this.dataRegistro,
    this.deletado = false,
    this.dataCriacao,
    this.dataAtualizacao,
  });

  static HealthData fromMap(Map<String, dynamic> map) {
    return HealthData(
      id: map['id'],
      idPerfil: map['idPerfil'],
      tipo: map['tipo'],
      valor: map['valor']?.toDouble(),
      valorSistolica: map['valorSistolica']?.toDouble(),
      valorDiastolica: map['valorDiastolica']?.toDouble(),
      unidade: map['unidade'],
      observacao: map['observacao'],
      dataRegistro: map['dataRegistro'],
      deletado: (map['deletado'] ?? 0) == 1,
      dataCriacao: map['dataCriacao'],
      dataAtualizacao: map['dataAtualizacao'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idPerfil': idPerfil,
      'tipo': tipo,
      'valor': valor,
      'valorSistolica': valorSistolica,
      'valorDiastolica': valorDiastolica,
      'unidade': unidade,
      'observacao': observacao,
      'dataRegistro': dataRegistro,
      'deletado': deletado ? 1 : 0,
      'dataCriacao': dataCriacao ?? DateTime.now().toIso8601String(),
      'dataAtualizacao': DateTime.now().toIso8601String(),
    };
  }

  HealthData copyWith({
    int? id,
    int? idPerfil,
    String? tipo,
    double? valor,
    double? valorSistolica,
    double? valorDiastolica,
    String? unidade,
    String? observacao,
    String? dataRegistro,
    bool? deletado,
    String? dataCriacao,
    String? dataAtualizacao,
  }) {
    return HealthData(
      id: id ?? this.id,
      idPerfil: idPerfil ?? this.idPerfil,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      valorSistolica: valorSistolica ?? this.valorSistolica,
      valorDiastolica: valorDiastolica ?? this.valorDiastolica,
      unidade: unidade ?? this.unidade,
      observacao: observacao ?? this.observacao,
      dataRegistro: dataRegistro ?? this.dataRegistro,
      deletado: deletado ?? this.deletado,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }

  // Getter para formatar valores de pressão arterial
  String get pressaoArterialFormatada {
    if (valorSistolica != null && valorDiastolica != null) {
      return '${valorSistolica!.toInt()}/${valorDiastolica!.toInt()} mmHg';
    }
    return '';
  }

  // Getter para formatar valores simples
  String get valorFormatado {
    if (valor != null) {
      if (unidade != null) {
        return '${valor!.toStringAsFixed(valor! % 1 == 0 ? 0 : 1)} $unidade';
      }
      return valor!.toStringAsFixed(valor! % 1 == 0 ? 0 : 1);
    }
    return '';
  }

  // Getter para data formatada
  DateTime get dataRegistroDateTime {
    return DateTime.parse(dataRegistro);
  }

  @override
  String toString() {
    return 'HealthData(id: $id, idPerfil: $idPerfil, tipo: $tipo, valor: $valor, valorSistolica: $valorSistolica, valorDiastolica: $valorDiastolica, unidade: $unidade, dataRegistro: $dataRegistro)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum para tipos de dados de saúde
enum HealthDataType {
  peso('Peso', 'kg'),
  altura('Altura', 'cm'),
  glicose('Glicose', 'mg/dL'),
  pressaoArterial('Pressão Arterial', 'mmHg'),
  frequenciaCardiaca('Frequência Cardíaca', 'bpm'),
  temperatura('Temperatura', '°C'),
  saturacaoOxigenio('Saturação de Oxigênio', '%'),
  colesterolTotal('Colesterol Total', 'mg/dL'),
  colesterolHDL('Colesterol HDL', 'mg/dL'),
  colesterolLDL('Colesterol LDL', 'mg/dL'),
  triglicerideos('Triglicerídeos', 'mg/dL'),
  hemoglobinaGlicada('Hemoglobina Glicada', '%');

  const HealthDataType(this.label, this.unidade);
  final String label;
  final String unidade;

  static HealthDataType? fromString(String tipo) {
    try {
      return HealthDataType.values.firstWhere((e) => e.name == tipo);
    } catch (e) {
      return null;
    }
  }

  bool get isPressaoArterial => this == HealthDataType.pressaoArterial;
}
