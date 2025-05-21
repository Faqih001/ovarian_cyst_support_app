import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

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

class MLPredictionService {
  static final MLPredictionService _instance = MLPredictionService._internal();
  factory MLPredictionService() => _instance;

  final Logger _logger = Logger('MLPredictionService');

  // API Configuration
  static const bool _useLocalServer = false;
  static const String _localUrl = 'http://localhost:8001';
  static const String _streamlitUrl =
      'https://ovarian-cyst-ml-api.streamlit.app/_stcore/stream';

  String get _baseUrl => _useLocalServer ? _localUrl : _streamlitUrl;

  // Request configuration
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 60);

  MLPredictionService._internal() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

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
    final Map<String, dynamic> requestData = {
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
    };

    try {
      final response = await _makeRequest(requestData);
      try {
        _logger.info('Processing response: ${response.body}');
        final result = json.decode(response.body);
        return PCOSPredictionResult.fromJson(result);
      } catch (e) {
        _logger.severe('Error processing prediction response: $e');
        throw Exception('Invalid response from server. Please try again.');
      }
    } catch (e) {
      _logger.severe('Prediction failed: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Request timed out. Please try again.');
      } else if (e.toString().contains('API not ready')) {
        throw Exception(
            'The prediction service is starting up. Please try again in a few moments.');
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your internet connection.');
      }
      throw Exception(
          'Unable to process your request. Please try again later.');
    }
  }

  Future<http.Response> _makeRequest(Map<String, dynamic> data) async {
    final uri = Uri.parse(_baseUrl);
    int retryCount = 0;

    // Add specific headers for Streamlit
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      'User-Agent': 'OvarianCystApp/1.0',
      'Accept-Encoding': 'gzip, deflate, br',
      'Host': 'ovarian-cyst-ml-api.streamlit.app',
      'Origin': 'https://ovarian-cyst-ml-api.streamlit.app',
      'Referer': 'https://ovarian-cyst-ml-api.streamlit.app/',
      'Connection': 'keep-alive',
      'X-Streamlit-Client': 'true',
    };

    while (retryCount < _maxRetries) {
      try {
        final client = http.Client();
        try {
          _logger.info('Making request to: ${uri.toString()}');
          _logger.info('Request headers: $requestHeaders');
          _logger.info('Request body: ${json.encode(data)}');

          // Wrap the data in Streamlit's expected format
          final streamlitData = {
            'data': data,
            'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
            'app_id': 'ovarian-cyst-predictor'
          };

          final response = await client
              .post(
                uri,
                headers: requestHeaders,
                body: json.encode(streamlitData),
              )
              .timeout(_timeout);

          _logger.info('Response status: ${response.statusCode}');
          _logger.info('Response headers: ${response.headers}');
          _logger.info('Response body: ${response.body}');

          if (response.statusCode == 200) {
            return response;
          } else if (response.statusCode >= 300 && response.statusCode < 400) {
            _logger.warning(
                'Received redirect response. Streamlit API might not be ready.');
            throw Exception(
                'API not ready. Please try again in a few moments.');
          }

          // Handle specific error codes
          switch (response.statusCode) {
            case 401:
              throw Exception(
                  'Unauthorized access. Please check your credentials.');
            case 403:
              throw Exception(
                  'Access forbidden. Please check your permissions.');
            case 429:
              final retryAfter = response.headers['retry-after'];
              if (retryAfter != null) {
                final delay = int.tryParse(retryAfter) ?? 5;
                await Future.delayed(Duration(seconds: delay));
              }
              throw Exception('Too many requests. Please try again later.');
            default:
              throw Exception(
                  'Server returned status code ${response.statusCode}: ${response.body}');
          }
        } finally {
          client.close();
        }
      } catch (e) {
        _logger.warning('Attempt ${retryCount + 1} failed: $e');
        retryCount++;

        if (retryCount < _maxRetries) {
          final baseDelay = 1 << retryCount;
          final jitter =
              (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0;
          await Future.delayed(Duration(seconds: baseDelay + jitter.floor()));
        }
      }
    }

    throw Exception('Failed to make prediction after $_maxRetries attempts');
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
    return bloodGroups[bloodGroup] ?? 1;
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
    const double defaultFSH = 6.0;
    const double defaultLH = 5.0;
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
      betaHcg1: 0.0,
      betaHcg2: 0.0,
      fsh: defaultFSH,
      lh: defaultLH,
      fshLhRatio: fshLhRatio,
      hip: waistHipRatio * 100,
      waist: 100,
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
