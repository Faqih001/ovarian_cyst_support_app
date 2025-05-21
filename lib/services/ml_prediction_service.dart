import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

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

  final Logger _logger = Logger('MLPredictionService');

  MLPredictionService._internal() {
    // Initialize logging when the service is created
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // In production, you might want to use a proper logging backend
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

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
        final error = 'Failed to get prediction: ${response.statusCode}';
        _logger.severe(error);
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      _logger.severe('Error making prediction', e, stackTrace);
      rethrow;
    }
  }

  // Convert blood group string to numeric value
  int _bloodGroupToNumeric(String bloodGroup) {
    const bloodGroups = {
      'A+': 1,
      'A-': 2,
      'B+': 3,
      'B-': 4,
      'O+': 5,
      'O-': 6,
      'AB+': 7,
      'AB-': 8
    };
    return bloodGroups[bloodGroup] ?? 1; // Default to 1 (A+) if unknown
  }

  Future<PCOSPredictionResult> predictOvarianCyst({
    required double age,
    required double weight,
    required double height,
    required double bmi,
    required String bloodGroup,
    required double pulseRate,
    required double rr,
    required double hb,
    required double cycleLength,
    required int cycleRegularity,
    required double marriageStatus,
    required double abortions,
    required int pregnant,
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
    // Calculate FSH-LH ratio using typical values when not provided
    const double defaultFSH = 6.0; // typical FSH level
    const double defaultLH = 5.0; // typical LH level
    final double fshLhRatio = defaultFSH / defaultLH;

    return predictFromData(
      age: age,
      weight: weight,
      height: height,
      bmi: bmi,
      bloodGroup: _bloodGroupToNumeric(bloodGroup),
      pulseRate: pulseRate,
      rr: rr,
      hb: hb,
      cycleRI: cycleRegularity,
      cycleLength: cycleLength,
      marriageStatus: marriageStatus,
      pregnant: pregnant,
      noOfAbortions: abortions,
      betaHcg1: 0.0, // Not using these values in simplified version
      betaHcg2: 0.0,
      fsh: defaultFSH,
      lh: defaultLH,
      fshLhRatio: fshLhRatio,
      hip: waistHipRatio * 100, // Approximating from ratio
      waist: 100, // Using standard value since we only need the ratio
      waistHipRatio: waistHipRatio,
      tsh: tsh,
      amh: amh,
      prl: prl,
      vitD3: vitD3,
      prg: prg,
      rbs: rbs,
      weightGain: weightGain,
      hairGrowth: hairGrowth,
      skinDarkening: skinDarkening,
      hairLoss: hairLoss,
      pimples: pimples,
      fastFood: fastFood,
      regularExercise: regularExercise,
      bpSystolic: bpSystolic,
      bpDiastolic: bpDiastolic,
      follicleL: follicleL,
      follicleR: follicleR,
      avgFSizeL: avgFSizeL,
      avgFSizeR: avgFSizeR,
      endometrium: endometrium,
    );
  }
}
