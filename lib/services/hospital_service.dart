import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/facility.dart';
import 'package:ovarian_cyst_support_app/models/doctor.dart';

class HospitalService {
  final String _baseUrl = 'http://api.kmhfl.health.go.ke/api';
  final Logger _logger = Logger();

  // API endpoints
  static const String _facilitiesEndpoint = '/facilities/facilities/';
  static const String _facilityDetailsEndpoint = '/facilities/facilities/';

  // Get facilities with optional filters
  Future<List<Facility>> getFacilities({
    String? searchQuery,
    String? county,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      Map<String, String> queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      if (county != null && county.isNotEmpty) {
        queryParams['county'] = county;
      }

      final Uri uri = Uri.parse('$_baseUrl$_facilitiesEndpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        return results
            .map((facilityData) => Facility.fromJson(facilityData))
            .toList();
      } else {
        _logger.e('Failed to load facilities: ${response.statusCode}');
        throw Exception('Failed to load facilities');
      }
    } catch (e) {
      _logger.e('Error fetching facilities: $e');
      throw Exception('Error fetching facilities: $e');
    }
  }

  // Get detailed information about a specific facility
  Future<Facility> getFacilityDetails(String facilityId) async {
    try {
      final Uri uri =
          Uri.parse('$_baseUrl$_facilityDetailsEndpoint$facilityId/');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Facility.fromJson(data);
      } else {
        _logger.e('Failed to load facility details: ${response.statusCode}');
        throw Exception('Failed to load facility details');
      }
    } catch (e) {
      _logger.e('Error fetching facility details: $e');
      throw Exception('Error fetching facility details: $e');
    }
  }

  // Get doctors for a specific facility
  Future<List<Doctor>> getDoctorsForFacility(String facilityId) async {
    try {
      // Note: This is an approximation as the actual endpoint for doctors might be different
      // Please adjust according to the actual API documentation
      final Uri uri =
          Uri.parse('$_baseUrl$_facilityDetailsEndpoint$facilityId/doctors/');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        return results
            .map((doctorData) => Doctor.fromJson(doctorData))
            .toList();
      } else {
        _logger.e('Failed to load doctors: ${response.statusCode}');
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      _logger.e('Error fetching doctors: $e');
      throw Exception('Error fetching doctors: $e');
    }
  }

  // Get list of counties in Kenya
  Future<List<String>> getCounties() async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/common/counties/');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        return results.map((county) => county['name'] as String).toList();
      } else {
        _logger.e('Failed to load counties: ${response.statusCode}');
        throw Exception('Failed to load counties');
      }
    } catch (e) {
      _logger.e('Error fetching counties: $e');
      throw Exception('Error fetching counties: $e');
    }
  }
}
