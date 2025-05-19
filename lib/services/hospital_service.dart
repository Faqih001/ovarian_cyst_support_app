import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:csv/csv.dart';
import 'package:ovarian_cyst_support_app/models/facility.dart';
import 'package:ovarian_cyst_support_app/models/doctor.dart';

enum FacilityType {
  ministry, // Ministry of Health
  privatePractice, // Private Practice (individual providers)
  privateEnterprise // Private Enterprise (institutions, companies)
}

class HospitalService {
  final Logger _logger = Logger();

  // Path to the local CSV file
  final String _csvFilePath = 'assets/healthcare_facilities.csv';

  // Cache for facilities to avoid reloading the CSV file repeatedly
  List<Map<String, dynamic>>? _facilitiesCache;

  // Get facilities based on type and search criteria
  Future<List<Facility>> getFacilities({
    String? searchQuery,
    String? county,
    int page = 1,
    int pageSize = 20,
    FacilityType facilityType = FacilityType.ministry,
  }) async {
    try {
      // Load all facilities from CSV if not already cached
      if (_facilitiesCache == null) {
        await _loadFacilitiesFromCsv();
      }

      // Filter facilities based on criteria
      List<Map<String, dynamic>> filteredFacilities =
          _facilitiesCache!.where((facility) {
        // Filter by facility type
        bool matchesType = false;
        String owner = facility['Owner'] ?? '';

        switch (facilityType) {
          case FacilityType.ministry:
            matchesType = owner.contains('Ministry of Health');
            break;
          case FacilityType.privatePractice:
            matchesType = owner.contains('Private Practice');
            break;
          case FacilityType.privateEnterprise:
            matchesType = owner.contains('Private Enterprise');
            break;
        }

        // Filter by search query if provided
        bool matchesSearch = true;
        if (searchQuery != null && searchQuery.isNotEmpty) {
          String facilityName = facility['Facility_N'] ?? '';
          matchesSearch =
              facilityName.toLowerCase().contains(searchQuery.toLowerCase());
        }

        // Filter by county if provided
        bool matchesCounty = true;
        if (county != null && county.isNotEmpty) {
          String facilityCounty = facility['County'] ?? '';
          matchesCounty = facilityCounty.toLowerCase() == county.toLowerCase();
        }

        return matchesType && matchesSearch && matchesCounty;
      }).toList();

      // Apply pagination
      int startIndex = (page - 1) * pageSize;
      int endIndex = startIndex + pageSize;
      if (startIndex >= filteredFacilities.length) {
        return [];
      }
      if (endIndex > filteredFacilities.length) {
        endIndex = filteredFacilities.length;
      }

      List<Map<String, dynamic>> paginatedResults =
          filteredFacilities.sublist(startIndex, endIndex);

      // Convert to Facility objects
      return paginatedResults
          .map((data) => _convertCsvRowToFacility(data))
          .toList();
    } catch (e) {
      _logger.e('Error fetching facilities: $e');
      return _getMockFacilities(searchQuery, county, facilityType);
    }
  }

  // Load facilities from CSV file
  Future<void> _loadFacilitiesFromCsv() async {
    try {
      // Load CSV file from assets
      final String csvData = await rootBundle.loadString(_csvFilePath);

      // Parse CSV data
      List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvData);

      // Extract headers (first row)
      List<String> headers =
          csvTable.first.map((item) => item.toString()).toList();

      // Convert CSV rows to maps with headers as keys
      _facilitiesCache = [];
      for (int i = 1; i < csvTable.length; i++) {
        Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length; j++) {
          if (j < csvTable[i].length) {
            row[headers[j]] = csvTable[i][j];
          } else {
            row[headers[j]] = ''; // Handle missing values
          }
        }
        _facilitiesCache!.add(row);
      }

