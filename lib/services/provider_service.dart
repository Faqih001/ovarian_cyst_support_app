import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ovarian_cyst_support_app/services/data_persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProviderService {
  // Base URL for the main backend (Express.js)
  static const String baseUrl = 'https://ovacare-backend.example.com/api';

  // Endpoints
  static const String providersEndpoint = '/providers';
  static const String appointmentsEndpoint = '/appointments';
  static const String availabilityEndpoint = '/availability';
  static const String costEstimateEndpoint = '/costs/estimate';
  static const String paymentEndpoint = '/payments';

  // Singleton instance
  static final ProviderService _instance = ProviderService._internal();

  factory ProviderService() {
    return _instance;
  }

  ProviderService._internal();

  // Get list of healthcare providers
  Future<List<Map<String, dynamic>>> getProviders({
    String? specialty,
    String? location,
  }) async {
    // Check for internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('No internet connection. Using cached providers data.');
      return _getCachedProviders();
    }

    try {
      // Build query parameters
      Map<String, String> queryParams = {};
      if (specialty != null && specialty.isNotEmpty) {
        queryParams['specialty'] = specialty;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }

      // Make API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl$providersEndpoint',
        ).replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> providers = _safeMapListCast(data);

        // Cache data for offline use
        await _cacheProviders(providers);

        return providers;
      } else {
        debugPrint('Error from providers API: ${response.statusCode}');
        return _getCachedProviders();
      }
    } catch (e) {
      debugPrint('Exception in providers API call: $e');
      return _getCachedProviders();
    }
  }

  // Get provider availability
  Future<List<DateTime>> getProviderAvailability(
    String providerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Check for internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('No internet connection. Using cached availability data.');
      return _getCachedAvailability(providerId, startDate, endDate);
    }

    try {
      // Format the date range
      final Map<String, String> queryParams = {
        'providerId': providerId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      // Make API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl$availabilityEndpoint',
        ).replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<DateTime> availableTimes =
            data.map((item) => DateTime.parse(item as String)).toList();

        // Cache data for offline use
        await _cacheAvailability(providerId, availableTimes);

        return availableTimes;
      } else {
        debugPrint('Error from availability API: ${response.statusCode}');
        return _getCachedAvailability(providerId, startDate, endDate);
      }
    } catch (e) {
      debugPrint('Exception in availability API call: $e');
      return _getCachedAvailability(providerId, startDate, endDate);
    }
  }

  // Get available time slots for a provider on a specific date
  Future<List<String>> getAvailableTimeSlots({
    required String providerId,
    required DateTime date,
  }) async {
    final availability = await getProviderAvailability(
      providerId,
      date,
      date,
    );

    if (availability.isEmpty) {
      return [];
    }

    // Convert availability to time slots (30-minute intervals)
    List<String> slots = [];
    for (DateTime dt in availability) {
      int hour = dt.hour;
      int minute = dt.minute;
      slots.add(
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
    }

    return slots;
  }

  // Get services offered by a provider
  Future<List<Map<String, dynamic>>> getProviderServices(
    String providerId,
  ) async {
    // Check for internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('No internet connection. Using cached services data.');
      return _getCachedProviderServices(providerId);
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl$providersEndpoint/$providerId/services'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> services = _safeMapListCast(data);

        // Cache data for offline use
        await _cacheProviderServices(providerId, services);

        return services;
      } else {
        debugPrint('Error from provider services API: ${response.statusCode}');
        return _getCachedProviderServices(providerId);
      }
    } catch (e) {
      debugPrint('Exception in provider services API call: $e');
      return _getCachedProviderServices(providerId);
    }
  }

  Future<List<Map<String, dynamic>>> _getCachedProviderServices(
    String providerId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('provider_services_$providerId');
    if (cachedData != null) {
      final List<dynamic> data = jsonDecode(cachedData);
      return _safeMapListCast(data);
    }
    return [];
  }

  Future<void> _cacheProviderServices(
    String providerId,
    List<Map<String, dynamic>> services,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'provider_services_$providerId',
      jsonEncode(services),
    );
  }

  // Book an appointment
  Future<Appointment> bookAppointment(Appointment appointment) async {
    // Simulate booking an appointment
    // Generate a unique ID for the appointment
    final String id = DateTime.now().millisecondsSinceEpoch.toString();

    // Create a new appointment with the generated ID
    final bookedAppointment = Appointment(
      id: id,
      doctorName: appointment.doctorName,
      providerName: appointment.providerName,
      specialization: appointment.specialization,
      purpose: appointment.purpose,
      dateTime: appointment.dateTime,
      location: appointment.location,
      notes: appointment.notes,
      reminderEnabled: appointment.reminderEnabled,
    );

    // Small delay to simulate network request
    await Future.delayed(const Duration(milliseconds: 800));

    return bookedAppointment;
  }

  // Get appointment cost estimate
  Future<double?> getAppointmentCostEstimate(
    String providerId,
    String purpose,
  ) async {
    // Check for internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('No internet connection. Using approximate cost estimate.');
      return _getApproximateCostEstimate(purpose);
    }

    try {
      // Format the request parameters
      final Map<String, String> queryParams = {
        'providerId': providerId,
        'purpose': purpose,
      };

      // Make API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl$costEstimateEndpoint',
        ).replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['estimatedCost'] as double;
      } else {
        debugPrint('Error from cost estimate API: ${response.statusCode}');
        return _getApproximateCostEstimate(purpose);
      }
    } catch (e) {
      debugPrint('Exception in cost estimate API call: $e');
      return _getApproximateCostEstimate(purpose);
    }
  }

  // Process payment (M-Pesa integration would be here)
  Future<Map<String, dynamic>?> processPayment(
    String appointmentId,
    double amount,
  ) async {
    // In a real implementation, this would integrate with M-Pesa API
    // For now, we'll simulate a successful payment

    // Check for internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('No internet connection. Cannot process payment now.');
      return null;
    }

    try {
      // Format the payment request
      final Map<String, dynamic> paymentRequest = {
        'appointmentId': appointmentId,
        'amount': amount,
        'method': 'mpesa',
        // In a real app, additional payment details would be included here
      };

      // Make API call
      final response = await http
          .post(
            Uri.parse('$baseUrl$paymentEndpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(paymentRequest),
          )
          .timeout(const Duration(seconds: 30)); // Payments may take longer

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        debugPrint('Error from payment API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception in payment API call: $e');
      return null;
    }
  }

  // Get user's appointments
  Future<List<Appointment>> getUserAppointments() async {
    // Get locally stored appointments first
    final List<Appointment> localAppointments =
        await DataPersistenceService.getAppointments();

    // Check for internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('No internet connection. Using locally stored appointments.');
      return localAppointments;
    }

    try {
      // Make API call to get appointments from server
      final response = await http.get(
        Uri.parse('$baseUrl$appointmentsEndpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Appointment> serverAppointments = data
            .map(
              (item) => Appointment.fromMap(item as Map<String, dynamic>),
            )
            .toList();

        // Merge server and local appointments, with preference to server data
        final List<Appointment> mergedAppointments = _mergeAppointments(
          serverAppointments,
          localAppointments,
        );

        // Update local storage with merged appointments
        await _updateLocalAppointments(mergedAppointments);

        return mergedAppointments;
      } else {
        debugPrint('Error from appointments API: ${response.statusCode}');
        return localAppointments;
      }
    } catch (e) {
      debugPrint('Exception in appointments API call: $e');
      return localAppointments;
    }
  }

  // Cache providers data locally
  Future<void> _cacheProviders(List<Map<String, dynamic>> providers) async {
    // We'll use shared preferences to store simplified provider data
    // Note: In a real app, you'd want to use a more robust solution like SQLite or Hive

    // Convert providers to a simple JSON string
    final String providersJson = jsonEncode(providers);

    // Store using shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_providers', providersJson);
    await prefs.setString(
      'cached_providers_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  // Get cached providers
  Future<List<Map<String, dynamic>>> _getCachedProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? providersJson = prefs.getString('cached_providers');

    if (providersJson == null || providersJson.isEmpty) {
      // Return mock data if no cache exists
      return _getMockProviders();
    }

    try {
      final List<dynamic> decoded = jsonDecode(providersJson);
      return _safeMapListCast(decoded);
    } catch (e) {
      debugPrint('Error parsing cached providers: $e');
      return _getMockProviders();
    }
  }

  // Mock data for providers
  List<Map<String, dynamic>> _getMockProviders() {
    return [
      {
        'id': 'dr-1',
        'name': 'Dr. Sarah Johnson',
        'specialty': 'Gynecology',
        'facility': 'Women\'s Health Clinic',
        'address': '123 Medical Center Dr.',
        'rating': 4.8,
        'experience': '15 years',
        'photo': 'https://i.pravatar.cc/150?img=32',
      },
      {
        'id': 'dr-2',
        'name': 'Dr. Michael Chen',
        'specialty': 'Obstetrics & Gynecology',
        'facility': 'Central Hospital',
        'address': '456 Healthcare Ave.',
        'rating': 4.7,
        'experience': '12 years',
        'photo': 'https://i.pravatar.cc/150?img=68',
      },
      {
        'id': 'dr-3',
        'name': 'Dr. Amina Osei',
        'specialty': 'Gynecological Surgery',
        'facility': 'Metro Medical Center',
        'address': '789 Hospital Blvd.',
        'rating': 4.9,
        'experience': '18 years',
        'photo': 'https://i.pravatar.cc/150?img=23',
      },
    ];
  }

  // Cache provider availability
  Future<void> _cacheAvailability(
    String providerId,
    List<DateTime> availability,
  ) async {
    // Convert availability to string list
    final List<String> availabilityStrings =
        availability.map((dt) => dt.toIso8601String()).toList();

    // Store using shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('availability_$providerId', availabilityStrings);
    await prefs.setString(
      'availability_${providerId}_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  // Get cached availability
  Future<List<DateTime>> _getCachedAvailability(
    String providerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? availabilityStrings = prefs.getStringList(
      'availability_$providerId',
    );

    if (availabilityStrings == null || availabilityStrings.isEmpty) {
      // Generate mock availability if no cache exists
      return _generateMockAvailability(startDate, endDate);
    }

    try {
      // Parse dates and filter for the requested date range
      final List<DateTime> allDates =
          availabilityStrings.map((str) => DateTime.parse(str)).toList();
      return allDates
          .where((date) => date.isAfter(startDate) && date.isBefore(endDate))
          .toList();
    } catch (e) {
      debugPrint('Error parsing cached availability: $e');
      return _generateMockAvailability(startDate, endDate);
    }
  }

  // Generate mock availability for a date range
  List<DateTime> _generateMockAvailability(
    DateTime startDate,
    DateTime endDate,
  ) {
    List<DateTime> availability = [];

    // Generate availability for each day in the range (excluding weekends)
    // with appointments at 9am, 10am, 11am, 2pm, 3pm, and 4pm
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate)) {
      // Skip weekends
      if (currentDate.weekday != DateTime.saturday &&
          currentDate.weekday != DateTime.sunday) {
        // Morning slots
        availability.add(
          DateTime(currentDate.year, currentDate.month, currentDate.day, 9, 0),
        );
        availability.add(
          DateTime(currentDate.year, currentDate.month, currentDate.day, 10, 0),
        );
        availability.add(
          DateTime(currentDate.year, currentDate.month, currentDate.day, 11, 0),
        );

        // Afternoon slots
        availability.add(
          DateTime(currentDate.year, currentDate.month, currentDate.day, 14, 0),
        );
        availability.add(
          DateTime(currentDate.year, currentDate.month, currentDate.day, 15, 0),
        );
        availability.add(
          DateTime(currentDate.year, currentDate.month, currentDate.day, 16, 0),
        );
      }

      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return availability;
  }

  // Approximate cost estimates for different appointment types
  double _getApproximateCostEstimate(String purpose) {
    switch (purpose.toLowerCase()) {
      case 'consultation':
      case 'check-up':
      case 'follow-up':
        return 50.0;
      case 'ultrasound':
        return 120.0;
      case 'surgical consultation':
        return 150.0;
      case 'procedure':
        return 300.0;
      default:
        return 80.0; // Default estimate
    }
  }

  // Merge appointments from server and local storage
  List<Appointment> _mergeAppointments(
    List<Appointment> serverAppointments,
    List<Appointment> localAppointments,
  ) {
    Map<String, Appointment> mergedMap = {};

    // Add all server appointments
    for (var appointment in serverAppointments) {
      mergedMap[appointment.doctorName +
          appointment.dateTime.toIso8601String()] = appointment;
    }

    // Add local appointments that don't exist on server (these might be pending sync)
    for (var appointment in localAppointments) {
      final key =
          appointment.doctorName + appointment.dateTime.toIso8601String();
      if (!mergedMap.containsKey(key)) {
        mergedMap[key] = appointment;
      }
    }

    return mergedMap.values.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Update local storage with merged appointments
  Future<void> _updateLocalAppointments(List<Appointment> appointments) async {
    await AppointmentDataPersistence.clearAppointments(); // Clear existing

    // Save each appointment
    for (var appointment in appointments) {
      await DataPersistenceService.saveAppointment(appointment);
    }
  }

  // Helper method to safely convert dynamic list to List<Map<String, dynamic>>
  List<Map<String, dynamic>> _safeMapListCast(List<dynamic> dataList) {
    return dataList.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      } else if (item is Map) {
        // Convert other Map types to Map<String, dynamic>
        return Map<String, dynamic>.from(item);
      } else {
        // Handle unexpected item types
        debugPrint(
            'Warning: Unexpected item type in list: ${item?.runtimeType}');
        return <String, dynamic>{};
      }
    }).toList();
  }
}

// Extension method to clear all appointments
extension AppointmentDataPersistence on DataPersistenceService {
  static Future<void> clearAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('appointments');
  }
}
