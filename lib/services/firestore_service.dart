import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/user_profile.dart';
import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/models/medication.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';
import 'package:ovarian_cyst_support_app/models/community_post.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get posts => _firestore.collection('communityPosts');

  // User Profile Operations
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await users.doc(profile.uid).set(profile.toMap());
    } catch (e) {
      _logger.e('Error creating user profile: $e');
      throw e;
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await users.doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      _logger.e('Error getting user profile: $e');
      throw e;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await users.doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      throw e;
    }
  }

  // Medical Records Operations
  Future<void> addMedicalRecord(
      String userId, Map<String, dynamic> record) async {
    try {
      await users.doc(userId).collection('medicalRecords').add({
        ...record,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error adding medical record: $e');
      throw e;
    }
  }

  // Symptoms Tracking
  Stream<QuerySnapshot> getSymptomEntries(String userId) {
    return users
        .doc(userId)
        .collection('symptoms')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addSymptomEntry(
      String userId, Map<String, dynamic> entry) async {
    try {
      await users.doc(userId).collection('symptoms').add({
        ...entry,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error adding symptom entry: $e');
      throw e;
    }
  }

  // Appointments
  Stream<QuerySnapshot> getAppointments(String userId) {
    return users
        .doc(userId)
        .collection('appointments')
        .orderBy('date')
        .snapshots();
  }

  Future<void> addAppointment(
      String userId, Map<String, dynamic> appointment) async {
    try {
      await users.doc(userId).collection('appointments').add({
        ...appointment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error adding appointment: $e');
      throw e;
    }
  }

  // Community Posts
  Stream<QuerySnapshot> getCommunityPosts() {
    return posts.orderBy('createdAt', descending: true).limit(20).snapshots();
  }

  Future<void> createCommunityPost(Map<String, dynamic> post) async {
    try {
      await posts.add({
        ...post,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error creating community post: $e');
      throw e;
    }
  }

  // Offline Persistence Setup
  void enablePersistence() async {
    try {
      await _firestore.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
      _logger.i('Firestore persistence enabled');
    } catch (e) {
      _logger.w('Failed to enable persistence: $e');
    }
  }

  // Batch Operations
  Future<void> batchUpdate(List<Map<String, dynamic>> operations) async {
    final batch = _firestore.batch();
    try {
      for (var operation in operations) {
        final ref = operation['ref'] as DocumentReference;
        final data = operation['data'] as Map<String, dynamic>;
        batch.update(ref, data);
      }
      await batch.commit();
    } catch (e) {
      _logger.e('Error in batch update: $e');
      throw e;
    }
  }
}
