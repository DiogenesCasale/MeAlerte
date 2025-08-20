import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:app_remedio/models/medication.dart';

class DatabaseController {
  // Padrão Singleton para garantir uma única instância do banco de dados.
  static final DatabaseController instance = DatabaseController._init();
  static Database? _database;
  DatabaseController._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medications.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Cria a tabela no banco de dados
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const nullableTextType = 'TEXT';

    await db.execute('''
      CREATE TABLE medications ( 
        id $idType, 
        name $textType,
        quantity $intType,
        interval $textType,
        duration $textType,
        startTime $textType,
        observation $nullableTextType
      )
    ''');
  }

  // --- MÉTODOS CRUD ---

  // Criar (Create)
  Future<Medication> create(Medication medication) async {
    final db = await instance.database;
    final id = await db.insert('medications', medication.toMap());
    return medication.copyWith(id: id);
  }

  // Ler um (Read)
  Future<Medication> readMedication(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'medications',
      columns: ['id', 'name', 'quantity', 'interval', 'duration', 'startTime', 'observation'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Medication.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  // Ler todos (Read All)
  Future<List<Medication>> readAllMedications() async {
    final db = await instance.database;
    final result = await db.query('medications');
    return result.map((json) => Medication.fromMap(json)).toList();
  }

  // Atualizar (Update)
  Future<int> update(Medication medication) async {
    final db = await instance.database;
    return db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  // Deletar (Delete)
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
