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

  // --- Método para fechar o banco de dados ---
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('Banco de dados fechado e resetado.');
    }
  }

  // --- Inicialização e criação das tabelas ---
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 5,
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

    // 1. Selecionar os dados existentes da tblMedicamentos
    List<Map<String, dynamic>> dadosMedicamentos = await db.rawQuery(
      'SELECT * FROM tblMedicamentos;',
    );

    // 2. Dropar a tabela tblMedicamentos
    batch.execute('DROP TABLE IF EXISTS tblMedicamentos;');

    // 3. Recriar a tabela tblMedicamentos com a nova estrutura
    batch.execute('''
      CREATE TABLE tblMedicamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        estoque REAL NOT NULL DEFAULT 0,
        tipo TEXT NOT NULL DEFAULT 'comprimido',
        deletado INTEGER DEFAULT 0,
        caminhoImagem TEXT NULL,
        observacao TEXT,
        dataCriacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        dataAtualizacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''');

    // 4. Transferir os dados para a nova tabela tblMedicamentos
    if (dadosMedicamentos.isNotEmpty) {
      print("Migrando dados de tblMedicamentos...");
      for (var dadosMedicamento in dadosMedicamentos) {
        // Mapear os dados da tabela antiga para a nova
        // Campos da v1: id, nome, quantidade, observacao, data_criacao
        // Campos da v2: id, nome, estoque, tipo, deletado, idPerfil, caminhoImagem, observacao, dataCriacao, dataAtualizacao
        batch.execute(
          '''
      INSERT INTO tblMedicamentos (id, nome, estoque, tipo, deletado, caminhoImagem, observacao, dataCriacao, dataAtualizacao)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
          [
            dadosMedicamento['id'], // Mantém o mesmo ID
            dadosMedicamento['nome'],
            dadosMedicamento['quantidade'] ??
                0, // Mapeia quantidade para estoque
            'comprimido', // Valor padrão para tipo
            0, // Valor padrão para não deletado
            null, // caminhoImagem não existe na v1, então null
            dadosMedicamento['observacao'],
            dadosMedicamento['data_criacao'] ??
                '', // data_criacao mapeia para dataCriacao
            dadosMedicamento['data_criacao'] ??
                '', // Usa data_criacao como dataAtualizacao inicial
          ],
        );
      }
    }

    // 5. Selecionar os dados existentes da tblMedicamentosAgendados
    List<Map<String, dynamic>> dadosMedicamentosAgendados = await db.rawQuery(
      'SELECT * FROM tblMedicamentosAgendados;',
    );

    // 6. Dropar a tabela tblMedicamentosAgendados
    batch.execute('DROP TABLE IF EXISTS tblMedicamentosAgendados;');

    // 7. Recriar a tabela tblMedicamentosAgendados com a nova estrutura
    batch.execute('''
      CREATE TABLE tblMedicamentosAgendados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hora TEXT NOT NULL,
        dose REAL NOT NULL CHECK(dose > 0),
        intervalo INTEGER NOT NULL,
        dias INTEGER NOT NULL CHECK(dias >= 0),
        deletado INTEGER DEFAULT 0,
        observacao TEXT,
        idMedicamento INTEGER NOT NULL,
        dataInicio TEXT NULL,
        dataFim TEXT NULL,
        paraSempre INTEGER DEFAULT 0,
        dataCriacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        dataAtualizacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (idMedicamento) REFERENCES tblMedicamentos (id) ON DELETE CASCADE
      )
      ''');

    // 8. Transferir os dados para a nova tabela tblMedicamentosAgendados
    if (dadosMedicamentosAgendados.isNotEmpty) {
      print("Migrando dados de tblMedicamentosAgendados...");
      for (var dadosMedicamentoAgendado in dadosMedicamentosAgendados) {
        if (dadosMedicamentoAgendado['medicamento_id'] == null) {
          print(
            "⚠️ Aviso: Agendamento com ID ${dadosMedicamentoAgendado['id']} possui medicamento_id nulo. Pulando migração deste registro.",
          );
          continue; // Pula este registro
        }

        if (dadosMedicamentoAgendado['data_criacao'] == null) {
          print(
            "⚠️ Aviso: Agendamento com ID ${dadosMedicamentoAgendado['id']} possui data_criacao nulo. Pulando migração deste registro.",
          );
          continue; // Pula este registro
        }

        var dataFim =
            dadosMedicamentoAgendado['dias'] != null &&
                dadosMedicamentoAgendado['dias'] > 0
            ? DateTime.parse(dadosMedicamentoAgendado['data_criacao'])
                  .add(Duration(days: dadosMedicamentoAgendado['dias']))
                  .toIso8601String()
            : null;
        batch.execute(
          '''
        INSERT INTO tblMedicamentosAgendados (id, hora, dose, intervalo, dias, deletado, observacao, idMedicamento, dataInicio, dataFim, paraSempre, dataCriacao, dataAtualizacao)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            dadosMedicamentoAgendado['id'],
            dadosMedicamentoAgendado['hora'],
            dadosMedicamentoAgendado['dose'],
            dadosMedicamentoAgendado['intervalo'],
            dadosMedicamentoAgendado['dias'],
            0,
            dadosMedicamentoAgendado['observacao'],
            dadosMedicamentoAgendado['medicamento_id'],
            dadosMedicamentoAgendado['data_criacao'],
            dataFim,
            0,
            dadosMedicamentoAgendado['data_criacao'] ?? '',
            dadosMedicamentoAgendado['data_criacao'] ?? '',
          ],
        );
      }
    }

    // 9. Triggers para atualização das colunas dataAtualizacao
    batch.execute('''
        CREATE TRIGGER updateDataAtualizacaoMedicamentos
        AFTER UPDATE ON tblMedicamentos
        FOR EACH ROW
        BEGIN
          UPDATE tblMedicamentos
          SET dataAtualizacao = CURRENT_TIMESTAMP
          WHERE id = OLD.id;
        END;
      ''');

    batch.execute('''
        CREATE TRIGGER updateDataAtualizacaoAgendamentos
        AFTER UPDATE ON tblMedicamentosAgendados
        FOR EACH ROW
        BEGIN
          UPDATE tblMedicamentosAgendados
          SET dataAtualizacao = CURRENT_TIMESTAMP
          WHERE id = OLD.id;
        END;
      ''');

    try {
      await batch.commit();
      print("Migração v1 para v2 concluída com sucesso.");
    } catch (e) {
      print("Erro na migração v1 para v2: $e");
      rethrow;
    }
  }

  Future<void> _migrateToV3(Database db) async {
    final batch = db.batch();

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

    // Cria a nova tabela de dados de saúde
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

    // Adiciona chaves estrangeiras para idPerfil em tblMedicamentos e tblMedicamentosAgendados
    // 1. Altera a tabela tblMedicamentos
    batch.execute('''
      ALTER TABLE tblMedicamentos
      ADD COLUMN idPerfil INTEGER NOT NULL DEFAULT 1
      REFERENCES tblPerfil(id) ON DELETE CASCADE
    ''');

    // 2. Altera a tabela tblMedicamentosAgendados
    batch.execute('''
      ALTER TABLE tblMedicamentosAgendados
      ADD COLUMN idPerfil INTEGER NOT NULL DEFAULT 1
      REFERENCES tblPerfil(id) ON DELETE CASCADE
    ''');

    // Triggers para atualização das colunas dataAtualizacao
    batch.execute('''
      CREATE TRIGGER updateDataAtualizacaoPerfil
      AFTER UPDATE ON tblPerfil
      FOR EACH ROW
      BEGIN
        UPDATE tblPerfil
        SET dataAtualizacao = CURRENT_TIMESTAMP
        WHERE id = OLD.id;
      END;
    ''');

    batch.execute('''
      CREATE TRIGGER updateDataAtualizacaoDadosSaude
      AFTER UPDATE ON tblDadosSaude
      FOR EACH ROW
      BEGIN
        UPDATE tblDadosSaude
        SET dataAtualizacao = CURRENT_TIMESTAMP
        WHERE id = OLD.id;
      END;
    ''');

    try {
      await batch.commit();
      print("Migração v2 para v3 concluída com sucesso.");
    } catch (e) {
      print("Erro na migração v2 para v3: $e");
      rethrow;
    }
  }

  Future<void> _migrateToV4(Database db) async {
    final batch = db.batch();

    // Cria a tabela de doses tomadas
    batch.execute('''
    CREATE TABLE tblDosesTomadas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      idAgendamento INTEGER NOT NULL,
      idPerfil INTEGER NOT NULL DEFAULT 1,
      dataTomada TEXT NOT NULL,
      horarioTomada TEXT NOT NULL,
      horarioAgendado TEXT NOT NULL,
      observacao TEXT,
      deletado INTEGER DEFAULT 0,
      dataCriacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      dataAtualizacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (idAgendamento) REFERENCES tblMedicamentosAgendados (id) ON DELETE CASCADE,
      FOREIGN KEY (idPerfil) REFERENCES tblPerfil (id) ON DELETE CASCADE
    )
  ''');

    // Cria o trigger para atualização da coluna dataAtualizacao
    batch.execute('''
      CREATE TRIGGER updateDataAtualizacaoDosesTomadas
      AFTER UPDATE ON tblDosesTomadas
      FOR EACH ROW
      BEGIN
        UPDATE tblDosesTomadas
        SET dataAtualizacao = CURRENT_TIMESTAMP
        WHERE id = OLD.id;
      END;
    ''');

    try {
      await batch.commit();
      print("Migração v3 para v4 concluída com sucesso.");
    } catch (e) {
      print("Erro na migração v3 para v4: $e");
      rethrow;
    }
  }

  Future<void> _migrateToV5(Database db) async {
    final batch = db.batch();
    // INCREMENTO 3 DO PROJETO

    // Adiciona a coluna perfilPadrao para a tabela tblPerfil
    batch.execute('''
      ALTER TABLE tblPerfil ADD COLUMN perfilPadrao INTEGER NOT NULL DEFAULT 0;
    ''');

    // Adiciona a coluna mensagemCompartilhar para a tabela tblPerfil
    batch.execute('''
      ALTER TABLE tblPerfil ADD COLUMN mensagemCompartilhar TEXT NOT NULL DEFAULT '';
    ''');

    batch.execute('''
      CREATE TABLE tblEstoqueMedicamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idMedicamento INTEGER NOT NULL,
        idPerfil INTEGER NOT NULL DEFAULT 1,
        idDoseTomada INTEGER NULL,
        tipo TEXT NOT NULL,
        quantidade REAL NOT NULL,
        observacao TEXT NULL,
        deletado INTEGER DEFAULT 0,
        dataCriacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (idMedicamento) REFERENCES tblMedicamentos (id) ON DELETE CASCADE,
        FOREIGN KEY (idPerfil) REFERENCES tblPerfil (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
        CREATE TABLE tblNotificacoes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          idPerfil INTEGER NOT NULL DEFAULT 1,
          idAgendamento INTEGER,
          horarioAgendado TEXT,
          titulo TEXT NOT NULL,
          mensagem TEXT NOT NULL,
          lida INTEGER DEFAULT 0,
          deletado INTEGER DEFAULT 0,
          dataCriacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (idPerfil) REFERENCES tblPerfil (id) ON DELETE CASCADE,
          FOREIGN KEY (idAgendamento) REFERENCES tblMedicamentosAgendados (id) ON DELETE CASCADE
          )
      ''');

    batch.execute('''
        CREATE TABLE tblAnotacoes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          idPerfil INTEGER NOT NULL DEFAULT 1,
          anotacao TEXT NOT NULL,
          deletado INTEGER DEFAULT 0,
          dataCriacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          dataAtualizacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (idPerfil) REFERENCES tblPerfil (id) ON DELETE CASCADE
          )
      ''');

    batch.execute('''
        CREATE TRIGGER updateDataAtualizacaoAnotacoes
        AFTER UPDATE ON tblAnotacoes
        FOR EACH ROW
        BEGIN
          UPDATE tblAnotacoes
          SET dataAtualizacao = CURRENT_TIMESTAMP
          WHERE id = OLD.id;
        END;
      ''');

    batch.execute('''
          ALTER TABLE tblMedicamentosAgendados ADD COLUMN idAgendamentoPai INTEGER NULL;
        ''');

    try {
      await batch.commit();
      print("Migração v4 para v5 concluída com sucesso.");
    } catch (e) {
      print("Erro na migração v4 para v5: $e");
      rethrow;
    }
  }
}
