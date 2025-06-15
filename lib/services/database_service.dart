import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/treatment_item.dart';
import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/models/symptom_prediction.dart';

/// Base class for Firebase database operations
abstract class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  String get userId => _auth.currentUser?.uid ?? '';

  /// Initialize the database service
  Future<void> initialize();

  /// Get a collection reference with the user's ID in the path
  CollectionReference getUserCollection(String collection) {
    if (userId.isEmpty) {
      throw Exception('No user logged in');
    }
    return _firestore.collection('users').doc(userId).collection(collection);
  }

  /// Get treatment items with optional facilityId filter
  Future<List<TreatmentItem>> getTreatmentItems({String? facilityId});

  /// Save a treatment item to the database
  Future<void> saveTreatmentItem(TreatmentItem item);

  /// Clear all data for testing
  @visibleForTesting
  Future<void> clearAllData() async {
    if (!kDebugMode) {
      throw Exception('clearAllData can only be called in debug mode');
    }

    try {
      final batch = _firestore.batch();
      final collections = [
        'symptom_entries',
        'appointments',
        'medications',
        'treatment_items',
        'community_posts',
        'symptom_predictions',
        'payment_attempts',
      ];

      for (var collection in collections) {
        final querySnapshot = await getUserCollection(collection).get();
        for (var doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
      _logger.i('All data cleared successfully');
    } catch (e) {
      _logger.e('Error clearing data: $e');
      rethrow;
    }
  }

  /// Check if database exists
  Future<bool> databaseExists() async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final doc = await userDoc.get();
      return doc.exists;
    } catch (e) {
      _logger.e('Error checking database existence: $e');
      return false;
    }
  }

  /// Close connection (no-op for Firestore as it manages its own connections)
  Future<void> close() async {
    // No need to close Firestore connections
  }

  /// Get today's symptoms
  Future<List<Map<String, dynamic>>> getTodaysSymptoms();

  /// Get all symptom entries
  Future<List<Map<String, dynamic>>> getAllSymptomEntries();

  /// Get all medications
  Future<List<Map<String, dynamic>>> getAllMedications();

  /// Log a symptom
  Future<void> logSymptom(Map<String, dynamic> symptom);

  /// Get upcoming appointments
  Future<List<dynamic>> getUpcomingAppointments();

  /// Update appointment status
  Future<void> updateAppointmentStatus(String appointmentId, String status);

  /// Get recent symptom entries
  Future<List<Map<String, dynamic>>> getRecentSymptomEntries();

  /// Get symptom entries for AI prediction
  Future<List<SymptomEntry>> getSymptomEntries();

  /// Get symptom predictions history
  Future<List<SymptomPrediction>> getSymptomPredictions();

  /// Save a symptom prediction
  Future<void> saveSymptomPrediction(Map<String, dynamic> prediction);

  /// Get medications
  Future<List<Map<String, dynamic>>> getMedications();

  /// Save medication
  Future<void> saveMedication(Map<String, dynamic> medication);

  /// Delete medication
  Future<void> deleteMedication(String id);
}
