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
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
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
        // Adicione novos 'cases' aqui para futuras versões.
        // case 5:
        //   await _migrateToV5(db);
        //   break;
      }
    }

    print("Migração do banco de dados concluída com sucesso.");
  }

  Future<void> _migrateToV2(Database db) async {
    final batch = db.batch();

    print("Migração da v1 para v2...");

    // Alterações na tblMedicamentos
    // NOTA: SQLite não permite renomear colunas em todas as versões.
    // O comando 'RENAME COLUMN' é mais recente. A maneira mais segura seria criar uma
    // nova tabela, copiar os dados e renomear, mas para simplicidade, usaremos o ALTER.
    // Assumindo que a coluna se chamava 'quantidade' e agora é 'estoque'.
    // Se sua tabela já tinha 'estoque', este comando não é necessário.
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
      peso REAL NULL,
      caminhoImagem TEXT NULL,
      deletado INTEGER DEFAULT 0,
      dataCriacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      dataAtualizacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
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

  /// Migração da v3 para v4: Adiciona a tabela para controle de doses tomadas.
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

  // METODO DE DEBUG DOS CAMPOS DA TABELA
  Future<void> _inspectTable(Database db, String tableName) async {
    print("\n--- Inspecionando a tabela: '$tableName' ---");
    try {
      // 1. Verifica a ESTRUTURA (colunas)
      final tableInfo = await db.rawQuery('PRAGMA table_info($tableName);');
      print("Estrutura (Colunas):");
      if (tableInfo.isEmpty) {
        print("  (A tabela não existe ou não tem colunas)");
      } else {
        for (var column in tableInfo) {
          print(
            "  - Nome: ${column['name']}, Tipo: ${column['type']}, Nulo: ${column['notnull'] == 0}",
          );
        }
      }

      // 2. Verifica os DADOS (as 5 primeiras linhas)
      final sampleData = await db.query(tableName, limit: 5);
      print("\nAmostra de Dados (até 5 linhas):");
      if (sampleData.isEmpty) {
        print("  (A tabela está vazia)");
      } else {
        for (var row in sampleData) {
          print("  - $row");
        }
      }
    } catch (e) {
      print("  Erro ao inspecionar a tabela '$tableName': $e");
    }
    print("--- Fim da inspeção de '$tableName' ---\n");
  }

  // METODO DE DEBUG DOS DADOS DA TABELA
  Future<void> debugPrintTableData(Database db, String tableName) async {
    print("\n--- 🕵️  [DEBUG] Conteúdo da Tabela: '$tableName' 🕵️ ---");
    try {
      // 1. Executa a query para buscar todos os dados
      final List<Map<String, dynamic>> results = await db.query(tableName);

      // 2. Verifica se a tabela está vazia
      if (results.isEmpty) {
        print("|| A tabela está vazia ou não existe. ||");
        print("--- Fim do conteúdo de '$tableName' ---\n");
        return;
      }

      // 3. Monta e imprime o cabeçalho com os nomes das colunas
      final columns = results.first.keys;
      final header = columns.map((col) => col.padRight(15)).join(' | ');
      print(header);
      print('-' * header.length); // Linha separadora

      // 4. Itera sobre cada linha e imprime os dados
      for (final row in results) {
        final rowValues = columns
            .map((col) => (row[col]?.toString() ?? 'NULL').padRight(15))
            .join(' | ');
        print(rowValues);
      }
    } catch (e) {
      print("🚨 Erro ao ler a tabela '$tableName': $e");
    }
    print("--- Fim do conteúdo de '$tableName' ---\n");
  }
}
