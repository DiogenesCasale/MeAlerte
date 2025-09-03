class ScheduledMedication {
  final int? id;
  final String hora; // Formato HH:MM
  final double dose; // Quantidade numérica da dose
  final int intervalo; // Intervalo em horas
  final int dias;
  final String? observacao;
  final int medicamentoId;
  final String? dataCriacao;
  final String? medicationName; // Para joins

  ScheduledMedication({
    this.id,
    required this.hora,
    required this.dose,
    required this.intervalo,
    required this.dias,
    this.observacao,
    required this.medicamentoId,
    this.dataCriacao,
    this.medicationName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hora': hora,
      'dose': dose,
      'intervalo': intervalo,
      'dias': dias,
      'observacao': observacao,
      'medicamento_id': medicamentoId,
      'data_criacao': dataCriacao ?? DateTime.now().toIso8601String(),
    };
  }

  static ScheduledMedication fromMap(Map<String, dynamic> map) {
    return ScheduledMedication(
      id: map['id'],
      hora: map['hora'],
      dose: (map['dose'] as num).toDouble(),
      intervalo: map['intervalo'],
      dias: map['dias'],
      observacao: map['observacao'],
      medicamentoId: map['medicamento_id'],
      dataCriacao: map['data_criacao'],
    );
  }

  static ScheduledMedication fromMapWithMedication(Map<String, dynamic> map) {
    return ScheduledMedication(
      id: map['id'],
      hora: map['hora'],
      dose: (map['dose'] as num).toDouble(),
      intervalo: map['intervalo'],
      dias: map['dias'],
      observacao: map['observacao'],
      medicamentoId: map['medicamento_id'],
      dataCriacao: map['data_criacao'],
      medicationName: map['medicationName'],
    );
  }

  ScheduledMedication copyWith({int? id}) {
    return ScheduledMedication(
      id: id ?? this.id,
      hora: hora,
      dose: dose,
      intervalo: intervalo,
      dias: dias,
      observacao: observacao,
      medicamentoId: medicamentoId,
      dataCriacao: dataCriacao,
      medicationName: medicationName,
    );
  }
}

// Classe auxiliar para exibir medicamentos hoje
class TodayDose {
  final int scheduledMedicationId;
  final String medicationName;
  final double dose; // Quantidade numérica da dose
  final DateTime scheduledTime;
  final String? observacao;

  TodayDose({
    required this.scheduledMedicationId,
    required this.medicationName,
    required this.dose,
    required this.scheduledTime,
    this.observacao,
  });
} 