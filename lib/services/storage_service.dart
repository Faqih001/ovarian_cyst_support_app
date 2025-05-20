import 'dart:io';
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

      // Upload the file to Firebase Storage
      final uploadTask = _storage.ref(storagePath).putFile(tempFile);
      final snapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      _logger.i('CSV file uploaded successfully: $downloadUrl');

      // Delete the temporary file
      await tempFile.delete();

      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading CSV file to Firebase Storage: $e');
      return null;
    }
  }

  // Download the CSV file from Firebase Storage
  Future<String?> downloadCsvToString(String storagePath) async {
    try {
      // Get the download URL
      final downloadUrl = await _storage.ref(storagePath).getDownloadURL();

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
