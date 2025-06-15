import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// Database configuration helper to properly initialize Firestore
/// based on the platform (web or mobile)
class DatabaseConfig {
  static final _logger = Logger();
  static bool _initialized = false;

  /// Initialize Firestore with the appropriate settings
  static Future<void> initializeDatabase() async {
    if (_initialized) return;

    try {
      _logger.i('Initializing Firestore for ${kIsWeb ? 'Web' : 'Mobile'}');

      // Initialize Firestore settings
      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );

      _initialized = true;
      _logger.i('Firestore initialized successfully');
    } catch (e) {
      _logger.e('Error initializing Firestore: $e');
      throw Exception('Failed to initialize Firestore: $e');
    }
  }

  /// Get the path for any local files needed by the app
  static Future<String> getDatabasePath(String fileName) async {
    if (kIsWeb) {
      return 'cache/$fileName';
    }

    // For mobile platforms, use path_provider to get the app's documents directory
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    return '${appDir.path}/$fileName';
  }

  /// Clear any cached data
  static Future<void> clearCache() async {
    try {
      await FirebaseFirestore.instance.clearPersistence();
      _logger.i('Cache cleared successfully');
    } catch (e) {
      _logger.e('Error clearing cache: $e');
      throw Exception('Failed to clear cache: $e');
    }
  }
}
