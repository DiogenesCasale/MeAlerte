/// Modelo para doses tomadas
class TakenDose {
  final int? id;
  final int idAgendamento;
  final String dataTomada; // Data no formato ISO
  final String horarioTomada; // Horário real que foi tomado HH:MM
  final String horarioAgendado; // Horário que estava agendado HH:MM
  final int idPerfil;
  final String? observacao;
  final bool deletado;
  final String? dataCriacao;
  final String? dataAtualizacao;

  TakenDose({
    this.id,
    required this.idAgendamento,
    required this.dataTomada,
    required this.horarioTomada,
    required this.horarioAgendado,
    required this.idPerfil,
    this.observacao,
    this.deletado = false,
    this.dataCriacao,
    this.dataAtualizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idAgendamento': idAgendamento,
      'dataTomada': dataTomada,
      'horarioTomada': horarioTomada,
      'horarioAgendado': horarioAgendado,
      'idPerfil': idPerfil,
      'observacao': observacao,
      'deletado': deletado ? 1 : 0,
      'dataCriacao': dataCriacao ?? DateTime.now().toIso8601String(),
      'dataAtualizacao': dataAtualizacao ?? DateTime.now().toIso8601String(),
    };
  }

  static TakenDose fromMap(Map<String, dynamic> map) {
    return TakenDose(
      id: map['id'],
      idAgendamento: map['idAgendamento'],
      dataTomada: map['dataTomada'],
      horarioTomada: map['horarioTomada'],
      horarioAgendado: map['horarioAgendado'],
      idPerfil: map['idPerfil'],
      observacao: map['observacao'],
      deletado: (map['deletado'] ?? 0) == 1,
      dataCriacao: map['dataCriacao'],
      dataAtualizacao: map['dataAtualizacao'],
    );
  }

  TakenDose copyWith({
    int? id,
    int? idAgendamento,
    String? dataTomada,
    String? horarioTomada,
    String? horarioAgendado,
    int? idPerfil,
    String? observacao,
    bool? deletado,
    String? dataCriacao,
    String? dataAtualizacao,
  }) {
    return TakenDose(
      id: id ?? this.id,
      idAgendamento: idAgendamento ?? this.idAgendamento,
      dataTomada: dataTomada ?? this.dataTomada,
      horarioTomada: horarioTomada ?? this.horarioTomada,
      horarioAgendado: horarioAgendado ?? this.horarioAgendado,
      idPerfil: idPerfil ?? this.idPerfil,
      observacao: observacao ?? this.observacao,
      deletado: deletado ?? this.deletado,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}
