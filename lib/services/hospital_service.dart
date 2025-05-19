import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/facility.dart';
import 'package:ovarian_cyst_support_app/models/doctor.dart';

enum FacilityType {
  public,
  private
}

class HospitalService {
  // Kenya Master Facility List API URL for public hospitals
  final String _baseUrl = 'https://api.kmhfl.health.go.ke/api/v1';
  
  // CKAN Data API URL for private hospitals
  final String _ckanBaseUrl = 'https://energydata.info/api/3/action';
  
  // Resource ID for Kenyan private hospitals (replace with actual resource ID)
  final String _privateHospitalsResourceId = '841097c2-9424-4c90-b1e7-8e942a817c3c';
  
  final Logger _logger = Logger();
  
  // API endpoints
  static const String _facilitiesEndpoint = '/facilities/';
  static const String _facilityDetailsEndpoint = '/facilities/';
  static const String _countiesEndpoint = '/counties/';
  
  // API key (if required - check API documentation)
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add API key or auth token if required
    // 'Authorization': 'Bearer YOUR_API_TOKEN',
  };  

  // Get facilities from either public or private sources
  Future<List<Facility>> getFacilities({
    String? searchQuery,
    String? county,
    int page = 1,
    int pageSize = 20,
    FacilityType facilityType = FacilityType.public,
  }) async {
    if (facilityType == FacilityType.private) {
      return getPrivateFacilities(searchQuery: searchQuery, county: county, limit: pageSize);
    } else {
      return getPublicFacilities(searchQuery: searchQuery, county: county, page: page, pageSize: pageSize);
    }
  }

  // Get public facilities with optional filters
  Future<List<Facility>> getPublicFacilities({
    String? searchQuery,
    String? county,
    int page = 1,
    int pageSize = 20,
  }) async {
    // This is the original implementation for public facilities
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
      
      _logger.i('Fetching public facilities from: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> results = data['results'] ?? [];
          
          return results
              .map((facilityData) => Facility.fromJson(facilityData))
              .toList();
        } catch (e) {
          _logger.e('Error parsing facility data: $e');
          return _getMockFacilities(searchQuery, county);
        }
      } else {
        _logger.e('Failed to load facilities: ${response.statusCode}');
        return _getMockFacilities(searchQuery, county);
      }
    } catch (e) {
      _logger.e('Error fetching facilities: $e');
      return _getMockFacilities(searchQuery, county);
    }
  }

  // Get private facilities using CKAN API
  Future<List<Facility>> getPrivateFacilities({
    String? searchQuery,
    String? county,
    int limit = 20,
  }) async {
    try {
      Map<String, String> queryParams = {
        'resource_id': _privateHospitalsResourceId,
        'limit': limit.toString(),
      };
      
      // Add search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }
      
      // For county filter, we'll use SQL query if county is provided
      if (county != null && county.isNotEmpty) {
        final Uri sqlUri = Uri.parse('$_ckanBaseUrl/datastore_search_sql');
        final String sqlQuery = 'SELECT * FROM "$_privateHospitalsResourceId" WHERE county LIKE \'%$county%\' LIMIT $limit';
        
        final Uri uri = sqlUri.replace(
          queryParameters: {'sql': sqlQuery},
        );
        
        _logger.i('Fetching private facilities with SQL from: $uri');
        
        final response = await http.get(uri);
        
        if (response.statusCode == 200) {
          return _parseCkanResponse(response.body);
        } else {
          _logger.e('Failed to load private facilities: ${response.statusCode}');
          return _getMockPrivateFacilities(searchQuery, county);
        }
      } else {
        // Regular search without county filter
        final Uri uri = Uri.parse('$_ckanBaseUrl/datastore_search').replace(
          queryParameters: queryParams,
        );
        
        _logger.i('Fetching private facilities from: $uri');
        
        final response = await http.get(uri);
        
        if (response.statusCode == 200) {
          return _parseCkanResponse(response.body);
        } else {
          _logger.e('Failed to load private facilities: ${response.statusCode}');
          return _getMockPrivateFacilities(searchQuery, county);
        }
      }
    } catch (e) {
      _logger.e('Error fetching private facilities: $e');
      return _getMockPrivateFacilities(searchQuery, county);
    }
  }
  
  // Parse CKAN API response
  List<Facility> _parseCkanResponse(String responseBody) {
    try {
      final Map<String, dynamic> data = json.decode(responseBody);
      
      if (data['success'] == true && data['result'] != null) {
        final List<dynamic> records = data['result']['records'] ?? [];
        
        return records.map((record) {
          // Map CKAN fields to Facility model fields
          // Adjust field mappings according to the actual API response
          return Facility(
            id: record['_id']?.toString() ?? '',
            code: record['code']?.toString() ?? '',
            name: record['name']?.toString() ?? record['facility_name']?.toString() ?? '',
            facilityType: record['facility_type']?.toString() ?? 'Private Hospital',
            county: record['county']?.toString() ?? 'Unknown',
            subCounty: record['sub_county']?.toString() ?? 'Unknown',
            ward: record['ward']?.toString() ?? 'Unknown',
            owner: record['owner']?.toString() ?? 'Private',
            operationalStatus: record['status']?.toString() ?? 'Operational',
            latitude: record['latitude'] != null ? double.tryParse(record['latitude'].toString()) : null,
            longitude: record['longitude'] != null ? double.tryParse(record['longitude'].toString()) : null,
            phone: record['phone']?.toString() ?? record['phone_number']?.toString(),
            email: record['email']?.toString(),
            website: record['website']?.toString(),
            postalAddress: record['postal_address']?.toString() ?? record['address']?.toString(),
            description: record['description']?.toString(),
            services: record['services'] is List 
                ? List<String>.from(record['services']) 
                : (record['services']?.toString() != null 
                   ? record['services'].toString().split(',').map((s) => s.trim()).toList() 
                   : []),
          );
        }).toList();
      }
      
      return [];
    } catch (e) {
      _logger.e('Error parsing CKAN response: $e');
      return [];
    }
  }

  // Get detailed information about a specific facility
  Future<Facility> getFacilityDetails(String facilityId) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl$_facilityDetailsEndpoint$facilityId/');
      
      _logger.i('Fetching facility details from: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          return Facility.fromJson(data);
        } catch (e) {
          _logger.e('Error parsing facility details: $e');
          // Return a mock facility if parsing fails
          return _getMockFacility(facilityId);
        }
      } else {
        _logger.e('Failed to load facility details: ${response.statusCode}');
        return _getMockFacility(facilityId);
      }
    } catch (e) {
      _logger.e('Error fetching facility details: $e');
      return _getMockFacility(facilityId);
    }
  }

  // Get doctors for a specific facility
  Future<List<Doctor>> getDoctorsForFacility(String facilityId) async {
    try {
      // Note: This is an approximation as the actual endpoint for doctors might be different
      final Uri uri = Uri.parse('$_baseUrl$_facilityDetailsEndpoint$facilityId/doctors/');
      
      _logger.i('Fetching doctors from: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> results = data['results'] ?? [];
          
          return results
              .map((doctorData) => Doctor.fromJson(doctorData))
              .toList();
        } catch (e) {
          _logger.e('Error parsing doctor data: $e');
          return _getMockDoctors();
        }
      } else {
        _logger.e('Failed to load doctors: ${response.statusCode}');
        return _getMockDoctors();
      }
    } catch (e) {
      _logger.e('Error fetching doctors: $e');
      return _getMockDoctors();
    }
  }

  // Get list of counties in Kenya
  Future<List<String>> getCounties() async {
    try {
      final Uri uri = Uri.parse('$_baseUrl$_countiesEndpoint');
      
      _logger.i('Fetching counties from: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> results = data['results'] ?? [];
          
          return results
              .map((county) => county['name'] as String)
              .toList();
        } catch (e) {
          _logger.e('Error parsing county data: $e');
          return _getMockCounties();
        }
      } else {
        _logger.e('Failed to load counties: ${response.statusCode}');
        return _getMockCounties();
      }
    } catch (e) {
      _logger.e('Error fetching counties: $e');
      return _getMockCounties();
    }
  }
  
  // Mock data methods for fallback when API fails
  
  // Return mock facilities
  List<Facility> _getMockFacilities(String? searchQuery, String? county) {
    List<Facility> mockFacilities = [
      Facility(
        id: '1',
        code: 'KNH001',
        name: 'Kenyatta National Hospital',
        facilityType: 'National Referral Hospital',
        county: 'Nairobi',
        subCounty: 'Dagoretti',
        ward: 'Kilimani',
        owner: 'Ministry of Health',
        operationalStatus: 'Operational',
        latitude: -1.3017,
        longitude: 36.8069,
        phone: '+254 020 2726300',
        email: 'info@knh.or.ke',
        website: 'https://knh.or.ke',
        services: ['Gynecology', 'Obstetrics', 'Surgery', 'Pediatrics'],
      ),
      Facility(
        id: '2',
        code: 'MSA001',
        name: 'Coast General Hospital',
        facilityType: 'Provincial Hospital',
        county: 'Mombasa',
        subCounty: 'Mvita',
        ward: 'Tudor',
        owner: 'Ministry of Health',
        operationalStatus: 'Operational',
        phone: '+254 722123456',
        services: ['Gynecology', 'Obstetrics', 'Surgery'],
      ),
      Facility(
        id: '3',
        code: 'ELD001',
        name: 'Moi Teaching and Referral Hospital',
        facilityType: 'National Referral Hospital',
        county: 'Uasin Gishu',
        subCounty: 'Eldoret East',
        ward: 'Langas',
        owner: 'Ministry of Health',
        operationalStatus: 'Operational',
        phone: '+254 722123457',
        email: 'info@mtrh.go.ke',
        website: 'https://mtrh.go.ke',
        services: ['Gynecology', 'Obstetrics', 'Surgery', 'Oncology'],
      ),
      Facility(
        id: '4',
        code: 'KSM001',
        name: 'Jaramogi Oginga Odinga Teaching and Referral Hospital',
        facilityType: 'Provincial Hospital',
        county: 'Kisumu',
        subCounty: 'Kisumu Central',
        ward: 'Milimani',
        owner: 'Ministry of Health',
        operationalStatus: 'Operational',
        phone: '+254 722123458',
        services: ['Gynecology', 'Obstetrics', 'Surgery'],
      ),
      Facility(
        id: '5',
        code: 'NKR001',
        name: 'Nakuru County Referral Hospital',
        facilityType: 'County Referral Hospital',
        county: 'Nakuru',
        subCounty: 'Nakuru Town East',
        ward: 'Biashara',
        owner: 'County Government',
        operationalStatus: 'Operational',
        phone: '+254 722123459',
        services: ['Gynecology', 'Obstetrics', 'Surgery'],
      ),
    ];
    
    // Filter by search query if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      mockFacilities = mockFacilities
          .where((facility) => facility.name
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }
    
    // Filter by county if provided
    if (county != null && county.isNotEmpty) {
      mockFacilities = mockFacilities
          .where((facility) =>
              facility.county.toLowerCase() == county.toLowerCase())
          .toList();
    }
    
    return mockFacilities;
  }
  
  // Return a mock facility for a specific ID
  Facility _getMockFacility(String facilityId) {
    final mockFacilities = _getMockFacilities(null, null);
    return mockFacilities.firstWhere(
      (facility) => facility.id == facilityId,
      orElse: () => mockFacilities.first,
    );
  }
  
  // Return mock doctors
  List<Doctor> _getMockDoctors() {
    return [
      Doctor(
        id: '1',
        name: 'Dr. Sarah Njeri',
        specialty: 'Gynecology',
        qualification: 'MBBS, MS',
        phone: '0712345678',
        email: 'sarah.njeri@example.com',
        description: 'Specializes in reproductive health and ovarian disorders',
      ),
      Doctor(
        id: '2',
        name: 'Dr. John Kamau',
        specialty: 'Obstetrics',
        qualification: 'MD',
        phone: '0723456789',
        email: 'john.kamau@example.com',
        description: 'Experienced in women\'s health and prenatal care',
      ),
      Doctor(
        id: '3',
        name: 'Dr. Mary Ochieng',
        specialty: 'Gynecologic Oncology',
        qualification: 'MD, PhD',
        phone: '0734567890',
        email: 'mary.ochieng@example.com',
        description: 'Specializes in cancer treatment related to women\'s reproductive system',
      ),
    ];
  }
  
  // Return mock counties
  List<String> _getMockCounties() {
    return [
      'Nairobi',
      'Mombasa',
      'Kisumu',
      'Nakuru',
      'Uasin Gishu',
      'Kiambu',
      'Kakamega',
      'Nyeri',
      'Meru',
      'Machakos',
      'Kajiado',
      'Kilifi',
      'Bungoma',
      'Bomet',
      'Kericho'
    ];
  }

  // Return mock private facilities
  List<Facility> _getMockPrivateFacilities(String? searchQuery, String? county) {
    List<Facility> mockPrivateFacilities = [
      Facility(
        id: 'p1',
        code: 'NRB-PVT-001',
        name: 'Aga Khan University Hospital',
        facilityType: 'Private Hospital',
        county: 'Nairobi',
        subCounty: 'Westlands',
        ward: 'Parklands',
        owner: 'Aga Khan Foundation',
        operationalStatus: 'Operational',
        latitude: -1.2631,
        longitude: 36.8081,
        phone: '+254 20 366 2000',
        email: 'info@aku.edu',
        website: 'https://hospitals.aku.edu/nairobi',
        services: ['Gynecology', 'Obstetrics', 'Radiology', 'Surgery', 'Oncology'],
      ),
      Facility(
        id: 'p2',
        code: 'NRB-PVT-002',
        name: 'Nairobi Hospital',
        facilityType: 'Private Hospital',
        county: 'Nairobi',
        subCounty: 'Nairobi Central',
        ward: 'Kilimani',
        owner: 'Kenya Hospital Association',
        operationalStatus: 'Operational',
        latitude: -1.2930,
        longitude: 36.7916,
        phone: '+254 20 284 5000',
        email: 'info@nairobihospital.org',
        website: 'https://www.nairobihospital.org',
        services: ['Gynecology', 'Obstetrics', 'Surgery', 'Pediatrics'],
      ),
      Facility(
        id: 'p3',
        code: 'MSA-PVT-001',
        name: 'Mombasa Hospital',
        facilityType: 'Private Hospital',
        county: 'Mombasa',
        subCounty: 'Mvita',
        ward: 'Ganjoni',
        owner: 'Mombasa Hospital',
        operationalStatus: 'Operational',
        latitude: -4.0435,
        longitude: 39.6682,
        phone: '+254 722 123 456',
        services: ['Gynecology', 'Obstetrics', 'Surgery'],
      ),
      Facility(
        id: 'p4',
        code: 'KSM-PVT-001',
        name: 'Aga Khan Hospital Kisumu',
        facilityType: 'Private Hospital',
        county: 'Kisumu',
        subCounty: 'Kisumu Central',
        ward: 'Milimani',
        owner: 'Aga Khan Foundation',
        operationalStatus: 'Operational',
        latitude: -0.1022,
        longitude: 34.7617,
        phone: '+254 57 202 0701',
        services: ['Gynecology', 'Obstetrics', 'Surgery'],
      ),
      Facility(
        id: 'p5',
        code: 'NKR-PVT-001',
        name: 'Mediheal Hospital Nakuru',
        facilityType: 'Private Hospital',
        county: 'Nakuru',
        subCounty: 'Nakuru East',
        ward: 'Nakuru East',
        owner: 'Mediheal Group',
        operationalStatus: 'Operational',
        phone: '+254 722 123 459',
        services: ['Gynecology', 'Obstetrics', 'Surgery', 'Fertility'],
      ),
    ];
    
    // Filter by search query if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      mockPrivateFacilities = mockPrivateFacilities
          .where((facility) => facility.name
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }
    
    // Filter by county if provided
    if (county != null && county.isNotEmpty) {
      mockPrivateFacilities = mockPrivateFacilities
          .where((facility) =>
              facility.county.toLowerCase() == county.toLowerCase())
          .toList();
    }
    
    return mockPrivateFacilities;
  }
}
