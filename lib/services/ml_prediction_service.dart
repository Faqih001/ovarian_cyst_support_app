import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset('assets/models/pcos_model.tflite');
      _isInitialized = true;
    } catch (e) {
      print('Error initializing ML model: \$e');
      rethrow;
    }
  }

  Future<PCOSPredictionResult> predictFromData({
    required int age,
    required double cystSize,
    required int painLevel,
    required bool irregularBleeding,
    required bool abdominalPain,
    required bool bloating,
    required bool urinarySymptoms,
    required bool weightLoss,
  }) async {
    if (!_isInitialized) await initialize();

    // Normalize input features
    List<double> features = [
      age / 100.0, // Normalize age
      cystSize / 20.0, // Normalize cyst size (assuming max 20cm)
      painLevel / 5.0, // Pain level is already 1-5
      irregularBleeding ? 1.0 : 0.0,
      abdominalPain ? 1.0 : 0.0,
      bloating ? 1.0 : 0.0,
      urinarySymptoms ? 1.0 : 0.0,
      weightLoss ? 1.0 : 0.0,
    ];

    // Prepare input tensor
    var input = [features];
    var output = List.filled(1 * 3, 0).reshape([1, 3]); // [batch_size, num_classes]

    // Run inference
    _interpreter.run(input, output);
    
    // Process output probabilities
    List<double> probabilities = output[0].cast<double>();
    double maxProb = probabilities.reduce((a, b) => a > b ? a : b);
    int predictedClass = probabilities.indexOf(maxProb);

    // Calculate risk score (0-100)
    double riskScore = (maxProb * 100).roundToDouble();

    // Determine stage and recommendations
    String stage;
    List<String> recommendations;
    Map<String, double> featureContributions = {};

    // Calculate feature contributions
    List<String> featureNames = [
      'Age', 'Cyst Size', 'Pain Level', 'Irregular Bleeding',
      'Abdominal Pain', 'Bloating', 'Urinary Symptoms', 'Weight Loss'
    ];
    for (int i = 0; i < features.length; i++) {
      featureContributions[featureNames[i]] = features[i] * 100;
    }

    if (predictedClass == 2 || riskScore >= 75) {
      stage = "Severe";
      recommendations = [
        "Immediate medical consultation required",
        "Schedule an ultrasound scan",
        "Rest and avoid physical strain",
        "Monitor symptoms closely",
        "Consider emergency care if pain intensifies"
      ];
    } else if (predictedClass == 1 || riskScore >= 50) {
      stage = "Moderate";
      recommendations = [
        "Schedule a gynecologist appointment",
        "Monitor symptoms daily",
        "Moderate activity level",
        "Consider pain management options",
        "Follow-up within 2 weeks"
      ];
    } else {
      stage = "Mild";
      recommendations = [
        "Regular monitoring",
        "Maintain healthy lifestyle",
        "Schedule routine check-up",
        "Track any symptom changes",
        "Continue normal activities"
      ];
    }

    return PCOSPredictionResult(
      riskScore: riskScore,
      stage: stage,
      recommendations: recommendations,
      featureContributions: featureContributions,
    );
  }

  Future<Map<String, dynamic>> analyzeUltrasoundImage(File imageFile) async {
    if (!_isInitialized) await initialize();

    // Load and preprocess image
    final image = img.decodeImage(await imageFile.readAsBytes())!;
    final resized = img.copyResize(image, width: 224, height: 224);
    
    // Convert to float32 array and normalize
    var input = List.generate(
      1 * 224 * 224 * 3,
      (i) => resized.getPixel(i % 224, (i ~/ 224) % 224).r / 255.0,
    ).reshape([1, 224, 224, 3]);

    // Prepare output tensor
    var output = List.filled(1 * 2, 0).reshape([1, 2]); // [batch_size, num_classes]

    // Run inference
    _interpreter.run(input, output);

    // Process results
    List<double> probabilities = output[0].cast<double>();
    bool isCystic = probabilities[1] > 0.5;
    double confidence = probabilities[1] * 100;

    return {
      'isCystic': isCystic,
      'confidence': confidence,
      'probability': probabilities[1],
    };
  }

  void dispose() {
    if (_isInitialized) {
      _interpreter.close();
      _isInitialized = false;
    }
  }
}
