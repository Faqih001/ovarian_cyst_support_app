import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:ovarian_cyst_support_app/utils/platform_helper.dart';

class StorageService {
  static const int maxRetries = 3;
  static const Duration uploadTimeout = Duration(seconds: 30);
  static const Duration downloadTimeout = Duration(seconds: 20);
  static const Duration retryDelay = Duration(seconds: 2);

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  // Upload the CSV file from assets to Firebase Storage with retries
  Future<String?> uploadCsvFromAssets(
      String assetPath, String storagePath) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Load the CSV file from assets
        final ByteData data = await rootBundle.load(assetPath);
        final Uint8List bytes = data.buffer.asUint8List();

        // For Web platform, use different approach
        if (kIsWeb) {
          return await _uploadBytesToStorage(bytes, storagePath, 'text/csv');
        }

        // For mobile platforms
        // Create a temporary file with UTF-8 encoding
        final tempPath = await PlatformHelper.getTemporaryPath();
        final tempFile = File('$tempPath/temp_csv_file.csv');
        await tempFile.writeAsBytes(bytes);

        // Create the storage reference
        final ref = _storage.ref(storagePath);

        // Upload the file to Firebase Storage with metadata
        final metadata = SettableMetadata(
          contentType: 'text/csv',
          contentEncoding: 'utf-8',
          customMetadata: {
            'source': 'app_upload',
            'date': DateTime.now().toString(),
            'retryCount': retryCount.toString(),
          },
        );

        // Create a timeout for the upload
        final uploadTask = ref.putFile(tempFile, metadata);
        final snapshot = await uploadTask.timeout(
          uploadTimeout,
          onTimeout: () {
            _logger.w(
                'Upload timeout after ${uploadTimeout.inSeconds} seconds - cancelling');
            uploadTask.cancel();
            throw TimeoutException(
                'Upload timed out after ${uploadTimeout.inSeconds} seconds');
          },
        );

        // Get the download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        _logger.i('CSV file uploaded successfully: $downloadUrl');

        // Delete the temporary file
        await tempFile.delete();
        return downloadUrl;
      } on FirebaseException catch (e) {
        _logger.e(
            'Firebase Storage error (attempt ${retryCount + 1}): ${e.code} - ${e.message}');
        if (e.code == 'object-not-found' ||
            e.code == 'unauthorized' ||
            retryCount >= maxRetries - 1) {
          return null;
        }
      } catch (e) {
        _logger.e('Error uploading CSV file (attempt ${retryCount + 1}): $e');
        if (retryCount >= maxRetries - 1) {
          return null;
        }
      }

      retryCount++;
      if (retryCount < maxRetries) {
        _logger.i('Retrying upload in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      }
    }
    return null;
  }

  // Upload bytes directly to storage (Web compatible)
  Future<String?> _uploadBytesToStorage(
      Uint8List bytes, String storagePath, String contentType) async {
    try {
      // Create the storage reference
      final ref = _storage.ref(storagePath);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'source': 'web_upload',
          'date': DateTime.now().toString(),
        },
      );

      // Upload bytes
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask.timeout(
        uploadTimeout,
        onTimeout: () {
          _logger.w('Upload timeout after ${uploadTimeout.inSeconds} seconds');
          uploadTask.cancel();
          throw TimeoutException(
              'Upload timed out after ${uploadTimeout.inSeconds} seconds');
        },
      );

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      _logger.i('File uploaded successfully via web: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading bytes: $e');
      return null;
    }
  }

  // Download the CSV file from Firebase Storage with retries
  Future<String?> downloadCsvToString(String storagePath) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        if (kIsWeb) {
          // Web implementation: Get download URL and fetch via HTTP
          final downloadURL = await _storage.ref(storagePath).getDownloadURL();
          final response = await http.get(Uri.parse(downloadURL));
          if (response.statusCode == 200) {
            return utf8.decode(response.bodyBytes);
          } else {
            throw Exception('Failed to download file: ${response.statusCode}');
          }
        } else {
          // Mobile implementation
          // Create a temporary file
          final tempPath = await PlatformHelper.getTemporaryPath();
          final tempFile = File('$tempPath/downloaded_csv.csv');

          // Download to a temporary file with timeout
          final downloadTask = _storage.ref(storagePath).writeToFile(tempFile);
          await downloadTask.timeout(
            downloadTimeout,
            onTimeout: () {
              _logger.w(
                  'Download timeout after ${downloadTimeout.inSeconds} seconds');
              downloadTask.cancel();
              throw TimeoutException(
                  'Download timed out after ${downloadTimeout.inSeconds} seconds');
            },
          );

          // Read the file contents as string with UTF-8 encoding
          final String csvData = await tempFile.readAsString(encoding: utf8);

          // Delete the temporary file
          await tempFile.delete();
          return csvData;
        }
      } on FirebaseException catch (e) {
        _logger.e(
            'Firebase Storage error (attempt ${retryCount + 1}): ${e.code} - ${e.message}');
        if (e.code == 'object-not-found' ||
            e.code == 'unauthorized' ||
            retryCount >= maxRetries - 1) {
          return null;
        }
      } catch (e) {
        _logger.e('Error downloading CSV file (attempt ${retryCount + 1}): $e');
        if (retryCount >= maxRetries - 1) {
          return null;
        }
      }

      retryCount++;
      if (retryCount < maxRetries) {
        _logger.i('Retrying download in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      }
    }
    return null;
  }

  // Upload an image from path (works on mobile)
  Future<String?> uploadImage(File imageFile, String storagePath) async {
    if (kIsWeb) {
      _logger.e(
          'uploadImage with File is not supported on web. Use uploadImageBytes instead.');
      return null;
    }

    try {
      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'source': 'user_upload',
          'date': DateTime.now().toString()
        },
      );

      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _logger.i('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading image: $e');
      return null;
    }
  }

  // Upload image from XFile (compatible with both web and mobile)
  Future<String?> uploadImageFromXFile(
      XFile imageFile, String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);

      UploadTask uploadTask;
      TaskSnapshot snapshot;

      if (kIsWeb) {
        // For web, read as bytes and upload
        final imageBytes = await imageFile.readAsBytes();

        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'source': 'web_upload',
            'date': DateTime.now().toString()
          },
        );

        uploadTask = ref.putData(imageBytes, metadata);
      } else {
        // For mobile, can use the File path
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'source': 'mobile_upload',
            'date': DateTime.now().toString()
          },
        );

        uploadTask = ref.putFile(File(imageFile.path), metadata);
      }

      snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _logger.i('Image uploaded successfully from XFile: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading image from XFile: $e');
      return null;
    }
  }

  // Upload bytes (good for web)
  Future<String?> uploadImageBytes(Uint8List bytes, String storagePath) async {
    return _uploadBytesToStorage(bytes, storagePath, 'image/jpeg');
  }

  // Check if the file exists in Firebase Storage with retries
  Future<bool> fileExists(String storagePath) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        await _storage.ref(storagePath).getMetadata();
        return true;
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          return false;
        }
        _logger.e(
            'Firebase Storage error checking file (attempt ${retryCount + 1}): ${e.code} - ${e.message}');
      } catch (e) {
        _logger
            .e('Error checking file existence (attempt ${retryCount + 1}): $e');
      }

      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }
    return false;
  }

  // Delete a file from Firebase Storage
  Future<bool> deleteFile(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
      _logger.i('File deleted successfully: $storagePath');
      return true;
    } catch (e) {
      _logger.e('Error deleting file: $e');
      return false;
    }
  }
}
