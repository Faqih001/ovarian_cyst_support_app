import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../screens/streamlit_view.dart';

/// Result model for PCOS prediction
class PCOSPredictionResult {
  final double riskScore;
  final String stage;
  final List<String> recommendations;
  final Map<String, double> featureContributions;

  const PCOSPredictionResult({
    required this.riskScore,
    required this.stage,
    required this.recommendations,
    required this.featureContributions,
  });

  factory PCOSPredictionResult.fromJson(Map<String, dynamic> json) {
    try {
      return PCOSPredictionResult(
        riskScore: (json['risk_probability'] as num).toDouble(),
        stage: json['stage'].toString(),
        recommendations: List<String>.from(json['recommendations'] ?? []),
        featureContributions: Map<String, double>.from(
            json['feature_contributions']?.map((key, value) =>
                    MapEntry(key.toString(), (value as num).toDouble())) ??
                {}),
      );
    } catch (e) {
      throw FormatException('Invalid JSON format: $e');
    }
  }
}

/// Service to handle ML predictions for PCOS
class MLPredictionService {
  static final MLPredictionService _instance = MLPredictionService._internal();
  factory MLPredictionService() => _instance;

  final Logger _logger = Logger('MLPredictionService');

  MLPredictionService._internal() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  /// Shows the Streamlit prediction UI in a WebView
  void showPredictionUI(BuildContext context) {
    _logger.info('Opening Streamlit WebView UI for prediction');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StreamlitPredictionView(),
      ),
    );
  }
}
