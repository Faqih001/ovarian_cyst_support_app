import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';
import 'package:ovarian_cyst_support_app/models/treatment_item.dart';
import 'package:ovarian_cyst_support_app/models/symptom_prediction.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ovarian_cyst_support_app/services/database_service.dart';

class FirestoreDatabaseService extends DatabaseService {
  static final FirestoreDatabaseService _instance =
      FirestoreDatabaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  bool _initialized = false;

  // Collection names
  static const String _symptomEntriesCollection = 'symptom_entries';
  static const String _appointmentsCollection = 'appointments';
  static const String _medicationsCollection = 'medications';
  static const String _paymentAttemptsCollection = 'payment_attempts';
  static const String _communityPostsCollection = 'community_posts';
  static const String _commentsCollection = 'comments';
  static const String _treatmentItemsCollection = 'treatment_items';
  static const String _symptomPredictionsCollection = 'symptom_predictions';
  static const String _usersCollection = 'users';

  factory FirestoreDatabaseService() {
    return _instance;
  }

  FirestoreDatabaseService._internal();

  @override
  Future<void> initialize() async {
    if (!_initialized) {
      // Enable offline persistence if not already enabled
      try {
        // Initialize settings with persistence
        FirebaseFirestore.instance.settings = Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          // Updated to support newer Firebase version
        );
      } catch (e) {
        _logger.w('Persistence already enabled or not available: $e');
      }
      _initialized = true;
    }
  }

  /// Check if Firestore connection is available by making a simple query
  Future<bool> checkConnection() async {
    try {
      // Attempt a simple, lightweight operation
      // Use a timeout to avoid waiting too long if Firebase is unavailable
      await _firestore
          .collection('_connection_test')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      _logger.w('Firestore connection check failed: $e');
      return false;
    }
  }

  // Get the current user's ID or a default ID for testing
  String _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'guest_user';
  }

  // Get a reference to the user's document
  DocumentReference _getUserDocument() {
    return _firestore.collection(_usersCollection).doc(_getCurrentUserId());
  }

  // Get a collection reference to a subcollection of the current user
  CollectionReference _getUserCollection(String collectionName) {
    return _getUserDocument().collection(collectionName);
  }

  // SYMPTOM ENTRIES

  Future<void> insertSymptomEntry(SymptomEntry entry) async {
    try {
      await _getUserCollection(_symptomEntriesCollection)
          .doc(entry.id)
          .set(entry.toMap());
    } catch (e) {
      _logger.e('Error inserting symptom entry: $e');
      throw Exception('Failed to insert symptom entry: $e');
    }
  }

  @override
  Future<List<SymptomEntry>> getSymptomEntries() async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(_symptomEntriesCollection)
              .orderBy('date', descending: true)
              .get();

      return snapshot.docs
          .map(
              (doc) => SymptomEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting symptom entries: $e');
      return [];
    }
  }

  Future<SymptomEntry?> getSymptomEntryById(String id) async {
    try {
      final DocumentSnapshot doc =
          await _getUserCollection(_symptomEntriesCollection).doc(id).get();

      if (doc.exists) {
        return SymptomEntry.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting symptom entry by ID: $e');
      return null;
    }
  }

  Future<void> updateSymptomEntry(SymptomEntry entry) async {
    try {
      await _getUserCollection(_symptomEntriesCollection)
          .doc(entry.id)
          .update(entry.toMap());
    } catch (e) {
      _logger.e('Error updating symptom entry: $e');
      throw Exception('Failed to update symptom entry: $e');
    }
  }

  Future<void> deleteSymptomEntry(String id) async {
    try {
      await _getUserCollection(_symptomEntriesCollection).doc(id).delete();
    } catch (e) {
      _logger.e('Error deleting symptom entry: $e');
      throw Exception('Failed to delete symptom entry: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTodaysSymptoms() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final QuerySnapshot snapshot =
          await _getUserCollection(_symptomEntriesCollection)
              .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
              .where('timestamp', isLessThan: endOfDay)
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Error getting today\'s symptoms: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSymptomEntries() async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(_symptomEntriesCollection)
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Error getting all symptom entries: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentSymptomEntries() async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(_symptomEntriesCollection)
              .orderBy('timestamp', descending: true)
              .limit(7) // Get only the most recent 7 entries
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Error getting recent symptom entries: $e');
      return [];
    }
  }

  // APPOINTMENTS

  Future<void> insertAppointment(Appointment appointment) async {
    try {
      await _getUserCollection(_appointmentsCollection)
          .doc(appointment.id)
          .set(appointment.toMap());
    } catch (e) {
      _logger.e('Error inserting appointment: $e');
      throw Exception('Failed to insert appointment: $e');
    }
  }

  Future<List<Appointment>> getAppointments() async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(_appointmentsCollection)
              .orderBy('dateTime', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => Appointment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting appointments: $e');
      return [];
    }
  }

  Future<Appointment?> getAppointmentById(String id) async {
    try {
      final DocumentSnapshot doc =
          await _getUserCollection(_appointmentsCollection).doc(id).get();

      if (doc.exists) {
        return Appointment.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting appointment by ID: $e');
      return null;
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _getUserCollection(_appointmentsCollection)
          .doc(appointment.id)
          .update(appointment.toMap());
    } catch (e) {
      _logger.e('Error updating appointment: $e');
      throw Exception('Failed to update appointment: $e');
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      await _getUserCollection(_appointmentsCollection).doc(id).delete();
    } catch (e) {
      _logger.e('Error deleting appointment: $e');
      throw Exception('Failed to delete appointment: $e');
    }
  }

  @override
  Future<List<dynamic>> getUpcomingAppointments() async {
    try {
      final now = DateTime.now();
      final QuerySnapshot snapshot =
          await _getUserCollection(_appointmentsCollection)
              .where('dateTime', isGreaterThanOrEqualTo: now)
              .orderBy('dateTime')
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Appointment.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      _logger.e('Error getting upcoming appointments: $e');
      return [];
    }
  }

  @override
  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _getUserCollection(_appointmentsCollection)
          .doc(appointmentId)
          .update({
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error updating appointment status: $e');
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // MEDICATIONS

  Future<void> insertMedication(Map<String, dynamic> medication) async {
    try {
      await _getUserCollection(_medicationsCollection)
          .doc(medication['id'])
          .set(medication);
    } catch (e) {
      _logger.e('Error inserting medication: $e');
      throw Exception('Failed to insert medication: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMedications() async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(_medicationsCollection).get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Error getting medications: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMedicationById(String id) async {
    try {
      final DocumentSnapshot doc =
          await _getUserCollection(_medicationsCollection).doc(id).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _logger.e('Error getting medication by ID: $e');
      return null;
    }
  }

  Future<void> updateMedication(
      String id, Map<String, dynamic> medication) async {
    try {
      await _getUserCollection(_medicationsCollection)
          .doc(id)
          .update(medication);
    } catch (e) {
      _logger.e('Error updating medication: $e');
      throw Exception('Failed to update medication: $e');
    }
  }

  @override
  Future<void> deleteMedication(String id) async {
    try {
      await _getUserCollection(_medicationsCollection).doc(id).delete();
    } catch (e) {
      _logger.e('Error deleting medication: $e');
      throw Exception('Failed to delete medication: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllMedications() async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(_medicationsCollection)
              .orderBy('name')
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Error getting all medications: $e');
      return [];
    }
  }

  @override
  Future<void> saveMedication(Map<String, dynamic> medication) async {
    try {
      if (medication.containsKey('id') && medication['id'] != null) {
        // Update existing medication
        await _getUserCollection(_medicationsCollection)
            .doc(medication['id'])
            .update(medication);
      } else {
        // Add new medication
        await _getUserCollection(_medicationsCollection).add(medication);
      }
    } catch (e) {
      _logger.e('Error saving medication: $e');
      throw Exception('Failed to save medication: $e');
    }
  }

  // PAYMENT ATTEMPTS

  Future<void> insertPaymentAttempt(Map<String, dynamic> payment) async {
    try {
      await _getUserCollection(_paymentAttemptsCollection)
          .doc(payment['id'])
          .set(payment);
    } catch (e) {
      _logger.e('Error inserting payment attempt: $e');
      throw Exception('Failed to insert payment attempt: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentAttemptsByAppointmentId(
      String appointmentId) async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(_paymentAttemptsCollection)
              .where('appointmentId', isEqualTo: appointmentId)
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Error getting payment attempts: $e');
      return [];
    }
  }

  // COMMUNITY POSTS

  Future<void> insertCommunityPost(Map<String, dynamic> post) async {
    try {
      final DocumentReference postRef =
          _firestore.collection(_communityPostsCollection).doc(post['id']);
      await postRef.set(post);
    } catch (e) {
      _logger.e('Error inserting community post: $e');
      throw Exception('Failed to insert community post: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCommunityPosts() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_communityPostsCollection)
          .orderBy('datePosted', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Error getting community posts: $e');
      return [];
    }
  }

  // COMMENTS

  Future<void> insertComment(Map<String, dynamic> comment) async {
    try {
      final DocumentReference commentRef = _firestore
          .collection(_communityPostsCollection)
          .doc(comment['postId'])
          .collection(_commentsCollection)
          .doc(comment['id']);

      await commentRef.set(comment);

      // Update comment count
      await _firestore
          .collection(_communityPostsCollection)
          .doc(comment['postId'])
          .update({'commentCount': FieldValue.increment(1)});
    } catch (e) {
      _logger.e('Error inserting comment: $e');
      throw Exception('Failed to insert comment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCommentsByPostId(String postId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_communityPostsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .orderBy('datePosted', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Error getting comments: $e');
      return [];
    }
  }

  // TREATMENT ITEMS

  Future<void> insertTreatmentItem(TreatmentItem item) async {
    try {
      await _firestore
          .collection(_treatmentItemsCollection)
          .doc(item.id)
          .set(item.toMap());
    } catch (e) {
      _logger.e('Error inserting treatment item: $e');
      throw Exception('Failed to insert treatment item: $e');
    }
  }

  @override
  Future<void> saveTreatmentItem(TreatmentItem item) async {
    try {
      await _firestore
          .collection(_treatmentItemsCollection)
          .doc(item.id)
          .set(item.toMap(), SetOptions(merge: true));
      _logger.i('Treatment item saved: ${item.id}');
    } catch (e) {
      _logger.e('Error saving treatment item: $e');
      throw Exception('Failed to save treatment item: $e');
    }
  }

  @override
  Future<List<TreatmentItem>> getTreatmentItems({String? facilityId}) async {
    try {
      Query query = _firestore.collection(_treatmentItemsCollection);

      // Add facility filter if provided
      if (facilityId != null) {
        query = query.where('facilityId', isEqualTo: facilityId);
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) =>
              TreatmentItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting treatment items: $e');
      return [];
    }
  }

  // SYMPTOM PREDICTIONS

  Future<void> insertSymptomPrediction(SymptomPrediction prediction) async {
    try {
      await _getUserCollection(_symptomPredictionsCollection)
          .doc(prediction.id)
          .set(prediction.toMap());
    } catch (e) {
      _logger.e('Error inserting symptom prediction: $e');
      throw Exception('Failed to insert symptom prediction: $e');
    }
  }

  @override
  Future<void> saveSymptomPrediction(Map<String, dynamic> prediction) async {
    try {
      await _getUserCollection(_symptomPredictionsCollection)
          .doc(prediction['id'])
          .set(prediction);
    } catch (e) {
      _logger.e('Error saving symptom prediction: $e');
      throw Exception('Failed to save symptom prediction: $e');
    }
  }

  @override
  Future<List<SymptomPrediction>> getSymptomPredictions() async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(_symptomPredictionsCollection)
              .orderBy('predictionDate', descending: true)
              .get();

      return snapshot.docs
          .map((doc) =>
              SymptomPrediction.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting symptom predictions: $e');
      return [];
    }
  }

  // DATA SYNC UTILITIES

  Future<void> markAsUploaded(String collection, String id) async {
    try {
      await _getUserCollection(collection).doc(id).update({
        'isUploaded': 1,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Error marking document as uploaded: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNonUploadedItems(
      String collection) async {
    try {
      final QuerySnapshot snapshot = await _getUserCollection(collection)
          .where('isUploaded', isEqualTo: 0)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Error getting non-uploaded items: $e');
      return [];
    }
  }

  @override
  Future<void> logSymptom(Map<String, dynamic> symptom) async {
    try {
      await _getUserCollection(_symptomEntriesCollection).doc().set({
        ...symptom,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error logging symptom: $e');
      throw Exception('Failed to log symptom: $e');
    }
  }
}
