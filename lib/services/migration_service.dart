import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/screens/database_migration_screen.dart';
import 'package:ovarian_cyst_support_app/services/database_service_factory.dart';

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

  /// Show the migration screen if needed
  static Future<void> checkAndShowMigrationScreen(BuildContext context) async {
    final migrationNeeded = await _isMigrationNeeded();
    if (migrationNeeded && context.mounted) {
      await _showMigrationScreen(context);
    }
  }

  /// Check if migration is needed
  static Future<bool> _isMigrationNeeded() async {
    final migrationCompleted = await isMigrationCompleted();
    final useFirestore = await DatabaseServiceFactory.shouldUseFirestore();
    return !migrationCompleted && !useFirestore;
  }

  /// Show the migration screen
  static Future<void> _showMigrationScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DatabaseMigrationScreen(),
      ),
    );
  }
}
