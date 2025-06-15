// Import necessary libraries
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:csv/csv.dart';
import 'package:ovarian_cyst_support_app/models/facility.dart';
import 'package:ovarian_cyst_support_app/models/doctor.dart';
import 'package:ovarian_cyst_support_app/services/storage_service.dart';
import 'package:ovarian_cyst_support_app/services/places_service.dart';

// Enum for facility types
enum FacilityType {
  ministry, // Ministry of Health
  privatePractice, // Private Practice (individual providers)
  privateEnterprise, // Private Enterprise (institutions, companies)
}

// Hospital service class for handling healthcare facility data
class HospitalService {
  final Logger _logger = Logger();
  final StorageService _storageService = StorageService();
  final PlacesService _placesService = PlacesService();

  // Path to the local CSV file in assets
  final String _csvFilePath = 'assets/healthcare_facilities.csv';

  // Path to the CSV file in Firebase Storage
  final String _firebaseStoragePath =
      'healthcare_facilities/healthcare_facilities.csv';

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

      // If cache is still empty after loading, return mock data as last resort
      if (_facilitiesCache == null || _facilitiesCache!.isEmpty) {
        _logger.w('No facilities found in cache, using mock data');
        return _getMockFacilities(searchQuery, county, facilityType);
      }

      // Filter facilities based on criteria
      List<Map<String, dynamic>> filteredFacilities =
          _facilitiesCache!.where((facility) {
            // Filter by facility type/owner
            bool matchesType = false;
            String owner = (facility['Owner'] ?? '').toLowerCase();
            String type = (facility['Type'] ?? '').toLowerCase();

            switch (facilityType) {
              case FacilityType.ministry:
                matchesType =
                    owner.contains('ministry') ||
                    owner.contains('government') ||
                    owner.contains('public') ||
                    type.contains('public');
                break;
              case FacilityType.privatePractice:
                matchesType =
                    owner.contains('private practice') ||
                    owner.contains('individual') ||
                    type.contains('private clinic');
                break;
              case FacilityType.privateEnterprise:
                matchesType =
                    owner.contains('private') ||
                    type.contains('private') ||
                    owner.contains('enterprise') ||
                    owner.contains('company');
                break;
            }

            // Filter by search query if provided
            bool matchesSearch = true;
            if (searchQuery != null && searchQuery.isNotEmpty) {
              String facilityName =
                  (facility['Facility_N'] ?? '').toLowerCase();
              matchesSearch = facilityName.contains(searchQuery.toLowerCase());
            }

            // Filter by county if provided
            bool matchesCounty = true;
            if (county != null && county.isNotEmpty) {
              String facilityCounty = (facility['County'] ?? '').toLowerCase();
              matchesCounty = facilityCounty == county.toLowerCase();
            }

            return matchesType && matchesSearch && matchesCounty;
          }).toList();

      // Log the number of facilities found
      _logger.i(
        'Found ${filteredFacilities.length} facilities matching criteria',
      );

      // Apply pagination
      int startIndex = (page - 1) * pageSize;
      int endIndex = startIndex + pageSize;
      if (endIndex > filteredFacilities.length) {
        endIndex = filteredFacilities.length;
      }
      if (startIndex >= filteredFacilities.length) {
        return [];
      }

      List<Map<String, dynamic>> paginatedResults = filteredFacilities.sublist(
        startIndex,
        endIndex,
      );

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
    if (_facilitiesCache != null) {
      return; // Data already loaded
    }

    try {
      String? csvData;

      // First try to load from local assets for faster access
      try {
        csvData = await rootBundle.loadString(_csvFilePath);
        _logger.i('Successfully loaded CSV from local assets');
      } catch (e) {
        _logger.w('Failed to load CSV from local assets: $e');
      }

      // If local asset failed, try Firebase Storage
      if (csvData == null) {
        _logger.i('Attempting to load CSV from Firebase Storage...');
        bool fileExistsInStorage = await _storageService.fileExists(
          _firebaseStoragePath,
        );

        if (!fileExistsInStorage) {
          _logger.i(
            'CSV not found in Firebase Storage. Uploading from assets...',
          );
          await _storageService.uploadCsvFromAssets(
            _csvFilePath,
            _firebaseStoragePath,
          );
        }

        csvData = await _storageService.downloadCsvToString(
          _firebaseStoragePath,
        );
        _logger.i('Successfully loaded CSV from Firebase Storage');
      }

      // If we still don't have data, throw an error
      if (csvData == null || csvData.isEmpty) {
        throw Exception('Could not load CSV data from any source');
      }

      // Parse CSV data
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        csvData,
      );

      if (csvTable.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Extract headers (first row)
      List<String> headers =
          csvTable.first.map((item) => item.toString()).toList();

      // Convert CSV rows to maps with headers as keys
      _facilitiesCache = [];
      for (int i = 1; i < csvTable.length; i++) {
        if (csvTable[i].isEmpty) continue; // Skip empty rows

        Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length; j++) {
          if (j < csvTable[i].length) {
            // Clean up the data
            var value = csvTable[i][j];
            if (value is String) {
              value = value.trim();
            }
            row[headers[j]] = value;
          } else {
            row[headers[j]] = ''; // Handle missing values
          }
        }
        _facilitiesCache!.add(row);
      }

