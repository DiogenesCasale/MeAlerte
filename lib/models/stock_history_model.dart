// arquivo: models/stock_history_model.dart

enum StockMovementType {
  entrada,
  saida,
}

class StockHistory {
  final int? id;
  final int medicationId;
  final int profileId;
  final int? takenDoseId;
  final StockMovementType type;
  final int quantity;
  final DateTime creationDate;
  final bool deletado;

  // Campo adicional para facilitar a exibição na tela de histórico
  final String? medicationName;

  StockHistory({
    this.id,
    required this.medicationId,
    required this.profileId,
    this.takenDoseId,
    required this.type,
    required this.quantity,
    required this.creationDate,
    this.deletado = false,
    this.medicationName, // Opcional
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idMedicamento': medicationId,
      'idPerfil': profileId,
      'idDoseTomada': takenDoseId,
      'tipo': type.name,
      'quantidade': quantity,
      'dataCriacao': creationDate.toIso8601String(),
      'deletado': deletado ? 1 : 0,
    };
  }

  // O fromMap agora pode receber dados da junção (JOIN) de tabelas
  factory StockHistory.fromMap(Map<String, dynamic> map) {
    return StockHistory(
      id: map['id'],
      medicationId: map['idMedicamento'],
      profileId: map['idPerfil'],
      takenDoseId: map['idDoseTomada'],
      type: StockMovementType.values.byName(map['tipo']),
      quantity: map['quantidade'],
      creationDate: DateTime.parse(map['dataCriacao']),
      deletado: (map['deletado'] ?? 0) == 1,
      medicationName: map['nomeMedicamento'], 
    );
  }
}