import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Helper class for platform-specific operations
class PlatformHelper {
  static final Logger _logger = Logger();

  /// Get temporary directory path in a cross-platform way
  static Future<String> getTemporaryPath() async {
    try {
      // Web doesn't have a real file system, so we return a virtual path
      if (kIsWeb) {
        return '/tmp';
      }
      // For mobile platforms, use actual temp directory
      final directory = await getTemporaryDirectory();
      return directory.path;
    } catch (e) {
      _logger.e('Error getting temporary directory: $e');
      // Provide a fallback path
      return kIsWeb ? '/tmp' : '/temporary';
    }
  }

  /// Check if running on web platform with better error handling
  static bool isWebPlatform() {
    return kIsWeb;
  }

  /// Get records audio format based on platform
  static String getAudioFormat() {
    return kIsWeb ? 'audio/webm' : 'audio/m4a';
  }

  /// Get records path for specific file in a cross-platform way
  static Future<String> getRecordingPath(String fileName) async {
    if (kIsWeb) {
      // Web doesn't use real file paths
      return fileName;
    }

    final tempPath = await getTemporaryPath();
    return '$tempPath/$fileName';
  }
}
