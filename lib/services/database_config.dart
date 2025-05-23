import 'package:flu      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        persistenceSettings: PersistenceSettings(synchronizeTabs: true),
      );/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
    // This is now only used for local file caching, not SQLite
    if (kIsWeb) {
      return 'cache/$fileName';
    }
    // For mobile platforms, you might want to use path_provider
    // to get the appropriate local storage path
    return 'cache/$fileName';
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
