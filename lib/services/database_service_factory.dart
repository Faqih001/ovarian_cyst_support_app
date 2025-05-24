import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/services/database_service.dart';
import 'package:ovarian_cyst_support_app/services/firestore_database_service.dart';

class DatabaseServiceFactory {
  static const String _dbChoiceKey = 'use_firestore_database';
  static final Logger _logger = Logger();
  static bool? _useFirestore;

  /// Checks if the app should use Firestore or SQLite
  /// Returns true if Firestore should be used, false otherwise.
  static Future<bool> shouldUseFirestore() async {
    if (_useFirestore != null) {
      return _useFirestore!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _useFirestore =
          prefs.getBool(_dbChoiceKey) ?? kIsWeb; // Default to Firestore on web
      return _useFirestore!;
    } catch (e) {
      _logger.e('Error checking database preference: $e');
      // Default to Firestore if there's an error
      return true;
    }
  }

  /// Sets the database preference to Firestore
  static Future<void> setUseFirestore(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dbChoiceKey, value);
      _useFirestore = value;
    } catch (e) {
      _logger.e('Error setting database preference: $e');
    }
  }

  /// Gets the appropriate database service based on the app's configuration.
  static Future<DatabaseService> getDatabaseService() async {
    // We're always using Firestore after migration
    await shouldUseFirestore(); // Just to update preferences if needed

    _logger.i('Using Firebase Firestore database service');
    return FirestoreDatabaseService();

    // SQLite is no longer supported after migration
  }

  /// Check if Firebase/Firestore is available and responsive
  static Future<bool> isFirestoreAvailable() async {
    try {
      // Get a reference to the database service
      final dbService = FirestoreDatabaseService();

      // Try to perform a simple operation to check connectivity
      await dbService.checkConnection();
      return true;
    } catch (e) {
      _logger.e('Firebase/Firestore is not available: $e');
      return false;
    }
  }

  /// Resets the cached database preference.
  static void resetCache() {
    _useFirestore = null;
    _logger.i('Database preference cache reset');
  }
}
