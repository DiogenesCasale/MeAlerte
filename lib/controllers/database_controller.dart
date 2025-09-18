import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseController {
  // --- Configuração do Singleton ---
  static final DatabaseController instance = DatabaseController._init();
  static Database? _database;
  DatabaseController._init();

  // --- Getter principal para o banco de dados ---
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_remedio_v4.db');
    return _database!;
  }

  // --- Inicialização e criação das tabelas ---
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        // 1. Cria o esquema da primeira versão
        await _createDBSchemaV1(db); 
        // 2. Executa todas as migrações desde a v1 até a versão final
        await _onUpgrade(db, 1, version);
      },
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDBSchemaV1(Database db) async {
    // Tabela de medicamentos
    await db.execute('''
      CREATE TABLE tblMedicamentos ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        nome TEXT NOT NULL,
        quantidade INTEGER NOT NULL CHECK(quantidade >= 0),
        observacao TEXT,
        data_criacao TEXT NOT NULL
      )
    ''');

    // Tabela de medicamentos agendados
    await db.execute('''
      CREATE TABLE tblMedicamentosAgendados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hora TEXT NOT NULL,
        dose REAL NOT NULL CHECK(dose > 0),
        intervalo INTEGER NOT NULL,
        dias INTEGER NOT NULL CHECK(dias >= 0),
        observacao TEXT,
        medicamento_id INTEGER NOT NULL,
        data_criacao TEXT NOT NULL,
        FOREIGN KEY (medicamento_id) REFERENCES tblMedicamentos (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print(
      "Executando migração do banco de dados da versão $oldVersion para $newVersion...",
    );

    // Um loop que executa cada migração necessária, uma por uma.
    // Por exemplo, ao atualizar da v1 para a v4, ele executará as migrações
    // para a v2, depois para a v3 e, finalmente, para a v4.
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      print("Aplicando migração para a versão $version...");
      switch (version) {
        case 2:
          await _migrateToV2(db);
          break;
        case 3:
          await _migrateToV3(db);
          break;
        case 4:
          await _migrateToV4(db);
          break;
        case 5:
          await _migrateToV5(db);
          break;
      }
    }

    print("Migração do banco de dados concluída com sucesso.");
  }

  Future<void> _migrateToV2(Database db) async {
    final batch = db.batch();

    print("Migração da v1 para v2...");
    batch.execute(
      'ALTER TABLE tblMedicamentos RENAME COLUMN quantidade TO estoque;',
    );

    batch.execute(
      "ALTER TABLE tblMedicamentos ADD COLUMN tipo TEXT NOT NULL DEFAULT 'comprimido';",
    );

    // Alterações na tblMedicamentosAgendados
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados ADD COLUMN data_inicio TEXT;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados ADD COLUMN data_fim TEXT;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados ADD COLUMN para_sempre INTEGER DEFAULT 0;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados ADD COLUMN deletado INTEGER DEFAULT 0;',
    );

    await batch.commit();
    print("Migração v1 para v2 concluída com sucesso.");
  }

  Future<void> _migrateToV3(Database db) async {
    final batch = db.batch();

    // Renomeia colunas para o padrão camelCase
    batch.execute(
      'ALTER TABLE tblMedicamentos RENAME COLUMN data_criacao TO dataCriacao;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados RENAME COLUMN data_criacao TO dataCriacao;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados RENAME COLUMN medicamento_id TO idMedicamento;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados RENAME COLUMN data_inicio TO dataInicio;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados RENAME COLUMN data_fim TO dataFim;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados RENAME COLUMN para_sempre TO paraSempre;',
    );

    // Adiciona novas colunas
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados ADD COLUMN dataAtualizacao TEXT;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentos ADD COLUMN deletado INTEGER DEFAULT 0;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentos ADD COLUMN caminhoImagem TEXT NULL;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentos ADD COLUMN dataAtualizacao TEXT;',
    );

    // Cria a nova tabela de perfil
    batch.execute('''
    CREATE TABLE tblPerfil (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      dataNascimento TEXT NULL,
      genero TEXT NULL,
      caminhoImagem TEXT NULL,
      deletado INTEGER DEFAULT 0,
      dataCriacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      dataAtualizacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''');


    // Cria a nova tabela de dados de saúde (Altura, Peso, Glicose, Pressão Arterial, Pulso, etc.)
    batch.execute('''
    CREATE TABLE tblDadosSaude (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      idPerfil INTEGER NOT NULL,
      tipo TEXT NOT NULL,
      valor REAL NULL,
      valorSistolica REAL NULL,
      valorDiastolica REAL NULL,
      unidade TEXT NULL,
      observacao TEXT NULL,
      dataRegistro TEXT NOT NULL,
      deletado INTEGER DEFAULT 0,
      dataCriacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      dataAtualizacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (idPerfil) REFERENCES tblPerfil (id) ON DELETE CASCADE
    )
    ''');

    // Adiciona a referência de perfil às tabelas existentes
    batch.execute(
      'ALTER TABLE tblMedicamentos ADD COLUMN idPerfil INTEGER NOT NULL DEFAULT 1;',
    );
    batch.execute(
      'ALTER TABLE tblMedicamentosAgendados ADD COLUMN idPerfil INTEGER NOT NULL DEFAULT 1;',
    );

    await batch.commit();
    print("Migração para v3 concluída.");
  }

  /// Migração da v3 para v4: Adiciona a tabela para controle de doses tomadas. Até qaqui o Incremento 2 do projeto está feito.
  Future<void> _migrateToV4(Database db) async {
    final batch = db.batch();

    // Cria a tabela de doses tomadas
    batch.execute('''
    CREATE TABLE tblDosesTomadas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      idAgendamento INTEGER NOT NULL,
      dataTomada TEXT NOT NULL,
      horarioTomada TEXT NOT NULL,
      horarioAgendado TEXT NOT NULL,
      idPerfil INTEGER NOT NULL,
      observacao TEXT,
      deletado INTEGER DEFAULT 0,
      dataCriacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      dataAtualizacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (idAgendamento) REFERENCES tblMedicamentosAgendados (id) ON DELETE CASCADE
    )
  ''');

    await batch.commit();
    print("Migração para v4 concluída.");
  }

  /// Migração da v4 para v5: Adiciona a coluna de horário agendado na tabela de doses tomadas.
  Future<void> _migrateToV5(Database db) async {
    final batch = db.batch();

    await batch.commit();
    print("Migração para v5 concluída.");
  }

}
