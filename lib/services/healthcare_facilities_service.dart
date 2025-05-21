import 'dart:async';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:logger/logger.dart';

class HealthcareFacilitiesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Load and store CSV data in Firestore (should be called only once during setup)
  Future<void> importCsvToFirestore() async {
    try {
      // Check if data already exists
      final snapshot =
          await _firestore.collection('healthcare_facilities').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        _logger.i('Healthcare facilities data already exists in Firestore');
        return;
      }

      // Load CSV from assets
      final String csvData =
          await rootBundle.loadString('assets/healthcare_facilities.csv');
      final List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvData);

      // Get headers from first row
      final headers = csvTable[0].map((e) => e.toString().trim()).toList();

      // Convert remaining rows to documents
      final batch = _firestore.batch();
      for (var i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        final Map<String, dynamic> data = {};

        // Create document data using headers as keys
        for (var j = 0; j < headers.length; j++) {
          if (j < row.length) {
            data[headers[j]] = row[j];
          }
        }

        // Add to batch
        final docRef = _firestore.collection('healthcare_facilities').doc();
        batch.set(docRef, data);
      }

      // Commit the batch
      await batch.commit();
      _logger
          .i('Successfully imported healthcare facilities data to Firestore');
    } catch (e) {
      _logger.e('Error importing healthcare facilities data to Firestore: $e');
      throw Exception('Failed to import healthcare facilities data');
    }
  }

  // Get all healthcare facilities
  Future<List<Map<String, dynamic>>> getAllFacilities() async {
    try {
      final snapshot =
          await _firestore.collection('healthcare_facilities').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.e('Error fetching healthcare facilities: $e');
      throw Exception('Failed to fetch healthcare facilities');
    }
  }

  // Search facilities by name or location
  Future<List<Map<String, dynamic>>> searchFacilities(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot =
          await _firestore.collection('healthcare_facilities').get();

      return snapshot.docs
          .map((doc) => doc.data())
          .where((facility) =>
              facility['name'].toString().toLowerCase().contains(queryLower) ||
              facility['location']
                  .toString()
                  .toLowerCase()
                  .contains(queryLower))
          .toList();
    } catch (e) {
      _logger.e('Error searching healthcare facilities: $e');
      throw Exception('Failed to search healthcare facilities');
    }
  }

  // Get facilities by region/area
  Future<List<Map<String, dynamic>>> getFacilitiesByRegion(
      String region) async {
    try {
      final snapshot = await _firestore
          .collection('healthcare_facilities')
          .where('region', isEqualTo: region)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.e('Error fetching facilities by region: $e');
      throw Exception('Failed to fetch facilities by region');
    }
  }
}