      _logger.i(
        'Successfully loaded ${_facilitiesCache!.length} facilities from CSV',
      );
    } catch (e) {
      _logger.e('Error loading facilities from CSV: $e');
      _facilitiesCache = []; // Set to empty list on error
    }
  }

  // Convert CSV row to Facility object
  Facility _convertCsvRowToFacility(Map<String, dynamic> data) {
    // Extract and clean facility name
    String name = data['Facility_N']?.toString() ?? '';
    name = name.trim();
    if (name.isEmpty) {
      name = 'Unnamed Facility';
    }

    // Extract and validate facility type
    String facilityType = data['Type']?.toString() ?? '';
    facilityType = facilityType.trim();
    if (facilityType.isEmpty) {
      facilityType = 'Health Facility';
    }

    // Determine ownership and operational status
    String owner = data['Owner']?.toString() ?? '';
    owner = owner.trim();
    if (owner.isEmpty) {
      owner = 'Unknown Owner';
    }

    // Clean up location data
    String county = data['County']?.toString() ?? '';
    county = county.trim();
    if (county.isEmpty) {
      county = 'Unknown County';
    }

    String subCounty = data['Sub_County']?.toString() ?? '';
    subCounty = subCounty.trim();
    if (subCounty.isEmpty) {
      subCounty = 'Unknown Sub-County';
    }

    String ward = data['Division']?.toString() ?? '';
    ward = ward.trim();
    if (ward.isEmpty) {
      ward = 'Unknown Ward';
    }

    // Parse coordinates with better error handling
    double? latitude;
    double? longitude;
    try {
      if (data['Latitude'] != null &&
          data['Latitude'].toString().trim().isNotEmpty) {
        final latStr = data['Latitude'].toString().trim();
        latitude = double.parse(latStr);
        // Validate latitude is in valid range
        if (latitude < -90 || latitude > 90) {
          _logger.w('Invalid latitude value for facility $name: $latitude');
          latitude = null;
        }
      }
      if (data['Longitude'] != null &&
          data['Longitude'].toString().trim().isNotEmpty) {
        final lngStr = data['Longitude'].toString().trim();
        longitude = double.parse(lngStr);
        // Validate longitude is in valid range
        if (longitude < -180 || longitude > 180) {
          _logger.w('Invalid longitude value for facility $name: $longitude');
          longitude = null;
        }
      }

      // Log when coordinates are missing
      if (latitude == null || longitude == null) {
        _logger.i('Missing or invalid coordinates for facility $name');
      }
    } catch (e) {
      _logger.w('Error parsing coordinates for facility $name: $e');
    }

    // Build description from available data
    List<String> descriptionParts = [];
    if (data['Nearest_To'] != null &&
        data['Nearest_To'].toString().isNotEmpty) {
      descriptionParts.add('Located near ${data['Nearest_To']}');
    }
    if (facilityType.isNotEmpty) {
      descriptionParts.add('Facility type: $facilityType');
    }
    if (owner.isNotEmpty) {
      descriptionParts.add('Operated by: $owner');
    }

    String? description =
        descriptionParts.isEmpty ? null : descriptionParts.join('. ');

    return Facility(
      id: data['OBJECTID']?.toString() ?? '',
      code: data['OBJECTID']?.toString() ?? '',
      name: name,
      facilityType: facilityType,
      county: county,
      subCounty: subCounty,
      ward: ward,
      owner: owner,
      operationalStatus: 'Operational', // Default value as it's not in CSV
      latitude: latitude,
      longitude: longitude,
      phone: null, // Not available in CSV
      email: null, // Not available in CSV
      website: null, // Not available in CSV
      postalAddress: null, // Not available in CSV
      description: description,
      services: _inferServicesFromType(facilityType),
    );
  }

  // Helper method to infer basic services based on facility type
  List<String> _inferServicesFromType(String facilityType) {
    List<String> services = ['Primary Care'];

    facilityType = facilityType.toLowerCase();
    if (facilityType.contains('hospital')) {
      services.addAll([
        'Emergency Care',
        'Inpatient Services',
        'Laboratory Services',
        'Pharmacy',
      ]);
    }
    if (facilityType.contains('health center')) {
      services.addAll([
        'Outpatient Services',
        'Basic Laboratory Services',
        'Pharmacy',
      ]);
    }
    if (facilityType.contains('clinic')) {
      services.add('Outpatient Services');
    }
    if (facilityType.contains('maternity')) {
      services.addAll(['Maternal Health', 'Child Health', 'Family Planning']);
    }

    return services;
  }

  // Ensure CSV file is in Firebase Storage or load from local assets
  Future<bool> ensureCsvInFirebaseStorage() async {
    try {
      _logger.i('Uploading healthcare facilities CSV to Firebase Storage...');

      // Try to upload to Firebase Storage, but don't block functionality if it fails
      try {
        String? url = await _storageService.uploadCsvFromAssets(
          _csvFilePath,
          _firebaseStoragePath,
        );
        _logger.i('Successfully uploaded CSV to Firebase Storage: $url');
        return true;
      } catch (e) {
        _logger.w('Firebase Storage error, falling back to local assets: $e');
      }

      // Load from local assets instead
      await _loadFacilitiesFromCsv();
      return _facilitiesCache != null && _facilitiesCache!.isNotEmpty;
    } catch (e) {
      _logger.e('Error ensuring CSV availability: $e');
      return false;
    }
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
      return [];
    }
  }

  // Get unique counties from loaded facilities
  Future<List<String>> getCounties() async {
    try {
      // Load facilities if not already loaded
      if (_facilitiesCache == null) {
        await _loadFacilitiesFromCsv();
      }

      // Extract unique counties
      Set<String> uniqueCounties = {};
      for (var facility in _facilitiesCache!) {
        String county = facility['County'] ?? '';
        if (county.isNotEmpty) {
          uniqueCounties.add(county);
        }
      }

      return uniqueCounties.toList()..sort();
    } catch (e) {
      _logger.e('Error fetching counties: $e');
      return ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret'];
    }
  }

  // Enhancement: Get nearby facilities using Google Places
  Future<List<Facility>> getNearbyFacilities(
    double latitude,
    double longitude, {
    double radius = 5000,
  }) async {
    try {
      final places = await _placesService.searchNearbyHospitals(
        latitude,
        longitude,
        radius: radius,
      );

      List<Facility> facilities = [];
      for (var place in places) {
        // Get additional details for each place
        final details = await _placesService.getPlaceDetails(place['place_id']);
        if (details != null) {
          facilities.add(
            Facility(
              id: place['place_id'],
              code: place['place_id'],
              name: place['name'],
              facilityType: 'Hospital',
              county: 'From Google Places',
              subCounty: '',
              ward: '',
              owner: 'From Google Places',
              operationalStatus: 'Operational',
              latitude: place['geometry']['location']['lat'],
              longitude: place['geometry']['location']['lng'],
              phone: details['formatted_phone_number'],
              email: null,
              website: details['website'],
              description: place['vicinity'],
              services: _inferServicesFromType('Hospital'),
            ),
          );
        }
      }

      return facilities;
    } catch (e) {
      _logger.e('Error getting nearby facilities: $e');
      return [];
    }
  }

  // Enhancement: Get facility details using Google Places
  Future<Map<String, dynamic>?> getGooglePlacesDetails(String placeId) async {
    try {
      return await _placesService.getPlaceDetails(placeId);
    } catch (e) {
      _logger.e('Error getting Google Places details: $e');
      return null;
    }
  }

  // Mock facilities for when CSV loading fails
  List<Facility> _getMockFacilities(
    String? searchQuery,
    String? county,
    FacilityType facilityType,
  ) {
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
              'Oncology',
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
      mockFacilities =
          mockFacilities
              .where(
                (facility) => facility.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }

    // Filter by county if provided
    if (county != null && county.isNotEmpty) {
      mockFacilities =
          mockFacilities
              .where(
                (facility) =>
                    facility.county.toLowerCase() == county.toLowerCase(),
              )
              .toList();
    }

    return mockFacilities;
  }

  // Get a mock facility by ID (for fallback)
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
        id: 'd1',
        name: 'Dr. Sarah Wanjiku',
        specialty: 'Gynecologist',
        qualification: 'MBBS, MD (Gynecology)',
        registrationNumber: 'KMP-12345',
        email: 'sarah.wanjiku@example.com',
        phone: '+254 712 345 678',
        description:
            'Dr. Wanjiku is a specialist in women\'s health with over 10 years of experience treating ovarian cysts and related conditions.',
        imageUrl: 'https://randomuser.me/api/portraits/women/45.jpg',
        isAvailable: true,
      ),
      Doctor(
        id: 'd2',
        name: 'Dr. James Mwangi',
        specialty: 'Obstetrician & Gynecologist',
        qualification: 'MBBS, FCPS (Obs & Gyne)',
        registrationNumber: 'KMP-23456',
        email: 'james.mwangi@example.com',
        phone: '+254 723 456 789',
        description:
            'Dr. Mwangi specializes in women\'s reproductive health and has extensive experience in managing ovarian cysts.',
        imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
        isAvailable: true,
      ),
      Doctor(
        id: 'd3',
        name: 'Dr. Elizabeth Ochieng',
        specialty: 'Reproductive Endocrinologist',
        qualification: 'MD, MRCOG',
        registrationNumber: 'KMP-34567',
        email: 'elizabeth.ochieng@example.com',
        phone: '+254 734 567 890',
        description:
            'Dr. Ochieng is an expert in hormonal disorders and reproductive health issues including ovarian cysts.',
        imageUrl: 'https://randomuser.me/api/portraits/women/67.jpg',
        isAvailable: true,
      ),
    ];
  }
}
