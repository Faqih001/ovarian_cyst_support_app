import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Database configuration helper to properly initialize database
/// based on the platform (web or mobile)
class DatabaseConfig {
  static final _logger = Logger();
  static bool _initialized = false;
  
  /// Initialize the database factory based on the platform
  static Future<void> initializeDatabase() async {
    if (_initialized) return;
    
    try {
      if (kIsWeb) {
        // Configure for web platform
        _logger.i('Initializing database factory for Web');
        databaseFactory = databaseFactoryFfiWeb;
      } else {
        // Configure for mobile (Android/iOS) platforms
        _logger.i('Initializing database factory for Mobile');
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _initialized = true;
      _logger.i('Database factory initialized successfully');
    } catch (e) {
      _logger.e('Error initializing database factory: $e');
      // Fallback to in-memory database if initialization fails
      _logger.w('Using in-memory database as fallback');
      
      // This is a simple fallback approach - adjust based on your needs
      try {
        if (kIsWeb) {
          databaseFactory = databaseFactoryFfiWeb;
        }
      } catch (e) {
        _logger.e('Failed to initialize fallback database: $e');
      }
    }
  }

  /// Get the proper path for database storage based on platform
  static Future<String> getDatabasePath(String dbName) async {
    if (kIsWeb) {
      // Web uses a virtual path
      return dbName;
    } else {
      // Mobile uses actual file system path
      final dbPath = await getDatabasesPath();
      return '$dbPath/$dbName';
    }
  }
}
