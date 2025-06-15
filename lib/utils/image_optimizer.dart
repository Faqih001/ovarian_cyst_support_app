import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Utility class to optimize images for better memory management
class ImageOptimizer {
  /// Resize and compress image bytes to reduce memory usage
  /// Returns the optimized image bytes
  static Future<Uint8List> optimizeImageBytes(
    Uint8List imageBytes, {
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
  }) async {
    try {
      // Try to decode the image safely
      img.Image? decodedImage;
      try {
        decodedImage = img.decodeImage(imageBytes);
      } catch (e) {
        debugPrint('Image decoding failed: $e');
        // Try with different decoders
        try {
          decodedImage = img.decodeJpg(imageBytes);
        } catch (e2) {
          try {
            decodedImage = img.decodePng(imageBytes);
          } catch (e3) {
            debugPrint('All image decoding attempts failed');
          }
        }
      }

      if (decodedImage == null) {
        debugPrint('Could not decode image, returning original');
        return imageBytes;
      }

      // Check if resizing is needed
      if (decodedImage.width > maxWidth || decodedImage.height > maxHeight) {
        // Calculate resize dimensions while maintaining aspect ratio
        final double aspectRatio = decodedImage.width / decodedImage.height;
        int resizedWidth, resizedHeight;

        if (decodedImage.width > decodedImage.height) {
          resizedWidth = maxWidth;
          resizedHeight = (maxWidth / aspectRatio).round();
        } else {
          resizedHeight = maxHeight;
          resizedWidth = (maxHeight * aspectRatio).round();
        }

        // Resize the image
        final img.Image resizedImage = img.copyResize(
          decodedImage,
          width: resizedWidth,
          height: resizedHeight,
        );

        // Encode as JPEG with specified quality
        return Uint8List.fromList(
          img.encodeJpg(resizedImage, quality: quality),
        );
      } else {
        // Just optimize quality if size is already acceptable
        return Uint8List.fromList(
          img.encodeJpg(decodedImage, quality: quality),
        );
      }
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      return imageBytes; // Return original if optimization fails
    }
  }

  /// Save image to temporary file with optimization
  /// Returns the path to the temporary file
  static Future<String?> saveToTemporaryFile(Uint8List imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/optimized_image_$timestamp.jpg');

      // Optimize before writing
      final optimizedBytes = await optimizeImageBytes(imageBytes);
      await tempFile.writeAsBytes(optimizedBytes);

      return tempFile.path;
    } catch (e) {
      debugPrint('Error saving optimized image: $e');
      return null;
    }
  }

  /// Clean up temporary image files
  static Future<void> cleanupTemporaryImages() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final directory = Directory(tempDir.path);
      final files = directory.listSync();

      for (final file in files) {
        if (file.path.contains('optimized_image_')) {
          await File(file.path).delete();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temporary images: $e');
    }
  }
}
