import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/utils/database_config.dart';

/// A generic data repository for interfacing with Firestore collections
class FirestoreRepository<T> {
  final Logger _logger = Logger();
  final String collectionPath;
  final T Function(Map<String, dynamic>) fromMap;
  final Map<String, dynamic> Function(T) toMap;

  FirebaseFirestore get _firestore => DatabaseConfig.getOptimizedFirestore();

  FirestoreRepository({
    required this.collectionPath,
    required this.fromMap,
    required this.toMap,
  });

  // Get current user ID
  String _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'guest_user';
  }

  // Get collection reference for personal data (user-specific)
  CollectionReference _getUserCollection() {
    return _firestore
        .collection('users')
        .doc(_getCurrentUserId())
        .collection(collectionPath);
  }

  // Get collection reference for global data (shared across users)
  CollectionReference _getGlobalCollection() {
    return _firestore.collection(collectionPath);
  }

  // Determine if this is user-specific data
  bool _isUserSpecific() {
    // These collections are typically user-specific
    return [
      'symptom_entries',
      'appointments',
      'medications',
      'payment_attempts',
      'symptom_predictions'
    ].contains(collectionPath);
  }

  // Get the appropriate collection reference
  CollectionReference _getCollectionRef() {
    return _isUserSpecific() ? _getUserCollection() : _getGlobalCollection();
  }

  // Add a new document
  Future<DocumentReference> add(T item) async {
    try {
      return await _getCollectionRef().add(toMap(item));
    } catch (e) {
      _logger.e('Error adding document to $collectionPath: $e');
      rethrow;
    }
  }

  // Set a document with specific ID
  Future<void> set(String id, T item) async {
    try {
      await _getCollectionRef().doc(id).set(toMap(item));
    } catch (e) {
      _logger.e('Error setting document $id in $collectionPath: $e');
      rethrow;
    }
  }

  // Get a document by ID
  Future<T?> get(String id) async {
    try {
      final doc = await _getCollectionRef().doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      _logger.e('Error getting document $id from $collectionPath: $e');
      return null;
    }
  }

  // Update a document
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _getCollectionRef().doc(id).update(data);
    } catch (e) {
      _logger.e('Error updating document $id in $collectionPath: $e');
      rethrow;
    }
  }

  // Delete a document
  Future<void> delete(String id) async {
    try {
      await _getCollectionRef().doc(id).delete();
    } catch (e) {
      _logger.e('Error deleting document $id from $collectionPath: $e');
      rethrow;
    }
  }

  // Get all documents
  Future<List<T>> getAll() async {
    try {
      final snapshot = await _getCollectionRef().get();
      return snapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting all documents from $collectionPath: $e');
      return [];
    }
  }

  // Query documents
  Future<List<T>> query({
    String? field,
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
  }) async {
    try {
      Query query = _getCollectionRef();

      if (field != null) {
        if (isEqualTo != null) {
          query = query.where(field, isEqualTo: isEqualTo);
        }
        if (isNotEqualTo != null) {
          query = query.where(field, isNotEqualTo: isNotEqualTo);
        }
        if (isLessThan != null) {
          query = query.where(field, isLessThan: isLessThan);
        }
        if (isLessThanOrEqualTo != null) {
          query = query.where(field, isLessThanOrEqualTo: isLessThanOrEqualTo);
        }
        if (isGreaterThan != null) {
          query = query.where(field, isGreaterThan: isGreaterThan);
        }
        if (isGreaterThanOrEqualTo != null) {
          query = query.where(field,
              isGreaterThanOrEqualTo: isGreaterThanOrEqualTo);
        }
        if (arrayContains != null) {
          query = query.where(field, arrayContains: arrayContains);
        }
        if (arrayContainsAny != null) {
          query = query.where(field, arrayContainsAny: arrayContainsAny);
        }
        if (whereIn != null) {
          query = query.where(field, whereIn: whereIn);
        }
        if (whereNotIn != null) {
          query = query.where(field, whereNotIn: whereNotIn);
        }
        if (isNull != null) {
          query = query.where(field, isNull: isNull);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error querying documents from $collectionPath: $e');
      return [];
    }
  }

  // Get real-time updates for a document
  Stream<T?> getStream(String id) {
    return _getCollectionRef().doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // Get real-time updates for a collection
  Stream<List<T>> getAllStream() {
    return _getCollectionRef().snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get real-time updates for a query
  Stream<List<T>> queryStream({
    String? field,
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
    String? orderBy,
    bool? descending,
  }) {
    Query query = _getCollectionRef();

    if (field != null) {
      if (isEqualTo != null) {
        query = query.where(field, isEqualTo: isEqualTo);
      }
      if (isNotEqualTo != null) {
        query = query.where(field, isNotEqualTo: isNotEqualTo);
      }
      if (isLessThan != null) {
        query = query.where(field, isLessThan: isLessThan);
      }
      if (isLessThanOrEqualTo != null) {
        query = query.where(field, isLessThanOrEqualTo: isLessThanOrEqualTo);
      }
      if (isGreaterThan != null) {
        query = query.where(field, isGreaterThan: isGreaterThan);
      }
      if (isGreaterThanOrEqualTo != null) {
        query =
            query.where(field, isGreaterThanOrEqualTo: isGreaterThanOrEqualTo);
      }
      if (arrayContains != null) {
        query = query.where(field, arrayContains: arrayContains);
      }
      if (arrayContainsAny != null) {
        query = query.where(field, arrayContainsAny: arrayContainsAny);
      }
      if (whereIn != null) {
        query = query.where(field, whereIn: whereIn);
      }
      if (whereNotIn != null) {
        query = query.where(field, whereNotIn: whereNotIn);
      }
      if (isNull != null) {
        query = query.where(field, isNull: isNull);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending ?? false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Handle transactions
  Future<void> runTransaction(
      Future<void> Function(Transaction) updateFunction) async {
    try {
      await _firestore.runTransaction((transaction) async {
        await updateFunction(transaction);
      });
    } catch (e) {
      _logger.e('Error running transaction in $collectionPath: $e');
      rethrow;
    }
  }

  // Handle batched writes
  Future<WriteBatch> batch() async {
    return _firestore.batch();
  }
}
