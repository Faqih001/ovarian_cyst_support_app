import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/services/database_service_factory.dart';
import 'package:ovarian_cyst_support_app/services/database_migration_service.dart';

/// Service to handle database migration flow in the app
class MigrationService {
  static const String _migrationCompletedKey = 'firebase_migration_completed';
  static final Logger _logger = Logger();

  /// Check if the migration has been completed
  static Future<bool> isMigrationCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_migrationCompletedKey) ?? false;
    } catch (e) {
      _logger.e('Error checking migration status: $e');
      return false;
    }
  }

  /// Mark the migration as completed
  static Future<void> markMigrationCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationCompletedKey, true);
      await DatabaseServiceFactory.setUseFirestore(true);
    } catch (e) {
      _logger.e('Error marking migration as completed: $e');
    }
  }

  /// Reset migration status (for testing)
  static Future<void> resetMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationCompletedKey, false);
    } catch (e) {
      _logger.e('Error resetting migration status: $e');
    }
  }

  /// Automatically perform migration if needed without showing the screen
  static Future<void> checkAndShowMigrationScreen(BuildContext context) async {
    final migrationNeeded = await _isMigrationNeeded();
    if (migrationNeeded) {
      // Attempt automatic migration with retry mechanism
      await _performAutomaticMigrationWithRetry();
    }
  }

  /// Check if migration is needed
  static Future<bool> _isMigrationNeeded() async {
    final migrationCompleted = await isMigrationCompleted();
    final useFirestore = await DatabaseServiceFactory.shouldUseFirestore();
    return !migrationCompleted && !useFirestore;
  }

  /// Automatically perform the migration with retry mechanism
  static Future<void> _performAutomaticMigrationWithRetry() async {
    // Initial attempt
    final success = await _performAutomaticMigration();

    // If failed due to network/Firebase issues, schedule a retry for later
    if (!success) {
      _logger.i('Will retry migration later when Firebase is available');
      // We don't mark as completed so it will be retried on next app start
    }
  }

  /// Automatically perform the migration without user confirmation
  /// Returns true if migration was successful, false otherwise
  static Future<bool> _performAutomaticMigration() async {
    try {
      // Check if Firebase is initialized and available
      if (!await _isFirebaseAvailable()) {
        _logger.w('Firebase is not available, will try again later');
        return false;
      }

      // Create an instance of the migration service
      final migrationService = DatabaseMigrationService();

      // Run all migration tasks sequentially
      await migrationService.migrateSymptomEntries([]);
      await migrationService.migrateAppointments([]);
      await migrationService.migrateTreatmentItems([]);
      await migrationService.migrateMedications([]);
      await migrationService.migrateCommunityPosts([]);

      // Mark migration as complete when finished
      await markMigrationCompleted();

      _logger.i('Automatic migration completed successfully');
      return true;
    } catch (e) {
      _logger.e('Error during automatic migration: $e');
      // Only mark as completed if not a connectivity issue
      if (!_isConnectivityError(e)) {
        await markMigrationCompleted();
        return true;
      }
      return false;
    }
  }

  /// Check if the error is related to connectivity
  static bool _isConnectivityError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('socket') ||
        errorStr.contains('timeout') ||
        errorStr.contains('unavailable');
  }

  /// Check if Firebase is available and properly initialized
  static Future<bool> _isFirebaseAvailable() async {
    try {
      // Try to perform a simple Firebase operation
      // Check if Firebase is connected by checking if storage is accessible
      final connected = await DatabaseServiceFactory.isFirestoreAvailable();
      if (!connected) {
        _logger.w('Firebase is not connected, will retry later');
      }
      return connected;
    } catch (e) {
      _logger.e('Error checking Firebase availability: $e');
      return false;
    }
  }
}
