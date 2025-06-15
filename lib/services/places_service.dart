import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacesService {
  final String _apiKey = 'AIzaSyAlmmBfcowptQde9BOD8HOMbAxixIne8qs';
  final Logger _logger = Logger();

  // Search for places nearby
  Future<List<Map<String, dynamic>>> searchNearbyHospitals(
    double latitude,
    double longitude, {
    double radius = 5000,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=$latitude,$longitude'
        '&radius=$radius'
        '&type=hospital'
        '&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['results']);
        }
      }
      return [];
    } catch (e) {
      _logger.e('Error searching nearby hospitals: $e');
      return [];
    }
  }

  // Get place details
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId'
        '&fields=name,formatted_address,formatted_phone_number,website,rating,opening_hours'
        '&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      _logger.e('Error getting place details: $e');
      return null;
    }
  }

  // Get place photos
  Future<String?> getPlacePhoto(String photoReference) async {
    try {
      return 'https://maps.googleapis.com/maps/api/place/photo?'
          'maxwidth=400'
          '&photo_reference=$photoReference'
          '&key=$_apiKey';
    } catch (e) {
      _logger.e('Error getting place photo: $e');
      return null;
    }
  }

  // Geocode address to coordinates
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'address=${Uri.encodeComponent(address)}'
        '&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      return null;
    } catch (e) {
      _logger.e('Error geocoding address: $e');
      return null;
    }
  }
}
