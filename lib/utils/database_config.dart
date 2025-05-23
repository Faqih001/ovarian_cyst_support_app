import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;

class DatabaseConfig {
  static final Logger _logger = Logger();

  /// Get the path for the local SQLite database
  /// This is used during migration from SQLite to Firestore
  static Future<String> getDatabasePath(String dbName) async {
    try {
      if (kIsWeb) {
        return dbName;
      } else {
        final Directory appDocDir =
            await path_provider.getApplicationDocumentsDirectory();
        return path.join(appDocDir.path, dbName);
      }
    } catch (e) {
      _logger.e('Error getting database path: $e');
      throw Exception('Failed to get database path: $e');
    }
  }

  /// Initialize Firebase Firestore with the appropriate settings
  static Future<void> initializeFirestore() async {
    try {
      if (kIsWeb) {
        // Web-specific settings
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        _logger.i('Initialized Firestore for web platform');
      } else {
        // Mobile and desktop settings
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          sslEnabled: true,
        );
        _logger.i('Initialized Firestore for non-web platform');
      }
    } catch (e) {
      _logger.e('Error initializing Firestore: $e');
      throw Exception('Failed to initialize Firestore: $e');
    }
  }

  /// Enable offline data persistence
  static Future<void> enableOfflinePersistence() async {
    try {
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
      _logger.i('Firestore offline persistence enabled');
    } catch (e) {
      _logger.w('Persistence already enabled or not available: $e');
    }
  }

  /// Get the Firestore instance with optimal settings for the platform
  static FirebaseFirestore getOptimizedFirestore() {
    return FirebaseFirestore.instance;
  }
}
