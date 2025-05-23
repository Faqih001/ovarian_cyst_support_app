
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/services/firestore_database_service.dart';

/// DatabaseProvider is a factory class that provides the appropriate database service
/// implementation based on the app's configuration.
class DatabaseProvider {
  static final Logger _logger = Logger();
  static FirestoreDatabaseService? _instance;

  /// Gets the instance of the database service.
  /// Returns a Firebase Firestore implementation.
  static Future<FirestoreDatabaseService> getInstance() async {
    if (_instance == null) {
      _logger.i('Initializing Firebase Database Service');
      _instance = FirestoreDatabaseService();
      await _instance!.initialize();
    }
    return _instance!;
  }

  /// Resets the database instance.
  /// This is useful for testing or when you need to reinitialize the database.
  static void resetInstance() {
    _instance = null;
    _logger.i('Database instance reset');
  }
}
