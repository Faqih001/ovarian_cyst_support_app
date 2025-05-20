import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class HealthcareFacility {
  final String id;
  final String name;
  final String type;
  final String owner;
  final String county;
  final String subCounty;
  final String location;
  final double latitude;
  final double longitude;
  final String? nearestTo;
  final String? division;

  HealthcareFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.owner,
    required this.county,
    required this.subCounty,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.nearestTo,
    this.division,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'owner': owner,
      'county': county,
      'subCounty': subCounty,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'nearestTo': nearestTo,
      'division': division,
    };
  }

  static HealthcareFacility fromCsvRow(List<dynamic> row) {
    return HealthcareFacility(
      id: row[0].toString(),
      name: row[1].toString(),
      type: row[2].toString(),
      owner: row[3].toString(),
      county: row[4].toString(),
      subCounty: row[5].toString(),
      division: row[6].toString().isNotEmpty ? row[6].toString() : null,
      location: row[7].toString(),
      latitude: double.tryParse(row[11].toString()) ?? 0.0,
      longitude: double.tryParse(row[12].toString()) ?? 0.0,
      nearestTo: row[10].toString().isNotEmpty ? row[10].toString() : null,
    );
  }
}

class FacilityService {
  static List<HealthcareFacility>? _facilities;

  Future<List<HealthcareFacility>> loadFacilities() async {
    if (_facilities != null) return _facilities!;

    try {
      final String csvContent =
          await rootBundle.loadString('assets/healthcare_facilities.csv');
      List<List<dynamic>> csvData = const CsvToListConverter()
          .convert(csvContent, shouldParseNumbers: false);

      // Remove header row
      csvData.removeAt(0);

      _facilities =
          csvData.map((row) => HealthcareFacility.fromCsvRow(row)).toList();
      return _facilities!;
    } catch (e) {
      debugPrint('Error loading facilities: $e');
      return [];
    }
  }

  Future<List<HealthcareFacility>> searchFacilities({
    String? query,
    String? county,
    String? type,
    double? latitude,
    double? longitude,
    double? maxDistance,
  }) async {
    final facilities = await loadFacilities();

    return facilities.where((facility) {
      bool matches = true;

      if (query != null && query.isNotEmpty) {
        matches = matches &&
            (facility.name.toLowerCase().contains(query.toLowerCase()) ||
                facility.location.toLowerCase().contains(query.toLowerCase()) ||
                facility.nearestTo
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ==
                    true);
      }

      if (county != null && county.isNotEmpty) {
        matches =
            matches && facility.county.toLowerCase() == county.toLowerCase();
      }

      if (type != null && type.isNotEmpty) {
        matches = matches && facility.type.toLowerCase() == type.toLowerCase();
      }

      if (latitude != null && longitude != null && maxDistance != null) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          facility.latitude,
          facility.longitude,
        );
        matches = matches && distance <= maxDistance;
      }

      return matches;
    }).toList();
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula for calculating distance between two points
    const double r = 6371; // Earth's radius in km
    final dlat = _toRad(lat2 - lat1);
    final dlon = _toRad(lon2 - lon1);
    final a = sin(dlat / 2) * sin(dlat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dlon / 2) * sin(dlon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  List<String> getAvailableCounties() {
    final counties = _facilities?.map((f) => f.county).toSet().toList() ?? [];
    counties.sort();
    return counties;
  }

  List<String> getAvailableFacilityTypes() {
    final types = _facilities?.map((f) => f.type).toSet().toList() ?? [];
    types.sort();
    return types;
  }
}
