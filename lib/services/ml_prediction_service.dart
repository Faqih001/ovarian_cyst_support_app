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
    required double age,
    required double weight,
    required double height,
    required double bmi,
    required int bloodGroup,
    required double pulseRate,
    required double rr,
    required double hb,
    required int cycleRI,
    required double cycleLength,
    required double marriageStatus,
    required int pregnant,
    required double noOfAbortions,
    required double betaHcg1,
    required double betaHcg2,
    required double fsh,
    required double lh,
    required double fshLhRatio,
    required double hip,
    required double waist,
    required double waistHipRatio,
    required double tsh,
    required double amh,
    required double prl,
    required double vitD3,
    required double prg,
    required double rbs,
    required int weightGain,
    required int hairGrowth,
    required int skinDarkening,
    required int hairLoss,
    required int pimples,
    required int fastFood,
    required int regularExercise,
    required double bpSystolic,
    required double bpDiastolic,
    required double follicleL,
    required double follicleR,
    required double avgFSizeL,
    required double avgFSizeR,
    required double endometrium,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'age': age,
          'weight': weight,
          'height': height,
          'bmi': bmi,
          'blood_group': bloodGroup,
          'pulse_rate': pulseRate,
          'rr': rr,
          'hb': hb,
          'cycle_ri': cycleRI,
          'cycle_length': cycleLength,
          'marriage_status': marriageStatus,
          'pregnant': pregnant,
          'no_of_abortions': noOfAbortions,
          'beta_hcg1': betaHcg1,
          'beta_hcg2': betaHcg2,
          'fsh': fsh,
          'lh': lh,
          'fsh_lh_ratio': fshLhRatio,
          'hip': hip,
          'waist': waist,
          'waist_hip_ratio': waistHipRatio,
          'tsh': tsh,
          'amh': amh,
          'prl': prl,
          'vit_d3': vitD3,
          'prg': prg,
          'rbs': rbs,
          'weight_gain': weightGain,
          'hair_growth': hairGrowth,
          'skin_darkening': skinDarkening,
          'hair_loss': hairLoss,
          'pimples': pimples,
          'fast_food': fastFood,
          'regular_exercise': regularExercise,
          'bp_systolic': bpSystolic,
          'bp_diastolic': bpDiastolic,
          'follicle_l': follicleL,
          'follicle_r': follicleR,
          'avg_f_size_l': avgFSizeL,
          'avg_f_size_r': avgFSizeR,
          'endometrium': endometrium,
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
