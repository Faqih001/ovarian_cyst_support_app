import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

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

        // Create a temporary file with UTF-8 encoding
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_csv_file.csv');
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

  // Download the CSV file from Firebase Storage with retries
  Future<String?> downloadCsvToString(String storagePath) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Create a temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/downloaded_csv.csv');

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
}
