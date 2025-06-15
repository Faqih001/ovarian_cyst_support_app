import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

enum SyncStatus { success, failed, pending }

class SyncService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if device has internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      // Check if we have an active internet connection
      return connectivityResults.isNotEmpty &&
          (connectivityResults.contains(ConnectivityResult.wifi) ||
              connectivityResults.contains(ConnectivityResult.mobile) ||
              connectivityResults.contains(ConnectivityResult.ethernet) ||
              connectivityResults.contains(ConnectivityResult.vpn));
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      return false;
    }
  }

  // Get user-specific collection
  CollectionReference _getUserCollection(String collection) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('No user logged in');
    }
    return _firestore.collection('users').doc(userId).collection(collection);
  }

  /// Start sync process
  Future<bool> syncData() async {
    if (_isSyncing) {
      _logger.w('Sync already in progress');
      return false;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      // Check connectivity
      if (!await _checkConnectivity()) {
        throw Exception('No internet connection');
      }

      // Get pending items
      final pendingItems = await _getPendingSyncItems();

      // Process items
      for (var item in pendingItems) {
        try {
          await _processSyncItem(item);
        } catch (e) {
          _logger.e('Error processing sync item: $e');
          await _markItemFailed(item.id);
        }
      }

      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();

      return true;
    } catch (e) {
      _logger.e('Error during sync: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Sync all data
  Future<bool> syncAll() async {
    return await syncData();
  }

  /// Manual sync request from user
  Future<bool> manualSync() async {
    return await syncData();
  }

  /// Clear sync queue
  Future<void> clearSyncQueue() async {
    final batch = _firestore.batch();
    final docs = await _getUserCollection('syncQueue').get();

    for (var doc in docs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Reset sync state
  Future<void> resetSync() async {
    _isSyncing = false;
    _lastSyncTime = null;
    notifyListeners();
  }

  /// Get items pending sync
  Future<List<QueryDocumentSnapshot>> _getPendingSyncItems() async {
    final querySnapshot = await _getUserCollection('syncQueue')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp')
        .limit(100)
        .get();

    return querySnapshot.docs;
  }

  /// Process a single sync item
  Future<void> _processSyncItem(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final collection = data['collection'] as String;
    final operation = data['operation'] as String;
    final itemData = data['data'] as Map<String, dynamic>;

    switch (operation) {
      case 'create':
        await _getUserCollection(collection).add(itemData);
        break;
      case 'update':
        await _getUserCollection(collection)
            .doc(itemData['id'])
            .update(itemData);
        break;
      case 'delete':
        await _getUserCollection(collection).doc(itemData['id']).delete();
        break;
      default:
        throw Exception('Unknown operation: $operation');
    }

    await _markItemComplete(doc.id);
  }

  /// Mark a sync item as complete
  Future<void> _markItemComplete(String itemId) async {
    await _getUserCollection('syncQueue').doc(itemId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark a sync item as failed
  Future<void> _markItemFailed(String itemId) async {
    await _getUserCollection('syncQueue').doc(itemId).update({
      'status': 'failed',
      'failedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add item to sync queue
  Future<void> queueSync({
    required String collection,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    await _getUserCollection('syncQueue').add({
      'collection': collection,
      'operation': operation,
      'data': data,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'retryCount': 0,
    });
  }

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    final pending = await _getUserCollection('syncQueue')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    final failed = await _getUserCollection('syncQueue')
        .where('status', isEqualTo: 'failed')
        .count()
        .get();

    return {
      'pending': pending.count ?? 0, // Add null check with default value of 0
      'failed': failed.count ?? 0, // Add null check with default value of 0
    };
  }
}
