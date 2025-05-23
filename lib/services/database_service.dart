import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Base class for Firebase database operations
abstract class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  String get userId => _auth.currentUser?.uid ?? '';

  /// Get a collection reference with the user's ID in the path
  CollectionReference getUserCollection(String collection) {
    if (userId.isEmpty) {
      throw Exception('No user logged in');
    }
    return _firestore.collection('users').doc(userId).collection(collection);
  }

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
}
