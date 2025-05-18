import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';
import 'package:ovarian_cyst_support_app/models/treatment_item.dart';
import 'package:ovarian_cyst_support_app/models/symptom_prediction.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ovarian_cyst_support.db');

    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    // Create symptom entries table
    await db.execute('''
      CREATE TABLE symptom_entries(
        id TEXT PRIMARY KEY,
        date TEXT,
        painLevel INTEGER,
        bloatingLevel INTEGER,
        mood TEXT,
        symptoms TEXT,
        notes TEXT,
        isUploaded INTEGER DEFAULT 0,
        updatedAt TEXT
      )
    ''');

    // Create medications table
    await db.execute('''
      CREATE TABLE medications(
        id TEXT PRIMARY KEY,
        name TEXT,
        dosage TEXT,
        frequency TEXT,
        time TEXT,
        startDate TEXT,
        endDate TEXT,
        notes TEXT,
        reminderEnabled INTEGER DEFAULT 0,
        isUploaded INTEGER DEFAULT 0,
        updatedAt TEXT
      )
    ''');

    // Create appointments table
    await db.execute('''
      CREATE TABLE appointments(
        id TEXT PRIMARY KEY,
        doctorName TEXT,
        doctorId TEXT,
        doctorSpecialty TEXT,
        purpose TEXT,
        dateTime TEXT,
        location TEXT,
        facilityName TEXT,
        facilityAddress TEXT,
        notes TEXT,
        reminderEnabled INTEGER DEFAULT 0,
        status TEXT DEFAULT 'scheduled',
        estimatedCost REAL,
        isPaid INTEGER DEFAULT 0,
        paymentReference TEXT,
        isUploaded INTEGER DEFAULT 0,
        updatedAt TEXT
      )
    ''');

    // Create community posts table
    await db.execute('''
      CREATE TABLE community_posts(
        id TEXT PRIMARY KEY,
        userId TEXT,
        userName TEXT,
        title TEXT,
        content TEXT,
        datePosted TEXT,
        likes INTEGER DEFAULT 0,
        commentCount INTEGER DEFAULT 0,
        isUploaded INTEGER DEFAULT 0,
        updatedAt TEXT
      )
    ''');

    // Create comments table
    await db.execute('''
      CREATE TABLE comments(
        id TEXT PRIMARY KEY,
        postId TEXT,
        userId TEXT,
        userName TEXT,
        content TEXT,
        datePosted TEXT,
        isUploaded INTEGER DEFAULT 0,
        updatedAt TEXT,
        FOREIGN KEY (postId) REFERENCES community_posts(id) ON DELETE CASCADE
      )
    ''');

    // Create treatment items table
    await db.execute('''
      CREATE TABLE treatment_items(
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT,
        description TEXT,
        cost REAL,
        requiresPrescription INTEGER DEFAULT 0,
        stockLevel INTEGER,
        facilityId TEXT,
        manufacturer TEXT,
        dosageInfo TEXT,
        sideEffects TEXT,
        isUploaded INTEGER DEFAULT 0,
        updatedAt TEXT
      )
    ''');

    // Create symptom predictions table
    await db.execute('''
      CREATE TABLE symptom_predictions(
        id TEXT PRIMARY KEY,
        predictionDate TEXT,
        severityScore REAL,
        riskLevel TEXT,
        potentialIssues TEXT,
        recommendation TEXT,
        requiresMedicalAttention INTEGER DEFAULT 0,
        isUploaded INTEGER DEFAULT 0,
        updatedAt TEXT
      )
    ''');

    // Create sync status table
    await db.execute('''
      CREATE TABLE sync_status(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entityType TEXT,
        entityId TEXT,
        syncStatus TEXT,
        lastSyncAttempt TEXT,
        syncError TEXT,
        UNIQUE(entityType, entityId)
      )
    ''');
  }

  // Symptom Entries
  Future<List<SymptomEntry>> getSymptomEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'symptom_entries',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return SymptomEntry.fromMap({
        'date': DateTime.parse(maps[i]['date']),
        'painLevel': maps[i]['painLevel'],
        'bloatingLevel': maps[i]['bloatingLevel'],
        'mood': maps[i]['mood'],
        'symptoms': (maps[i]['symptoms']).split(','),
        'notes': maps[i]['notes'],
      });
    });
  }

  Future<void> saveSymptomEntry(SymptomEntry entry) async {
    final db = await database;

    await db.insert('symptom_entries', {
      'id': entry.date.toIso8601String(),
      'date': entry.date.toIso8601String(),
      'painLevel': entry.painLevel,
      'bloatingLevel': entry.bloatingLevel,
      'mood': entry.mood,
      'symptoms': entry.symptoms.join(','),
      'notes': entry.notes,
      'isUploaded': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Add sync entry
    await _addToSyncQueue('symptom_entries', entry.date.toIso8601String());
  }

  Future<void> updateSymptomEntry(SymptomEntry entry) async {
    final db = await database;

    await db.update(
      'symptom_entries',
      {
        'painLevel': entry.painLevel,
        'bloatingLevel': entry.bloatingLevel,
        'mood': entry.mood,
        'symptoms': entry.symptoms.join(','),
        'notes': entry.notes,
        'isUploaded': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [entry.date.toIso8601String()],
    );

    // Update sync entry
    await _addToSyncQueue('symptom_entries', entry.date.toIso8601String());
  }

  Future<void> deleteSymptomEntry(SymptomEntry entry) async {
    final db = await database;

    await db.delete(
      'symptom_entries',
      where: 'id = ?',
      whereArgs: [entry.date.toIso8601String()],
    );

    // Remove from sync queue
    await _removeFromSyncQueue('symptom_entries', entry.date.toIso8601String());
  }

  // Medications
  Future<List<Map<String, dynamic>>> getMedications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      orderBy: 'startDate DESC',
    );
    return maps;
  }

  Future<void> saveMedication(Map<String, dynamic> medication) async {
    final db = await database;

    await db.insert(
      'medications',
      medication,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add sync entry
    await _addToSyncQueue('medications', medication['id']);
  }

  Future<void> updateMedication(
    String id,
    Map<String, dynamic> medication,
  ) async {
    final db = await database;

    await db.update(
      'medications',
      medication,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Update sync entry
    await _addToSyncQueue('medications', id);
  }

  Future<void> deleteMedication(String id) async {
    final db = await database;

    await db.delete('medications', where: 'id = ?', whereArgs: [id]);

    // Remove from sync queue
    await _removeFromSyncQueue('medications', id);
  }

  // Appointments
  Future<List<Appointment>> getAppointments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      orderBy: 'dateTime ASC',
    );

    return List.generate(maps.length, (i) {
      return Appointment.fromMap({
        'doctorName': maps[i]['doctorName'],
        'purpose': maps[i]['purpose'],
        'dateTime': DateTime.parse(maps[i]['dateTime']),
        'location': maps[i]['location'],
        'notes': maps[i]['notes'],
        'reminderEnabled': maps[i]['reminderEnabled'] == 1,
      });
    });
  }

  Future<List<Map<String, dynamic>>> getAppointmentsAsMap() async {
    final db = await database;
    return await db.query('appointments', orderBy: 'dateTime ASC');
  }

  Future<void> saveAppointment(Map<String, dynamic> appointmentMap) async {
    final db = await database;
    final id =
        appointmentMap['id'] ??
        '${appointmentMap['purpose']}_${DateTime.now().millisecondsSinceEpoch}';

    final Map<String, dynamic> dbMap = {
      'id': id,
      'doctorName': appointmentMap['doctorName'],
      'doctorId': appointmentMap['doctorId'] ?? '',
      'doctorSpecialty': appointmentMap['doctorSpecialty'] ?? '',
      'purpose': appointmentMap['purpose'],
      'dateTime': appointmentMap['dateTime'],
      'location': appointmentMap['location'],
      'facilityName': appointmentMap['facilityName'] ?? '',
      'facilityAddress': appointmentMap['facilityAddress'] ?? '',
      'notes': appointmentMap['notes'] ?? '',
      'reminderEnabled': appointmentMap['reminderEnabled'] == true ? 1 : 0,
      'status': appointmentMap['status'] ?? 'scheduled',
      'estimatedCost': appointmentMap['estimatedCost'],
      'isPaid': appointmentMap['isPaid'] == true ? 1 : 0,
      'paymentReference': appointmentMap['paymentReference'],
      'isUploaded': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'appointments',
      dbMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add sync entry
    await _addToSyncQueue('appointments', id);
  }

  Future<void> updateAppointment(
    String id,
    Map<String, dynamic> appointmentMap,
  ) async {
    final db = await database;

    final Map<String, dynamic> dbMap = {
      'doctorName': appointmentMap['doctorName'],
      'doctorId': appointmentMap['doctorId'] ?? '',
      'doctorSpecialty': appointmentMap['doctorSpecialty'] ?? '',
      'purpose': appointmentMap['purpose'],
      'dateTime': appointmentMap['dateTime'],
      'location': appointmentMap['location'],
      'facilityName': appointmentMap['facilityName'] ?? '',
      'facilityAddress': appointmentMap['facilityAddress'] ?? '',
      'notes': appointmentMap['notes'] ?? '',
      'reminderEnabled': appointmentMap['reminderEnabled'] == true ? 1 : 0,
      'status': appointmentMap['status'] ?? 'scheduled',
      'estimatedCost': appointmentMap['estimatedCost'],
      'isPaid': appointmentMap['isPaid'] == true ? 1 : 0,
      'paymentReference': appointmentMap['paymentReference'],
      'isUploaded': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await db.update('appointments', dbMap, where: 'id = ?', whereArgs: [id]);

    // Update sync entry
    await _addToSyncQueue('appointments', id);
  }

  Future<void> deleteAppointment(String id) async {
    final db = await database;

    await db.delete('appointments', where: 'id = ?', whereArgs: [id]);

    // Remove from sync queue
    await _removeFromSyncQueue('appointments', id);
  }

  // Treatment Items
  Future<List<TreatmentItem>> getTreatmentItems({String? facilityId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (facilityId != null) {
      maps = await db.query(
        'treatment_items',
        where: 'facilityId = ?',
        whereArgs: [facilityId],
      );
    } else {
      maps = await db.query('treatment_items');
    }

    return List.generate(maps.length, (i) {
      return TreatmentItem.fromJson({
        'id': maps[i]['id'],
        'name': maps[i]['name'],
        'type': maps[i]['type'],
        'description': maps[i]['description'],
        'cost': maps[i]['cost'],
        'requiresPrescription': maps[i]['requiresPrescription'] == 1,
        'stockLevel': maps[i]['stockLevel'],
        'facilityId': maps[i]['facilityId'],
        'manufacturer': maps[i]['manufacturer'],
        'dosageInfo': maps[i]['dosageInfo'],
        'sideEffects': maps[i]['sideEffects']?.split(','),
      });
    });
  }

  Future<void> saveTreatmentItem(TreatmentItem item) async {
    final db = await database;

    await db.insert('treatment_items', {
      'id': item.id,
      'name': item.name,
      'type': item.type.toString().split('.').last,
      'description': item.description,
      'cost': item.cost,
      'requiresPrescription': item.requiresPrescription ? 1 : 0,
      'stockLevel': item.stockLevel,
      'facilityId': item.facilityId,
      'manufacturer': item.manufacturer,
      'dosageInfo': item.dosageInfo,
      'sideEffects': item.sideEffects?.join(','),
      'isUploaded': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Add sync entry
    await _addToSyncQueue('treatment_items', item.id);
  }

  // Symptom Predictions
  Future<List<SymptomPrediction>> getSymptomPredictions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'symptom_predictions',
      orderBy: 'predictionDate DESC',
    );

    return List.generate(maps.length, (i) {
      return SymptomPrediction.fromJson({
        'predictionDate': maps[i]['predictionDate'],
        'severityScore': maps[i]['severityScore'],
        'riskLevel': maps[i]['riskLevel'],
        'potentialIssues': maps[i]['potentialIssues'].split(','),
        'recommendation': maps[i]['recommendation'],
        'requiresMedicalAttention': maps[i]['requiresMedicalAttention'] == 1,
      });
    });
  }

  // Get recent symptom entries with limit
  Future<List<SymptomEntry>> getRecentSymptomEntries({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'symptom_entries',
      orderBy: 'date DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return SymptomEntry.fromMap(maps[i]);
    });
  }

  // Get upcoming appointments
  Future<List<Appointment>> getUpcomingAppointments() async {
    final db = await database;
    final now = DateTime.now();
    final nowStr = now.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'dateTime > ?',
      whereArgs: [nowStr],
      orderBy: 'dateTime ASC',
    );

    return List.generate(maps.length, (i) {
      return Appointment.fromMap(maps[i]);
    });
  }

  Future<void> saveSymptomPrediction(SymptomPrediction prediction) async {
    final db = await database;
    final id = prediction.predictionDate.toIso8601String();

    await db.insert('symptom_predictions', {
      'id': id,
      'predictionDate': prediction.predictionDate.toIso8601String(),
      'severityScore': prediction.severityScore,
      'riskLevel': prediction.riskLevel,
      'potentialIssues': prediction.potentialIssues.join(','),
      'recommendation': prediction.recommendation,
      'requiresMedicalAttention': prediction.requiresMedicalAttention ? 1 : 0,
      'isUploaded': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Add sync entry
    await _addToSyncQueue('symptom_predictions', id);
  }

  // Sync Queue Management
  Future<void> _addToSyncQueue(String entityType, String entityId) async {
    final db = await database;

    await db.insert('sync_status', {
      'entityType': entityType,
      'entityId': entityId,
      'syncStatus': 'pending',
      'lastSyncAttempt': DateTime.now().toIso8601String(),
      'syncError': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _removeFromSyncQueue(String entityType, String entityId) async {
    final db = await database;

    await db.delete(
      'sync_status',
      where: 'entityType = ? AND entityId = ?',
      whereArgs: [entityType, entityId],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;

    return await db.query(
      'sync_status',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
    );
  }

  Future<void> updateSyncStatus(
    String entityType,
    String entityId,
    String status, {
    String? error,
  }) async {
    final db = await database;

    await db.update(
      'sync_status',
      {
        'syncStatus': status,
        'lastSyncAttempt': DateTime.now().toIso8601String(),
        'syncError': error,
      },
      where: 'entityType = ? AND entityId = ?',
      whereArgs: [entityType, entityId],
    );
  }

  Future<void> markAsUploaded(String table, String id) async {
    final db = await database;

    await db.update(table, {'isUploaded': 1}, where: 'id = ?', whereArgs: [id]);

    // Update sync status to success
    await updateSyncStatus(table, id, 'success');
  }

  // Database Migration and Management
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'ovarian_cyst_support.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<bool> checkDatabaseExists() async {
    String path = join(await getDatabasesPath(), 'ovarian_cyst_support.db');
    return await databaseExists(path);
  }

  Future<void> migrateFromSharedPreferences() async {
    // This method would migrate legacy data from SharedPreferences to SQLite
    // Would need to be implemented based on the structure of SharedPreferences data
    debugPrint('Migration from SharedPreferences to SQLite started');

    // Implementation would go here

    debugPrint('Migration from SharedPreferences to SQLite completed');
  }
}
