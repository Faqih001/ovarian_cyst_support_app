import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';
import 'package:ovarian_cyst_support_app/models/treatment_item.dart';
import 'package:ovarian_cyst_support_app/models/symptom_prediction.dart';
import 'package:ovarian_cyst_support_app/utils/database_config.dart';

class DatabaseMigrationService {
  static final _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Helper method to get the current user's collection reference
  CollectionReference _getUserCollection(String collectionName) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('No user logged in');
    }
    return _firestore.collection('users').doc(userId).collection(collectionName);
  }

  /// Migrates symptom entries from SQLite to Firestore
  Future<void> migrateSymptomEntries(List<SymptomEntry> entries) async {
    try {
      _logger.i('Starting symptom entries migration: ${entries.length} entries');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var entry in entries) {
        final docRef = _getUserCollection('symptomEntries').doc(entry.id);
        batch.set(docRef, entry.toMap());
        count++;
        
        // Firestore batches have a limit of 500 operations
        if (count >= 400) {
          await batch.commit();
          _logger.i('Committed batch of $count entries');
          count = 0;
        }
      }
      
      // Commit any remaining entries
      if (count > 0) {
        await batch.commit();
        _logger.i('Committed final batch of $count entries');
      }
      
      _logger.i('Symptom entries migration completed successfully');
    } catch (e) {
      _logger.e('Error migrating symptom entries: $e');
      rethrow;
    }
  }
  
  /// Migrates appointments from SQLite to Firestore
  Future<void> migrateAppointments(List<Appointment> appointments) async {
    try {
      _logger.i('Starting appointments migration: ${appointments.length} appointments');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var appointment in appointments) {
        final docRef = _getUserCollection('appointments').doc(appointment.id);
        batch.set(docRef, appointment.toMap());
        count++;
        
        // Firestore batches have a limit of 500 operations
        if (count >= 400) {
          await batch.commit();
          _logger.i('Committed batch of $count appointments');
          count = 0;
        }
      }
      
      // Commit any remaining appointments
      if (count > 0) {
        await batch.commit();
        _logger.i('Committed final batch of $count appointments');
      }
      
      _logger.i('Appointments migration completed successfully');
    } catch (e) {
      _logger.e('Error migrating appointments: $e');
      rethrow;
    }
  }
  
  /// Migrates medications from SQLite to Firestore
  Future<void> migrateMedications(List<Map<String, dynamic>> medications) async {
    try {
      _logger.i('Starting medications migration: ${medications.length} medications');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var medication in medications) {
        final docRef = _getUserCollection('medications').doc(medication['id']);
        batch.set(docRef, medication);
        count++;
        
        // Firestore batches have a limit of 500 operations
        if (count >= 400) {
          await batch.commit();
          _logger.i('Committed batch of $count medications');
          count = 0;
        }
      }
      
      // Commit any remaining medications
      if (count > 0) {
        await batch.commit();
        _logger.i('Committed final batch of $count medications');
      }
      
      _logger.i('Medications migration completed successfully');
    } catch (e) {
      _logger.e('Error migrating medications: $e');
      rethrow;
    }
  }
  
  /// Migrates payment attempts from SQLite to Firestore
  Future<void> migratePaymentAttempts(List<Map<String, dynamic>> payments) async {
    try {
      _logger.i('Starting payment attempts migration: ${payments.length} payments');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var payment in payments) {
        final docRef = _getUserCollection('paymentAttempts').doc(payment['id']);
        batch.set(docRef, payment);
        count++;
        
        // Firestore batches have a limit of 500 operations
        if (count >= 400) {
          await batch.commit();
          _logger.i('Committed batch of $count payments');
          count = 0;
        }
      }
      
      // Commit any remaining payments
      if (count > 0) {
        await batch.commit();
        _logger.i('Committed final batch of $count payments');
      }
      
      _logger.i('Payment attempts migration completed successfully');
    } catch (e) {
      _logger.e('Error migrating payment attempts: $e');
      rethrow;
    }
  }
  
  /// Migrates symptom predictions from SQLite to Firestore
  Future<void> migrateSymptomPredictions(List<SymptomPrediction> predictions) async {
    try {
      _logger.i('Starting symptom predictions migration: ${predictions.length} predictions');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var prediction in predictions) {
        final docRef = _getUserCollection('symptomPredictions').doc(prediction.id);
        batch.set(docRef, prediction.toMap());
        count++;
        
        // Firestore batches have a limit of 500 operations
        if (count >= 400) {
          await batch.commit();
          _logger.i('Committed batch of $count predictions');
          count = 0;
        }
      }
      
      // Commit any remaining predictions
      if (count > 0) {
        await batch.commit();
        _logger.i('Committed final batch of $count predictions');
      }
      
      _logger.i('Symptom predictions migration completed successfully');
    } catch (e) {
      _logger.e('Error migrating symptom predictions: $e');
      rethrow;
    }
  }
  
  /// Migrates treatment items from SQLite to Firestore
  Future<void> migrateTreatmentItems(List<TreatmentItem> items) async {
    try {
      _logger.i('Starting treatment items migration: ${items.length} items');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var item in items) {
        final docRef = _firestore.collection('treatmentItems').doc(item.id);
        batch.set(docRef, item.toMap());
        count++;
        
        // Firestore batches have a limit of 500 operations
        if (count >= 400) {
          await batch.commit();
          _logger.i('Committed batch of $count items');
          count = 0;
        }
      }
      
      // Commit any remaining items
      if (count > 0) {
        await batch.commit();
        _logger.i('Committed final batch of $count items');
      }
      
      _logger.i('Treatment items migration completed successfully');
    } catch (e) {
      _logger.e('Error migrating treatment items: $e');
      rethrow;
    }
  }

  /// Migrates community posts and their comments from SQLite to Firestore
  Future<void> migrateCommunityPosts(List<Map<String, dynamic>> posts) async {
    try {
      _logger.i('Starting community posts migration: ${posts.length} posts');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var post in posts) {
        // Get comments for this post
        final comments = await _getCommentsForPost(post['id']);
        
        // Add the post
        final postRef = _firestore.collection('communityPosts').doc(post['id']);
        batch.set(postRef, post);
        
        // Add all comments for this post
        for (var comment in comments) {
          final commentRef = postRef.collection('comments').doc(comment['id']);
          batch.set(commentRef, comment);
        }
        
        count++;
        
        // Firestore batches have a limit of 500 operations
        if (count >= 400) {
          await batch.commit();
          _logger.i('Committed batch of $count posts and their comments');
          count = 0;
        }
      }
      
      // Commit any remaining posts
      if (count > 0) {
        await batch.commit();
        _logger.i('Committed final batch of $count posts and their comments');
      }
      
      _logger.i('Community posts migration completed successfully');
    } catch (e) {
      _logger.e('Error migrating community posts: $e');
      rethrow;
    }
  }

  // Helper method to get comments for a post from SQLite
  Future<List<Map<String, dynamic>>> _getCommentsForPost(String postId) async {
    try {
      final db = await _getDatabaseInstance();
      final comments = await db.query(
        'comments',
        where: 'postId = ?',
        whereArgs: [postId],
      );
      return comments;
    } catch (e) {
      _logger.e('Error getting comments for post $postId: $e');
      return [];
    }
  }

  // Helper method to get database instance
  Future<Database> _getDatabaseInstance() async {
    final dbName = 'ovarian_cyst_support.db';
    final path = await DatabaseConfig.getDatabasePath(dbName);
    return await openDatabase(path);
  }
}
