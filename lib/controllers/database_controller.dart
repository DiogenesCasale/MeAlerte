import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:intl/intl.dart';

class DatabaseController {
  static final DatabaseController instance = DatabaseController._init();
  static Database? _database;
  DatabaseController._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_remedio_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabela de medicamentos conforme documentação
    await db.execute('''
      CREATE TABLE tblMedicamentos ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        nome TEXT NOT NULL,
        quantidade INTEGER NOT NULL CHECK(quantidade >= 0),
        observacao TEXT,
        data_criacao TEXT NOT NULL
      )
    ''');

    // Tabela de medicamentos agendados conforme documentação
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

  // --- MÉTODOS PARA MEDICAMENTOS ---
  Future<Medication> createMedication(Medication medication) async {
    final db = await instance.database;
    final id = await db.insert('tblMedicamentos', medication.toMap());
    return medication.copyWith(id: id);
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await instance.database;
    final result = await db.query('tblMedicamentos', orderBy: 'nome ASC');
    return result.map((json) => Medication.fromMap(json)).toList();
  }

  Future<List<Medication>> searchMedications(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'tblMedicamentos',
      where: 'nome LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'nome ASC',
    );
    return result.map((json) => Medication.fromMap(json)).toList();
  }

  // --- MÉTODOS PARA MEDICAMENTOS AGENDADOS ---
  Future<ScheduledMedication> createScheduledMedication(ScheduledMedication scheduledMedication) async {
    final db = await instance.database;
    final id = await db.insert('tblMedicamentosAgendados', scheduledMedication.toMap());
    return scheduledMedication.copyWith(id: id);
  }

  Future<void> updateScheduledMedication(ScheduledMedication scheduledMedication) async {
    final db = await instance.database;
    await db.update(
      'tblMedicamentosAgendados',
      scheduledMedication.toMap(),
      where: 'id = ?',
      whereArgs: [scheduledMedication.id],
    );
  }

  Future<void> deleteScheduledMedication(int id) async {
    final db = await instance.database;
    await db.delete(
      'tblMedicamentosAgendados',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ScheduledMedication>> getAllScheduledMedications() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        s.id, s.hora, s.dose, s.intervalo, s.dias, s.observacao, s.medicamento_id, s.data_criacao,
        m.nome as medicationName
      FROM tblMedicamentosAgendados s
      INNER JOIN tblMedicamentos m ON s.medicamento_id = m.id
      ORDER BY s.hora ASC
    ''');
    return result.map((json) => ScheduledMedication.fromMapWithMedication(json)).toList();
  }

  // Gera as doses do dia baseado nos medicamentos agendados
  Future<Map<String, List<TodayDose>>> getTodayDoses() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        s.id, s.hora, s.dose, s.intervalo, s.dias, s.observacao, s.medicamento_id, s.data_criacao,
        m.nome as medicationName
      FROM tblMedicamentosAgendados s
      INNER JOIN tblMedicamentos m ON s.medicamento_id = m.id
    ''');

    final List<ScheduledMedication> scheduledMedications = result.isNotEmpty 
        ? result.map((json) => ScheduledMedication.fromMapWithMedication(json)).toList() 
        : [];

    final Map<String, List<TodayDose>> groupedDoses = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var scheduled in scheduledMedications) {
      if (scheduled.dataCriacao == null) continue;
      
      try {
        final creationDate = DateTime.parse(scheduled.dataCriacao!);
        final endDate = creationDate.add(Duration(days: scheduled.dias));
        
        // Verifica se o medicamento ainda está ativo (dentro do período de dias)
        if (now.isBefore(endDate)) {
          // Parse da hora inicial
          final timeParts = scheduled.hora.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          
          // Calcula todas as doses do dia baseado no intervalo
          DateTime doseTime = today.add(Duration(hours: hour, minutes: minute));
          
          while (doseTime.day == today.day) {
            final timeKey = DateFormat('HH:mm').format(doseTime);
            
            final todayDose = TodayDose(
              scheduledMedicationId: scheduled.id!,
              medicationName: scheduled.medicationName!,
              dose: scheduled.dose,
              scheduledTime: doseTime,
              observacao: scheduled.observacao,
            );

            groupedDoses.putIfAbsent(timeKey, () => []).add(todayDose);
            
            // Próxima dose
            doseTime = doseTime.add(Duration(hours: scheduled.intervalo));
          }
        }
      } catch (e) {
        print('Erro ao processar medicamento agendado ${scheduled.id}: $e');
        continue;
      }
    }
    
    final sortedKeys = groupedDoses.keys.toList()..sort();
    return {for (var k in sortedKeys) k: groupedDoses[k]!};
  }
}
