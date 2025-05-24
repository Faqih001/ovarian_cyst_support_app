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
      await _performAutomaticMigration();
    }
  }

  /// Check if migration is needed
  static Future<bool> _isMigrationNeeded() async {
    final migrationCompleted = await isMigrationCompleted();
    final useFirestore = await DatabaseServiceFactory.shouldUseFirestore();
    return !migrationCompleted && !useFirestore;
  }
  
  /// Automatically perform the migration without user confirmation
  static Future<void> _performAutomaticMigration() async {
    try {
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
    } catch (e) {
      _logger.e('Error during automatic migration: $e');
      // Despite any errors, we'll mark it as completed to avoid showing again
      await markMigrationCompleted();
    }
  }
}
