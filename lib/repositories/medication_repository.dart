import 'package:me_alerte/model/medication_model.dart';
import 'package:sqflite/sqflite.dart';

class MedicationRepository {
  final Database db;

  MedicationRepository({required this.db});

  /// CREATE - Inserts a new medication into the database.
  Future<int> createMedication(MedicationModel medication) async {
    // The db.insert method returns the id of the newly inserted row.
    return await db.insert(
      MedicationModel.tableName,
      medication.toMap(),
      // In case the same medication is inserted twice, this will replace the previous data.
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// READ (Single) - Fetches a single medication by its ID.
  Future<MedicationModel?> getMedicationById(int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      MedicationModel.tableName,
      where: 'id = ?', // Use a 'where' clause to find a specific medication.
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return MedicationModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// READ (All) - Fetches all medications from the database.
  Future<List<MedicationModel>> listMedications() async {
    final List<Map<String, dynamic>> maps = await db.query(
      MedicationModel.tableName,
    );

    return List.generate(maps.length, (i) {
      return MedicationModel.fromMap(maps[i]);
    });
  }

  /// UPDATE - Modifies an existing medication's data.
  Future<int> updateMedication(MedicationModel medication) async {
    // The db.update method returns the number of rows affected.
    return await db.update(
      MedicationModel.tableName,
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  /// DELETE - Removes a medication from the database.
  Future<int> deleteMedication(int id) async {
    // The db.delete method returns the number of rows affected.
    return await db.delete(
      MedicationModel.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
