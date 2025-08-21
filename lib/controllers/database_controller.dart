import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:app_remedio/models/medication_model.dart';
import 'package:app_remedio/models/treatment_model.dart';
import 'package:intl/intl.dart';

class DatabaseController {
  static final DatabaseController instance = DatabaseController._init();
  static Database? _database;
  DatabaseController._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_remedio_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabela de catálogo de medicamentos (estoque)
    await db.execute('''
      CREATE TABLE medicamentos ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        nome TEXT NOT NULL UNIQUE,
        quantidade_estoque INTEGER NOT NULL,
        observacao TEXT
      )
    ''');

    // Tabela com as prescrições de tratamento
    await db.execute('''
      CREATE TABLE tratamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicamento_id INTEGER NOT NULL,
        dose TEXT NOT NULL,
        data_hora_inicio TEXT NOT NULL,
        intervalo_horas INTEGER NOT NULL,
        duracao_dias INTEGER NOT NULL,
        FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id) ON DELETE CASCADE
      )
    ''');

    // Tabela para registrar o histórico de doses tomadas
    await db.execute('''
      CREATE TABLE doses_historico (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tratamento_id INTEGER NOT NULL,
        horario_previsto TEXT NOT NULL,
        horario_real_tomado TEXT NOT NULL,
        status TEXT NOT NULL, 
        FOREIGN KEY (tratamento_id) REFERENCES tratamentos (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- MÉTODOS PARA MEDICAMENTOS (ESTOQUE) ---
  Future<Medication> createMedication(Medication medication) async {
    final db = await instance.database;
    final id = await db.insert('medicamentos', medication.toMap());
    return medication.copyWith(id: id);
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await instance.database;
    final result = await db.query('medicamentos', orderBy: 'nome ASC');
    return result.map((json) => Medication.fromMap(json)).toList();
  }

  // --- MÉTODOS PARA TRATAMENTOS ---
  Future<Treatment> createTreatment(Treatment treatment) async {
    final db = await instance.database;
    final id = await db.insert('tratamentos', treatment.toMap());
    return treatment.copyWith(id: id);
  }
  
  // --- MÉTODOS PARA HISTÓRICO DE DOSES ---
  Future<void> markDoseAsTaken(int treatmentId, DateTime scheduledTime) async {
    final db = await instance.database;
    await db.insert('doses_historico', {
      'tratamento_id': treatmentId,
      'horario_previsto': scheduledTime.toIso8601String(),
      'horario_real_tomado': DateTime.now().toIso8601String(),
      'status': 'TOMADO'
    });
  }

  Future<Set<String>> getTakenDosesForToday() async {
      final db = await instance.database;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      final result = await db.query(
          'doses_historico',
          where: 'horario_previsto >= ? AND horario_previsto <= ?',
          whereArgs: [todayStart, todayEnd]
      );

      // Cria um conjunto de chaves únicas para fácil verificação (ex: "1_2025-08-20T14:00:00.000")
      return result.map((row) => '${row['tratamento_id']}_${row['horario_previsto']}').toSet();
  }


  // LÓGICA PRINCIPAL: Gera as doses do dia e agrupa por horário
  Future<Map<String, List<ScheduledDose>>> getGroupedScheduledDosesForToday() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT
        t.id as treatmentId, t.dose, t.data_hora_inicio, t.intervalo_horas, t.duracao_dias,
        m.nome as medicationName
      FROM tratamentos t
      INNER JOIN medicamentos m ON t.medicamento_id = m.id
    ''');

    final List<Treatment> treatments = result.isNotEmpty 
        ? result.map((json) => Treatment.fromMapWithMedication(json)).toList() 
        : [];

    final takenDoses = await getTakenDosesForToday();
    final Map<String, List<ScheduledDose>> groupedDoses = {};

    for (var treatment in treatments) {
      final startDate = DateTime.parse(treatment.dataHoraInicio);
      final endDate = startDate.add(Duration(days: treatment.duracaoDias));

      if (now.isBefore(endDate)) {
        DateTime currentDoseTime = startDate;
        while (currentDoseTime.isBefore(endDate)) {
          if (currentDoseTime.isAfter(todayStart) && currentDoseTime.isBefore(todayEnd)) {
            final timeKey = DateFormat('HH:mm').format(currentDoseTime);
            final doseKey = '${treatment.id}_${currentDoseTime.toIso8601String()}';

            final scheduledDose = ScheduledDose(
              treatmentId: treatment.id!,
              medicationName: treatment.medicationName!,
              dose: treatment.dose,
              scheduledTime: currentDoseTime,
              isTaken: takenDoses.contains(doseKey),
            );

            groupedDoses.putIfAbsent(timeKey, () => []).add(scheduledDose);
          }
          currentDoseTime = currentDoseTime.add(Duration(hours: treatment.intervaloHoras));
        }
      }
    }
    
    final sortedKeys = groupedDoses.keys.toList()..sort();
    return {for (var k in sortedKeys) k: groupedDoses[k]!};
  }
}
