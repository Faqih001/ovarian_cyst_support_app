import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class DatabaseConfig {
  static final Logger _logger = Logger();

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