      _logger.i('Loaded ${_facilitiesCache!.length} facilities from CSV');
    } catch (e) {
      _logger.e('Error loading facilities from CSV: $e');
      _facilitiesCache = []; // Set to empty list on error
    }
  }

  // Convert CSV row to Facility object
  Facility _convertCsvRowToFacility(Map<String, dynamic> data) {
    return Facility(
      id: data['OBJECTID']?.toString() ?? '',
      code: data['OBJECTID']?.toString() ?? '',
      name: data['Facility_N']?.toString() ?? '',
      facilityType: data['Type']?.toString() ?? 'Unknown',
      county: data['County']?.toString() ?? 'Unknown',
      subCounty: data['Sub_County']?.toString() ?? 'Unknown',
      ward: data['Division']?.toString() ?? 'Unknown',
      owner: data['Owner']?.toString() ?? 'Unknown',
      operationalStatus: 'Operational', // Default value as it's not in CSV
      latitude: data['Latitude'] != null
          ? double.tryParse(data['Latitude'].toString())
          : null,
      longitude: data['Longitude'] != null
          ? double.tryParse(data['Longitude'].toString())
          : null,
      phone: null, // Not available in CSV
      email: null, // Not available in CSV
      website: null, // Not available in CSV
      postalAddress: null, // Not available in CSV
      description:
          'Located near ${data['Nearest_To']?.toString() ?? 'local area'}',
      services: [], // Not available in CSV
    );
  }

  // Get detailed information about a specific facility
  Future<Facility> getFacilityDetails(String facilityId) async {
    try {
      // Load facilities if not already loaded
      if (_facilitiesCache == null) {
        await _loadFacilitiesFromCsv();
      }

      // Find the facility by ID
      final facility = _facilitiesCache!.firstWhere(
        (f) => f['OBJECTID'].toString() == facilityId,
        orElse: () => {},
      );

      if (facility.isNotEmpty) {
        return _convertCsvRowToFacility(facility);
      } else {
        _logger.e('Facility not found: $facilityId');
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
      // In a real implementation, we would query a database or API for doctors
      // Since the CSV doesn't contain doctor information, we'll use mock data
      return _getMockDoctors();
    } catch (e) {
      _logger.e('Error fetching doctors: $e');
      return _getMockDoctors();
    }
  }

  // Get list of counties in Kenya
  Future<List<String>> getCounties() async {
    try {
      // Load facilities if not already loaded
      if (_facilitiesCache == null) {
        await _loadFacilitiesFromCsv();
      }

      // Extract unique counties from the CSV data
      Set<String> counties = {};
      for (var facility in _facilitiesCache!) {
        String county = facility['County']?.toString() ?? '';
        if (county.isNotEmpty) {
          counties.add(county);
        }
      }

      // Sort counties alphabetically
      List<String> sortedCounties = counties.toList()..sort();
      return sortedCounties;
    } catch (e) {
      _logger.e('Error fetching counties: $e');
      return _getMockCounties();
    }
  }

  // Mock data methods for fallback when API fails

  // Return mock facilities
  List<Facility> _getMockFacilities(
      String? searchQuery, String? county, FacilityType facilityType) {
    List<Facility> mockFacilities = [];

    switch (facilityType) {
      case FacilityType.ministry:
        mockFacilities = [
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
        ];
        break;

      case FacilityType.privatePractice:
        mockFacilities = [
          Facility(
            id: 'pp1',
            code: 'NRB-PP-001',
            name: 'Dr. Kimani Specialist Clinic',
            facilityType: 'Specialist Clinic',
            county: 'Nairobi',
            subCounty: 'Westlands',
            ward: 'Parklands',
            owner: 'Private Practice - Specialist',
            operationalStatus: 'Operational',
            latitude: -1.2631,
            longitude: 36.8081,
            phone: '+254 722 123 456',
            email: 'drkimani@example.com',
            services: ['Gynecology', 'Women\'s Health'],
          ),
          Facility(
            id: 'pp2',
            code: 'MSA-PP-001',
            name: 'Dr. Ochieng Medical Practice',
            facilityType: 'Medical Clinic',
            county: 'Mombasa',
            subCounty: 'Nyali',
            ward: 'Nyali',
            owner: 'Private Practice - General Practitioner',
            operationalStatus: 'Operational',
            phone: '+254 722 123 457',
            services: ['General Medicine', 'Women\'s Health'],
          ),
        ];
        break;

      case FacilityType.privateEnterprise:
        mockFacilities = [
          Facility(
            id: 'pe1',
            code: 'NRB-PE-001',
            name: 'Aga Khan University Hospital',
            facilityType: 'Private Hospital',
            county: 'Nairobi',
            subCounty: 'Westlands',
            ward: 'Parklands',
            owner: 'Private Enterprise (Institution)',
            operationalStatus: 'Operational',
            latitude: -1.2631,
            longitude: 36.8081,
            phone: '+254 20 366 2000',
            email: 'info@aku.edu',
            website: 'https://hospitals.aku.edu/nairobi',
            services: [
              'Gynecology',
              'Obstetrics',
              'Radiology',
              'Surgery',
              'Oncology'
            ],
          ),
          Facility(
            id: 'pe2',
            code: 'NRB-PE-002',
            name: 'Nairobi Hospital',
            facilityType: 'Private Hospital',
            county: 'Nairobi',
            subCounty: 'Nairobi Central',
            ward: 'Kilimani',
            owner: 'Private Enterprise (Institution)',
            operationalStatus: 'Operational',
            latitude: -1.2930,
            longitude: 36.7916,
            phone: '+254 20 284 5000',
            email: 'info@nairobihospital.org',
            website: 'https://www.nairobihospital.org',
            services: ['Gynecology', 'Obstetrics', 'Surgery', 'Pediatrics'],
          ),
        ];
        break;
    }

    // Filter by search query if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      mockFacilities = mockFacilities
          .where((facility) =>
              facility.name.toLowerCase().contains(searchQuery.toLowerCase()))
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
    // First try to match by prefix to determine facility type
    FacilityType facilityType;
    if (facilityId.startsWith('pp')) {
      facilityType = FacilityType.privatePractice;
    } else if (facilityId.startsWith('pe')) {
      facilityType = FacilityType.privateEnterprise;
    } else {
      facilityType = FacilityType.ministry;
    }

    final mockFacilities = _getMockFacilities(null, null, facilityType);
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
        description:
            'Specializes in cancer treatment related to women\'s reproductive system',
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
}
