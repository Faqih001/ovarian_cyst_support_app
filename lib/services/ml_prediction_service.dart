import 'dart:io';
import 'dart:convert';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

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
}

class MLPredictionService {
  static final MLPredictionService _instance = MLPredictionService._internal();
  factory MLPredictionService() => _instance;
  MLPredictionService._internal();

  late Interpreter _interpreter;
  late Map<String, dynamic> _scaler;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load TFLite model
      _interpreter =
          await Interpreter.fromAsset('assets/models/pcos_model.tflite');

      // Load scaler parameters
      final String scalerJson =
          await rootBundle.loadString('assets/models/pcos_scaler.json');
      _scaler = json.decode(scalerJson);

      _isInitialized = true;
    } catch (e) {
      print('Error initializing ML model: $e');
      rethrow;
    }
  }

  Future<PCOSPredictionResult> predictFromData({
    required double betaHcg1,
    required double betaHcg2,
    required double amhLevel,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Scale input data using saved scaler parameters
      List<double> means = List<double>.from(_scaler['mean']);
      List<double> scales = List<double>.from(_scaler['scale']);
      List<String> featureNames = List<String>.from(_scaler['feature_names']);

      List<double> scaledInputs = [
        (betaHcg1 - means[0]) / scales[0],
        (betaHcg2 - means[1]) / scales[1],
        (amhLevel - means[2]) / scales[2],
      ];

      // Prepare input tensor
      var inputArray = [scaledInputs];
      var outputArray = List<double>.filled(1, 0).reshape([1, 1]);

      // Run inference
      _interpreter.run(inputArray, outputArray);

      // Get risk score (probability)
      double riskScore = outputArray[0][0];

      // Determine stage based on risk score
      String stage;
      if (riskScore < 0.3) {
        stage = 'Low Risk';
      } else if (riskScore < 0.7) {
        stage = 'Moderate Risk';
      } else {
        stage = 'High Risk';
      }

      // Generate recommendations based on risk level
      List<String> recommendations = _getRecommendations(riskScore);

      // Calculate feature contributions using standardized coefficients
      Map<String, double> featureContributions = {};
      for (var i = 0; i < featureNames.length; i++) {
        featureContributions[featureNames[i]] = (scaledInputs[i].abs() /
            scaledInputs.map((x) => x.abs()).reduce((a, b) => a + b));
      }

      return PCOSPredictionResult(
        riskScore: riskScore,
        stage: stage,
        recommendations: recommendations,
        featureContributions: featureContributions,
      );
    } catch (e) {
      print('Error making prediction: $e');
      rethrow;
    }
  }

  List<String> _getRecommendations(double riskScore) {
    if (riskScore < 0.3) {
      return [
        'Continue regular health check-ups',
        'Maintain a healthy lifestyle',
        'Keep track of your menstrual cycle'
      ];
    } else if (riskScore < 0.7) {
      return [
        'Schedule a follow-up with a gynecologist',
        'Consider hormone level testing',
        'Monitor symptoms closely',
        'Maintain a healthy diet and exercise routine'
      ];
    } else {
      return [
        'Seek immediate medical consultation',
        'Complete hormone panel testing recommended',
        'Regular monitoring required',
        'Consider ultrasound examination'
      ];
    }
  }
}
