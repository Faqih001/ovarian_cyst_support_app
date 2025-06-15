import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';
import 'package:ovarian_cyst_support_app/models/treatment_item.dart';
import 'package:ovarian_cyst_support_app/models/symptom_prediction.dart';

class DatabaseMigrationService {
  static final _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to get user's collection reference
  CollectionReference _getUserCollection(String collectionName) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('No user logged in');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName);
  }

  /// Migrate symptom entries
  Future<void> migrateSymptomEntries(List<SymptomEntry> entries) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserCollection('symptomEntries');

      for (var entry in entries) {
        final docRef = collection.doc();
        batch.set(docRef, entry.toMap());
      }

      await batch.commit();
      _logger.i('Successfully migrated ${entries.length} symptom entries');
    } catch (e) {
      _logger.e('Error migrating symptom entries: $e');
      rethrow;
    }
  }

  /// Migrate appointments
  Future<void> migrateAppointments(List<Appointment> appointments) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserCollection('appointments');

      for (var appointment in appointments) {
        final docRef = collection.doc();
        batch.set(docRef, appointment.toMap());
      }

      await batch.commit();
      _logger.i('Successfully migrated ${appointments.length} appointments');
    } catch (e) {
      _logger.e('Error migrating appointments: $e');
      rethrow;
    }
  }

  /// Migrate treatment items
  Future<void> migrateTreatmentItems(List<TreatmentItem> items) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserCollection('treatments');

      for (var item in items) {
        final docRef = collection.doc();
        batch.set(docRef, item.toMap());
      }

      await batch.commit();
      _logger.i('Successfully migrated ${items.length} treatment items');
    } catch (e) {
      _logger.e('Error migrating treatment items: $e');
      rethrow;
    }
  }

  /// Migrate symptom predictions
  Future<void> migratePredictions(List<SymptomPrediction> predictions) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserCollection('predictions');

      for (var prediction in predictions) {
        final docRef = collection.doc();
        batch.set(docRef, prediction.toMap());
      }

      await batch.commit();
      _logger.i('Successfully migrated ${predictions.length} predictions');
    } catch (e) {
      _logger.e('Error migrating predictions: $e');
      rethrow;
    }
  }

  /// Migrate medications
  Future<void> migrateMedications(
      List<Map<String, dynamic>> medications) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserCollection('medications');

      for (var medication in medications) {
        final docRef = collection.doc();
        batch.set(docRef, medication);
      }

      await batch.commit();
      _logger.i('Successfully migrated ${medications.length} medications');
    } catch (e) {
      _logger.e('Error migrating medications: $e');
      rethrow;
    }
  }

  /// Migrate payment attempts
  Future<void> migratePaymentAttempts(
      List<Map<String, dynamic>> attempts) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserCollection('paymentAttempts');

      for (var attempt in attempts) {
        final docRef = collection.doc();
        batch.set(docRef, {
          ...attempt,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _logger.i('Successfully migrated ${attempts.length} payment attempts');
    } catch (e) {
      _logger.e('Error migrating payment attempts: $e');
      rethrow;
    }
  }

  /// Migrate symptom predictions
  Future<void> migrateSymptomPredictions(
      List<SymptomPrediction> predictions) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserCollection('symptomPredictions');

      for (var prediction in predictions) {
        final docRef = collection.doc();
        batch.set(docRef, prediction.toMap());
      }

      await batch.commit();
      _logger
          .i('Successfully migrated ${predictions.length} symptom predictions');
    } catch (e) {
      _logger.e('Error migrating symptom predictions: $e');
      rethrow;
    }
  }

  /// Migrate community posts
  Future<void> migrateCommunityPosts(List<Map<String, dynamic>> posts) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserCollection('communityPosts');

      for (var post in posts) {
        final docRef = collection.doc();
        batch.set(docRef, {
          ...post,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _logger.i('Successfully migrated ${posts.length} community posts');
    } catch (e) {
      _logger.e('Error migrating community posts: $e');
      rethrow;
    }
  }

  /// Get total number of records migrated
  Future<Map<String, int>> getMigrationStats() async {
    final stats = <String, int>{};

    try {
      final collections = [
        'symptomEntries',
        'appointments',
        'treatments',
        'predictions'
      ];

      for (var collection in collections) {
        final snapshot = await _getUserCollection(collection).count().get();
        stats[collection] =
            snapshot.count ?? 0; // Add null check with default value of 0
      }

      return stats;
    } catch (e) {
      _logger.e('Error getting migration stats: $e');
      return {};
    }
  }
}
