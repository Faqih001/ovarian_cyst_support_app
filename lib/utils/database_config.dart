import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;

class DatabaseConfig {
  static Future<void> initializeDatabase() async {
    if (kIsWeb) {
      // Initialize for web
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // Initialize for desktop
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // For Android and iOS, the default databaseFactory is used
  }

  static Future<String> getDatabasePath(String dbName) async {
    if (kIsWeb) {
      return dbName;
    } else {
      final Directory appDocDir =
          await path_provider.getApplicationDocumentsDirectory();
      return path.join(appDocDir.path, dbName);
    }
  }
}
