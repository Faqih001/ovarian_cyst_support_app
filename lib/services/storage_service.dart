import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  // Upload the CSV file from assets to Firebase Storage
  Future<String?> uploadCsvFromAssets(
      String assetPath, String storagePath) async {
    try {
      // Load the CSV file from assets
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_csv_file.csv');
      await tempFile.writeAsBytes(bytes);

      // Create the storage reference
      final ref = _storage.ref(storagePath);

      // Upload the file to Firebase Storage with metadata
      final metadata = SettableMetadata(
        contentType: 'text/csv',
        customMetadata: {
          'source': 'app_upload',
          'date': DateTime.now().toString()
        },
      );

      // Create a timeout for the upload to prevent hanging
      final uploadTask = ref.putFile(tempFile, metadata);
      final snapshot =
          await uploadTask.timeout(const Duration(seconds: 15), onTimeout: () {
        _logger.w('Upload timeout - cancelling');
        uploadTask.cancel();
        throw TimeoutException('Upload timed out after 15 seconds');
      }).whenComplete(() {
        _logger.i('Upload task completed or timed out');
      });

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      _logger.i('CSV file uploaded successfully: $downloadUrl');

      // Delete the temporary file
      await tempFile.delete();

      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('Firebase Storage error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Error uploading CSV file to Firebase Storage: $e');
      return null;
    }
  }

  // Download the CSV file from Firebase Storage
  Future<String?> downloadCsvToString(String storagePath) async {
    try {
      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/downloaded_csv.csv');

      // Download to a temporary file
      await _storage.ref(storagePath).writeToFile(tempFile);

      // Read the file contents as string
      final String csvData = await tempFile.readAsString();

      // Delete the temporary file
      await tempFile.delete();

      return csvData;
    } catch (e) {
      _logger.e('Error downloading CSV file from Firebase Storage: $e');
      return null;
    }
  }

  // Check if the file exists in Firebase Storage
  Future<bool> fileExists(String storagePath) async {
    try {
      await _storage.ref(storagePath).getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }
}
