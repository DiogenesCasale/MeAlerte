class Treatment {
  final int? id;
  final int medicamentoId;
  final String dose;
  final String dataHoraInicio; // Formato ISO: YYYY-MM-DDTHH:MM:SS
  final int intervaloHoras;
  final int duracaoDias;
  final String? medicationName;

  Treatment({
    this.id,
    required this.medicamentoId,
    required this.dose,
    required this.dataHoraInicio,
    required this.intervaloHoras,
    required this.duracaoDias,
    this.medicationName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicamento_id': medicamentoId,
      'dose': dose,
      'data_hora_inicio': dataHoraInicio,
      'intervalo_horas': intervaloHoras,
      'duracao_dias': duracaoDias,
    };
  }
  
  static Treatment fromMapWithMedication(Map<String, dynamic> map) {
    return Treatment(
      id: map['treatmentId'],
      medicamentoId: 0,
      dose: map['dose'],
      dataHoraInicio: map['data_hora_inicio'],
      intervaloHoras: map['intervalo_horas'],
      duracaoDias: map['duracao_dias'],
      medicationName: map['medicationName'],
    );
  }

  Treatment copyWith({int? id, int? medicamentoId}) {
    return Treatment(
      id: id ?? this.id,
      medicamentoId: medicamentoId ?? this.medicamentoId,
      dose: dose,
      dataHoraInicio: dataHoraInicio,
      intervaloHoras: intervaloHoras,
      duracaoDias: duracaoDias,
      medicationName: medicationName,
    );
  }
}

// Classe auxiliar para a tela de listagem
class ScheduledDose {
  final int treatmentId; // ID do tratamento pai
  final String medicationName;
  final String dose;
  final DateTime scheduledTime;
  final bool isTaken; // Propriedade corrigida

  ScheduledDose({
    required this.treatmentId,
    required this.medicationName,
    required this.dose,
    required this.scheduledTime,
    required this.isTaken,
  });
}
