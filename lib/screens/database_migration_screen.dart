import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';
import 'package:ovarian_cyst_support_app/models/treatment_item.dart';
import 'package:ovarian_cyst_support_app/models/symptom_prediction.dart';
import 'package:ovarian_cyst_support_app/services/database_migration_service.dart';
import 'package:ovarian_cyst_support_app/services/database_service.dart';
import 'package:ovarian_cyst_support_app/services/migration_service.dart';

class DatabaseMigrationScreen extends StatefulWidget {
  const DatabaseMigrationScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseMigrationScreen> createState() => _DatabaseMigrationScreenState();
}

class _DatabaseMigrationScreenState extends State<DatabaseMigrationScreen> {
  final Logger _logger = Logger();
  final DatabaseMigrationService _migrationService = DatabaseMigrationService();
  final DatabaseService _oldDatabase = DatabaseService();
  
  bool _isLoading = false;
  String _statusMessage = 'Ready to migrate data from SQLite to Firebase.';
  double _progress = 0.0;
  int _totalTasks = 7; // Updated to include community posts
  int _completedTasks = 0;
  
  void _updateProgress() {
    setState(() {
      _completedTasks++;
      _progress = _completedTasks / _totalTasks;
    });
  }
  
  Future<void> _migrateData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting migration...';
      _progress = 0.0;
      _completedTasks = 0;
    });
    
    try {
      // Make sure database is initialized
      await _oldDatabase.initialize();
      
      // Migrate symptom entries
      setState(() => _statusMessage = 'Migrating symptom entries...');
      final symptomEntries = await _fetchSymptomEntries();
      await _migrationService.migrateSymptomEntries(symptomEntries);
      _updateProgress();
      
      // Migrate appointments
      setState(() => _statusMessage = 'Migrating appointments...');
      final appointments = await _fetchAppointments();
      await _migrationService.migrateAppointments(appointments);
      _updateProgress();
      
      // Migrate medications
      setState(() => _statusMessage = 'Migrating medications...');
      final medications = await _fetchMedications();
      await _migrationService.migrateMedications(medications);
      _updateProgress();
      
      // Migrate payment attempts
      setState(() => _statusMessage = 'Migrating payment attempts...');
      final paymentAttempts = await _fetchPaymentAttempts();
      await _migrationService.migratePaymentAttempts(paymentAttempts);
      _updateProgress();
      
      // Migrate symptom predictions
      setState(() => _statusMessage = 'Migrating symptom predictions...');
      final symptomPredictions = await _fetchSymptomPredictions();
      await _migrationService.migrateSymptomPredictions(symptomPredictions);
      _updateProgress();
      
      // Migrate treatment items
      setState(() => _statusMessage = 'Migrating treatment items...');
      final treatmentItems = await _fetchTreatmentItems();
      await _migrationService.migrateTreatmentItems(treatmentItems);
      _updateProgress();

      // Migrate community posts and comments
      setState(() => _statusMessage = 'Migrating community posts and comments...');
      final communityPosts = await _fetchCommunityPosts();
      await _migrationService.migrateCommunityPosts(communityPosts);
      _updateProgress();
      
      setState(() {
        _statusMessage = 'Migration completed successfully!';
        _isLoading = false;
      });

      // Mark migration as completed
      await MigrationService.markMigrationCompleted();
      
    } catch (e) {
      _logger.e('Error during migration: $e');
      setState(() {
        _statusMessage = 'Error during migration: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<List<SymptomEntry>> _fetchSymptomEntries() async {
    try {
      final db = await _oldDatabase.database;
      final results = await db.query('symptom_entries');
      return results.map((e) => SymptomEntry.fromMap(e)).toList();
    } catch (e) {
      _logger.e('Error fetching symptom entries: $e');
      return [];
    }
  }
  
  Future<List<Appointment>> _fetchAppointments() async {
    try {
      final db = await _oldDatabase.database;
      final results = await db.query('appointments');
      return results.map((e) => Appointment.fromMap(e)).toList();
    } catch (e) {
      _logger.e('Error fetching appointments: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> _fetchMedications() async {
    try {
      final db = await _oldDatabase.database;
      return await db.query('medications');
    } catch (e) {
      _logger.e('Error fetching medications: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> _fetchPaymentAttempts() async {
    try {
      final db = await _oldDatabase.database;
      return await db.query('payment_attempts');
    } catch (e) {
      _logger.e('Error fetching payment attempts: $e');
      return [];
    }
  }
  
  Future<List<SymptomPrediction>> _fetchSymptomPredictions() async {
    try {
      final db = await _oldDatabase.database;
      final results = await db.query('symptom_predictions');
      return results.map((e) => SymptomPrediction.fromMap(e)).toList();
    } catch (e) {
      _logger.e('Error fetching symptom predictions: $e');
      return [];
    }
  }
  
  Future<List<TreatmentItem>> _fetchTreatmentItems() async {
    try {
      final db = await _oldDatabase.database;
      final results = await db.query('treatment_items');
      return results.map((e) => TreatmentItem.fromMap(e)).toList();
    } catch (e) {
      _logger.e('Error fetching treatment items: $e');
      return [];
    }
  }

  // Add helper method to fetch community posts
  Future<List<Map<String, dynamic>>> _fetchCommunityPosts() async {
    try {
      final db = await _oldDatabase.database;
      return await db.query('community_posts');
    } catch (e) {
      _logger.e('Error fetching community posts: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Migration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Migration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool will migrate your data from SQLite to Firebase Firestore. '
                      'This process might take some time depending on the amount of data.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _migrateData,
              child: _isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Migrating Data...'),
                      ],
                    )
                  : const Text('Start Migration'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const Spacer(),
            const Text(
              'Note: This migration is a one-time process. After migration, the app will use Firebase Firestore for all data storage.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
