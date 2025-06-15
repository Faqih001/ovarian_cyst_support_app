import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class DatabaseConfig {
  static final Logger _logger = Logger();
  static FirebaseFirestore? _optimizedInstance;

  /// Initialize Firebase Firestore with the appropriate settings
  static Future<void> initializeFirestore() async {
    try {
      final instance = FirebaseFirestore.instance;

      if (kIsWeb) {
        // Web-specific settings
        instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        _logger.i('Initialized Firestore for web platform');
      } else {
        // Mobile and desktop settings with optimized performance
        instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          sslEnabled: true,
        );
        _logger.i('Initialized Firestore for non-web platform');
      }

      _optimizedInstance = instance;
    } catch (e) {
      _logger.e('Error initializing Firestore: $e');
      throw Exception('Failed to initialize Firestore: $e');
    }
  }

  /// Enable offline data persistence with optimized settings
  static Future<void> enableOfflinePersistence() async {
    try {
      final instance = _optimizedInstance ?? FirebaseFirestore.instance;

      if (!kIsWeb) {
        // Persistence is handled differently on web
        instance.settings = Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        _logger.i('Firestore offline persistence enabled');
      }
    } catch (e) {
      _logger.w('Persistence already enabled or not available: $e');
    }
  }

  /// Get the optimized Firestore instance for the current platform
  static FirebaseFirestore getOptimizedFirestore() {
    if (_optimizedInstance == null) {
      _logger.w(
          'Getting default Firestore instance - initializeFirestore() should be called first');
      return FirebaseFirestore.instance;
    }
    return _optimizedInstance!;
  }

  /// Clear cached Firestore instance and settings
  static void clearInstance() {
    _optimizedInstance = null;
  }
}
