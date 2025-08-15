import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:me_alerte/model/medication_model.dart';

///A classe DatabaseConnection é responsável por criar e manter o banco de dados
class DatabaseConnection {
  //construtor privado, impede que seja instanciado diretamente
  DatabaseConnection._privateConstructor();
  //instancia única
  static final DatabaseConnection instance =
      DatabaseConnection._privateConstructor();
  //variável que representa o banco de dados
  static Database? _database;

  //getter do banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Método para inicializar o banco de dados
  Future<Database> _initDatabase() async {
    // Pega o caminho do diretório de documentos do app, também define o nome do banco de dados
    String path = join(await getDatabasesPath(), 'mealerte.db');

    // Abre o banco de dados. O "onCreate" é executado apenas na primeira vez que o app é aberto.
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  //O método "onCreate" é encarregado de criar as tabelas do banco de dados
  Future _onCreate(Database db, int version) async {
    //aqui vai o código sql dos model, precisa de um db.execute para cada model
    await db.execute(MedicationModel.createTableScript);
  }
}
