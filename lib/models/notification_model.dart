// Em: models/notification_model.dart

class NotificationModel {
  final int id;
  final int idPerfil;
  final int? idAgendamento;
  final String? horarioAgendado;
  final String titulo;
  final String mensagem;
  final bool lida; // Mantém como bool no modelo
  final bool deletado; // Mantém como bool no modelo
  final DateTime dataCriacao;

  NotificationModel({
    required this.id,
    required this.idPerfil,
    this.idAgendamento,
    this.horarioAgendado,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    required this.deletado,
    required this.dataCriacao,
  });

  // <<< CORREÇÃO PRINCIPAL AQUI >>>
  // Este método converte o mapa do banco para o objeto do modelo
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      idPerfil: map['idPerfil'],
      idAgendamento: map['idAgendamento'],
      horarioAgendado: map['horarioAgendado'],
      titulo: map['titulo'],
      mensagem: map['mensagem'],
      // Converte o inteiro (0 ou 1) do banco para um booleano
      lida: map['lida'] == 1,
      deletado: map['deletado'] == 1,
      // Converte a string ISO8601 do banco para um objeto DateTime
      dataCriacao: DateTime.parse(map['dataCriacao']),
    );
  }

  // É importante ter este método para a reatividade funcionar bem
  NotificationModel copyWith({
    int? id,
    int? idPerfil,
    int? idAgendamento,
    String? horarioAgendado,
    String? titulo,
    String? mensagem,
    bool? lida,
    bool? deletado,
    DateTime? dataCriacao,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      idPerfil: idPerfil ?? this.idPerfil,
      idAgendamento: idAgendamento ?? this.idAgendamento,
      horarioAgendado: horarioAgendado ?? this.horarioAgendado,
      titulo: titulo ?? this.titulo,
      mensagem: mensagem ?? this.mensagem,
      lida: lida ?? this.lida,
      deletado: deletado ?? this.deletado,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}