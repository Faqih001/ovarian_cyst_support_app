import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ovarian_cyst_support_app/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  // Base URL for API (Express.js backend)
  static const String baseUrl = 'https://ovacare-backend.example.com/api';

  // Singleton instance
  static final SyncService _instance = SyncService._internal();

  factory SyncService() {
    return _instance;
  }

  SyncService._internal();

  // Database service
  final DatabaseService _databaseService = DatabaseService();

  // Authentication token (would be set after login)
  String? _authToken;

  // Sync in progress flag
  bool _isSyncing = false;

  // Last sync timestamp
  static const String _keyLastSyncTime = 'last_sync_time';

  // Setup sync service
  Future<void> initialize(String? authToken) async {
    _authToken = authToken;

    // Setup periodic sync if we have an auth token
    if (_authToken != null) {
      // Try to sync immediately if we have connectivity
      checkAndSync();

      // Setup periodic sync (every 30 minutes)
      Timer.periodic(const Duration(minutes: 30), (timer) {
        checkAndSync();
      });
    }
  }

  // Set auth token (e.g., after login)
  void setAuthToken(String token) {
    _authToken = token;

    // Try to sync immediately after getting a token
    checkAndSync();
  }

  // Check connectivity and sync if online
  Future<void> checkAndSync() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping...');
      return;
    }

    if (_authToken == null) {
      debugPrint('No auth token, skipping sync...');
      return;
    }

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('No internet connection, skipping sync...');
      return;
    }

    // Start sync
    await syncData();
  }

  // Manual sync trigger
  Future<bool> manualSync() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping manual sync...');
      return false;
    }

    if (_authToken == null) {
      debugPrint('No auth token, skipping manual sync...');
      return false;
    }

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('No internet connection, manual sync failed.');
      return false;
    }

    // Start sync
    final success = await syncData();
    return success;
  }

  // Main sync function
  Future<bool> syncData() async {
    _isSyncing = true;
    debugPrint('Starting data sync...');

    try {
      // 1. Get items that need to be synced
      final pendingItems = await _databaseService.getPendingSyncItems();
      debugPrint('Found ${pendingItems.length} items pending sync.');

      if (pendingItems.isEmpty) {
        _isSyncing = false;
        await _updateLastSyncTime();
        return true;
      }

      // 2. Group items by entity type for batch processing
      final Map<String, List<String>> itemsByType = {};
      for (var item in pendingItems) {
        final entityType = item['entityType'] as String;
        final entityId = item['entityId'] as String;

        if (!itemsByType.containsKey(entityType)) {
          itemsByType[entityType] = [];
        }

        itemsByType[entityType]!.add(entityId);
      }

      // 3. Process each entity type
      bool overallSuccess = true;

      for (var entry in itemsByType.entries) {
        final entityType = entry.key;
        final entityIds = entry.value;

        final success = await _syncEntityType(entityType, entityIds);
        if (!success) {
          overallSuccess = false;
        }
      }

      // 4. Update last sync time
      await _updateLastSyncTime();

      _isSyncing = false;
      debugPrint(
        'Data sync completed with status: ${overallSuccess ? 'success' : 'partial failure'}',
      );
      return overallSuccess;
    } catch (e) {
      _isSyncing = false;
      debugPrint('Error during data sync: $e');
      return false;
    }
  }

  // Sync entities of a specific type
  Future<bool> _syncEntityType(
    String entityType,
    List<String> entityIds,
  ) async {
    debugPrint('Syncing $entityType: ${entityIds.length} items');

    try {
      // Endpoint mapping
      final endpointMap = {
        'symptom_entries': '/symptom-entries',
        'medications': '/medications',
        'appointments': '/appointments',
        'treatment_items': '/treatment-items',
        'symptom_predictions': '/symptom-predictions',
        'community_posts': '/community',
        'comments': '/community/comments',
      };

      final endpoint = endpointMap[entityType];
      if (endpoint == null) {
        debugPrint('Unknown entity type: $entityType');
        return false;
      }

      // Get data from SQLite based on entity type and IDs
      final data = await _getEntityDataForSync(entityType, entityIds);

      // Send data to server
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint/sync'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
            body: jsonEncode({
              'data': data,
              'lastSyncTime': await getLastSyncTime(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Server processed our data
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Update local status for successfully synced items
        final List<dynamic> successfulIds = responseData['successfulIds'] ?? [];
        for (var id in successfulIds) {
          await _databaseService.markAsUploaded(entityType, id);
        }

        // Handle server sync responses - server may send back updated data
        if (responseData.containsKey('updatedData')) {
          await _handleServerUpdates(entityType, responseData['updatedData']);
        }

        return successfulIds.length == entityIds.length;
      } else {
        debugPrint('Server error during sync: ${response.statusCode}');

        // Mark sync failed for these items
        for (var id in entityIds) {
          await _databaseService.updateSyncStatus(
            entityType,
            id,
            'failed',
            error: 'Server error: ${response.statusCode}',
          );
        }

        return false;
      }
    } catch (e) {
      debugPrint('Error syncing $entityType: $e');

      // Mark sync failed for these items
      for (var id in entityIds) {
        await _databaseService.updateSyncStatus(
          entityType,
          id,
          'failed',
          error: 'Exception: $e',
        );
      }

      return false;
    }
  }

  // Get entity data for sync
  Future<List<Map<String, dynamic>>> _getEntityDataForSync(
    String entityType,
    List<String> entityIds,
  ) async {
    final db = await _databaseService.database;

    final List<Map<String, dynamic>> result = [];

    for (var id in entityIds) {
      final List<Map<String, dynamic>> items = await db.query(
        entityType,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (items.isNotEmpty) {
        result.add(items.first);
      }
    }

    return result;
  }

  // Handle server updates
  Future<void> _handleServerUpdates(
    String entityType,
    List<dynamic> updatedData,
  ) async {
    final db = await _databaseService.database;

    for (var item in updatedData) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final String id = data['id'];

      // Check if this item exists locally
      final existingItems = await db.query(
        entityType,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (existingItems.isEmpty) {
        // This is a new item, insert it
        data['isUploaded'] = 1; // Mark as already uploaded
        await db.insert(entityType, data);
      } else {
        // This is an update, only apply if server version is newer
        final localUpdatedAt = DateTime.parse(
          existingItems.first['updatedAt'] as String,
        );
        final serverUpdatedAt = DateTime.parse(data['updatedAt']);

        if (serverUpdatedAt.isAfter(localUpdatedAt)) {
          data['isUploaded'] = 1; // Mark as already uploaded
          await db.update(entityType, data, where: 'id = ?', whereArgs: [id]);
        }
      }
    }
  }

  // Update last sync time
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString(_keyLastSyncTime, now);
  }

  // Get last sync time
  Future<String?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastSyncTime);
  }

  // Clear sync status (e.g., on logout)
  Future<void> clearSyncStatus() async {
    _authToken = null;
    final db = await _databaseService.database;
    await db.delete('sync_status');
  }

  // Sync all data types at once
  Future<bool> syncAll() async {
    if (_authToken == null) {
      debugPrint('No auth token, skipping sync all...');
      return false;
    }

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('No internet connection, sync all failed.');
      return false;
    }

    try {
      _isSyncing = true;

      // Use the existing syncData method which handles all data types
      final success = await syncData();

      // Update last sync time
      await _updateLastSyncTime();

      return success;
    } catch (e) {
      debugPrint('Error during sync all: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // Get sync status summary
  Future<Map<String, dynamic>> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTime = prefs.getString(_keyLastSyncTime);

    final db = await _databaseService.database;

    // Get count of pending items
    final pendingCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM sync_status WHERE syncStatus = ?',
            ['pending'],
          ),
        ) ??
        0;

    // Get count of failed items
    final failedCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM sync_status WHERE syncStatus = ?',
            ['failed'],
          ),
        ) ??
        0;

    return {
      'lastSyncTime': lastSyncTime,
      'isSyncing': _isSyncing,
      'pendingCount': pendingCount,
      'failedCount': failedCount,
    };
  }
}
