import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class PCOSPredictionResult {
  final double riskScore;
  final String stage;
  final List<String> recommendations;
  final Map<String, double> featureContributions;

  PCOSPredictionResult({
    required this.riskScore,
    required this.stage,
    required this.recommendations,
    required this.featureContributions,
  });

  factory PCOSPredictionResult.fromJson(Map<String, dynamic> json) {
    return PCOSPredictionResult(
      riskScore: json['risk_probability'] as double,
      stage: json['stage'] as String,
      recommendations: List<String>.from(json['recommendations']),
      featureContributions:
          Map<String, double>.from(json['feature_contributions']),
    );
  }
}

class MLPredictionService {
  static final MLPredictionService _instance = MLPredictionService._internal();
  factory MLPredictionService() => _instance;
  MLPredictionService._internal();

  static const String _baseUrl =
      'http://localhost:8000'; // Update with your Flask server URL

  Future<PCOSPredictionResult> predictFromData({
    required int pregnant,
    required int weightGain,
    required int hairGrowth,
    required int skinDarkening,
    required int hairLoss,
    required int pimples,
    required int fastFood,
    required int regularExercise,
    required int bloodGroup,
    required double betaHcg1,
    required double betaHcg2,
    required double amhLevel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'beta_hcg1': betaHcg1,
          'beta_hcg2': betaHcg2,
          'amh_level': amhLevel,
          'pregnant': pregnant,
          'weight_gain': weightGain,
          'hair_growth': hairGrowth,
          'skin_darkening': skinDarkening,
          'hair_loss': hairLoss,
          'pimples': pimples,
          'fast_food': fastFood,
          'regular_exercise': regularExercise,
          'blood_group': bloodGroup,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return PCOSPredictionResult.fromJson(result);
      } else {
        throw Exception('Failed to get prediction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error making prediction: $e');
      rethrow;
    }
  }
}
