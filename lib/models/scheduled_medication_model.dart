class ScheduledMedication {
  final int? id;
  final int idPerfil;
  final String hora; // Formato HH:MM
  final double dose; // Quantidade numérica da dose
  final int intervalo; // Intervalo em horas
  final int dias; // Mantido para compatibilidade
  final String? dataInicio; // Data de início do tratamento
  final String? dataFim; // Data de fim do tratamento
  final bool paraSempre; // Se é um tratamento contínuo
  final String? observacao;
  final int idMedicamento;
  final String? dataCriacao;
  final bool deletado; // Soft delete
  final String? medicationName; // Para joins
  final String? caminhoImagem; // Para joins
  final int? idAgendamentoPai;
  final String? dataAtualizacao;

  ScheduledMedication({
    this.id,
    required this.idPerfil,
    required this.hora,
    required this.dose,
    required this.intervalo,
    this.dias = 0, // Valor padrão para compatibilidade
    this.dataInicio,
    this.dataFim,
    this.paraSempre = false,
    this.observacao,
    required this.idMedicamento,
    this.dataCriacao,
    this.dataAtualizacao,
    this.deletado = false,
    this.medicationName,
    this.caminhoImagem,
    this.idAgendamentoPai,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idPerfil': idPerfil,
      'hora': hora,
      'dose': dose,
      'intervalo': intervalo,
      'dias': dias,
      'dataInicio': dataInicio,
      'dataFim': dataFim,
      'paraSempre': paraSempre ? 1 : 0,
      'observacao': observacao,
      'idMedicamento': idMedicamento,
      'dataCriacao': dataCriacao ?? DateTime.now().toIso8601String(),
      'dataAtualizacao': dataAtualizacao ?? DateTime.now().toIso8601String(),
      'deletado': deletado ? 1 : 0,
      'idAgendamentoPai': idAgendamentoPai,
    };
  }

  static ScheduledMedication fromMap(Map<String, dynamic> map) {
    return ScheduledMedication(
      id: map['id'],
      idPerfil: map['idPerfil'],
      hora: map['hora'],
      dose: (map['dose'] as num).toDouble(),
      intervalo: map['intervalo'],
      dias: map['dias'] ?? 0,
      dataInicio: map['dataInicio'],
      dataFim: map['dataFim'],
      paraSempre: (map['paraSempre'] ?? 0) == 1,
      observacao: map['observacao'],
      idMedicamento: map['idMedicamento'],
      dataCriacao: map['dataCriacao'],
      dataAtualizacao: map['dataAtualizacao'],
      deletado: (map['deletado'] ?? 0) == 1,
      idAgendamentoPai: map['idAgendamentoPai'],
    );
  }

  static ScheduledMedication fromMapWithMedication(Map<String, dynamic> map) {
    return ScheduledMedication(
      id: map['id'],
      idPerfil: map['idPerfil'],
      hora: map['hora'],
      dose: (map['dose'] as num).toDouble(),
      intervalo: map['intervalo'],
      dias: map['dias'] ?? 0,
      dataInicio: map['dataInicio'],
      dataFim: map['dataFim'],
      paraSempre: (map['paraSempre'] ?? 0) == 1,
      observacao: map['observacao'],
      idMedicamento: map['idMedicamento'],
      dataCriacao: map['dataCriacao'],
      dataAtualizacao: map['dataAtualizacao'],
      deletado: (map['deletado'] ?? 0) == 1,
      medicationName: map['medicationName'],
      caminhoImagem: map['caminhoImagem'],
      idAgendamentoPai: map['idAgendamentoPai'],
    );
  }

  // DENTRO DA CLASSE ScheduledMedication

  /// Cria uma cópia deste objeto, permitindo a substituição de campos específicos.
  ScheduledMedication copyWith({
    int? id,
    int? idPerfil,
    String? hora,
    double? dose,
    int? intervalo,
    int? dias,
    String? dataInicio,
    String? dataFim,
    bool? paraSempre,
    String? observacao,
    int? idMedicamento,
    String? dataCriacao,
    String? dataAtualizacao,
    bool? deletado,
    String? medicationName,
    String? caminhoImagem,
    int? idAgendamentoPai,
  }) {
    return ScheduledMedication(
      // A lógica é: use o novo valor se ele não for nulo, senão, use o valor antigo (this.campo).
      id: id ?? this.id,
      idPerfil: idPerfil ?? this.idPerfil,
      hora: hora ?? this.hora,
      dose: dose ?? this.dose,
      intervalo: intervalo ?? this.intervalo,
      dias: dias ?? this.dias,
      dataInicio:
          dataInicio ??
          this.dataInicio, // <-- Chave para resolver seu problema!
      dataFim: dataFim ?? this.dataFim,
      paraSempre: paraSempre ?? this.paraSempre,
      observacao: observacao ?? this.observacao,
      idMedicamento: idMedicamento ?? this.idMedicamento,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      deletado: deletado ?? this.deletado,
      medicationName: medicationName ?? this.medicationName,
      caminhoImagem: caminhoImagem ?? this.caminhoImagem,
      idAgendamentoPai: idAgendamentoPai ?? this.idAgendamentoPai,
    );
  }
}

/// Enum para representar os estados das medicações/agendamentos
enum MedicationStatus {
  notTaken('Não Tomado'),
  taken('Tomado'),
  late('Atrasado'),
  upcoming('Próximo'),
  missed('Perdido');

  const MedicationStatus(this.displayName);
  final String displayName;
}

// Classe auxiliar para exibir medicamentos hoje
class TodayDose {
  final int scheduledMedicationId;
  final int idMedicamento; // ID do medicamento para redução de estoque
  final String medicationName;
  final double dose; // Quantidade numérica da dose
  final DateTime scheduledTime;
  final String? observacao;
  final int idPerfil;
  final String? caminhoImagem;
  final MedicationStatus status;
  final int? takenDoseId; // ID da dose tomada, se existir

  TodayDose({
    required this.scheduledMedicationId,
    required this.idMedicamento,
    required this.medicationName,
    required this.dose,
    required this.scheduledTime,
    this.observacao,
    required this.idPerfil,
    this.caminhoImagem,
    this.status = MedicationStatus.notTaken,
    this.takenDoseId,
  });

  TodayDose copyWith({
    int? scheduledMedicationId,
    int? idMedicamento,
    String? medicationName,
    double? dose,
    DateTime? scheduledTime,
    String? observacao,
    int? idPerfil,
    String? caminhoImagem,
    MedicationStatus? status,
    int? takenDoseId,
  }) {
    return TodayDose(
      scheduledMedicationId: scheduledMedicationId ?? this.scheduledMedicationId,
      idMedicamento: idMedicamento ?? this.idMedicamento,
      medicationName: medicationName ?? this.medicationName,
      dose: dose ?? this.dose,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      observacao: observacao ?? this.observacao,
      idPerfil: idPerfil ?? this.idPerfil,
      caminhoImagem: caminhoImagem ?? this.caminhoImagem,
      status: status ?? this.status,
      takenDoseId: takenDoseId ?? this.takenDoseId,
    );
  }
}
