class Medication {
  final int? id;
  final String name;
  final int quantity;
  final String interval;
  final String duration;
  final String startTime;
  final String? observation;

  Medication({
    this.id,
    required this.name,
    required this.quantity,
    required this.interval,
    required this.duration,
    required this.startTime,
    this.observation,
  });

  // Converte um Map vindo do banco de dados em um objeto Medication.
  static Medication fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      interval: map['interval'] as String,
      duration: map['duration'] as String,
      startTime: map['startTime'] as String,
      observation: map['observation'] as String?,
    );
  }

  // Converte um objeto Medication em um Map para o banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'interval': interval,
      'duration': duration,
      'startTime': startTime,
      'observation': observation,
    };
  }
  
  // Cria uma cópia do objeto com valores potencialmente diferentes.
  Medication copyWith({
    int? id,
    String? name,
    int? quantity,
    String? interval,
    String? duration,
    String? startTime,
    String? observation,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      interval: interval ?? this.interval,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      observation: observation ?? this.observation,
    );
  }
}
