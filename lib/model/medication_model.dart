// models/produto_model.dart

class MedicationModel {
  final int? id;
  final String nome;
  final int quantidade;
  final String? descricao;

  MedicationModel({
    this.id,
    required this.nome,
    required this.quantidade,
    this.descricao,
  });

  /// Nome da tabela no banco de dados.
  /// Usar uma constante evita erros de digitação ao escrever queries.
  static const String tableName = 'medication';

  /// Script SQL para criar a tabela.
  /// A classe do modelo é a fonte da verdade sobre sua própria estrutura.
  static const String createTableScript =
      '''
    CREATE TABLE $tableName (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      quantidade INTEGER NOT NULL,
      descricao TEXT
    )
  ''';

  /// Converte um objeto MedicationModel para um Map<String, dynamic>.
  /// Isso é necessário para inserir/atualizar dados no sqflite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'quantidade': quantidade,
      'descricao': descricao,
    };
  }

  /// Converte um Map<String, dynamic> (vindo do banco) para um objeto MedicationModel.
  /// Isso é necessário para ler dados do sqflite.
  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'],
      nome: map['nome'],
      quantidade: map['quantidade'],
      descricao: map['descricao'],
    );
  }
}
