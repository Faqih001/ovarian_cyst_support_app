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

  // API Configuration
  static const bool _useLocalServer = false; // Set to false for production
  static const String _localUrl = 'http://localhost:8001'; // FastAPI server
  static const String _streamlitUrl =
      'http://localhost:8502'; // Streamlit server
  static const String _productionUrl =
      'https://ovarian-cyst-ml-api.streamlit.app';

  String get _baseUrl => _useLocalServer ? _localUrl : _productionUrl;
  String get _fallbackUrl => _streamlitUrl; // Only use local fallback in dev

  static const int _maxRetries = 3;
  static const int _maxRedirects = 5;
  static const Duration _timeout = Duration(seconds: 60); // Increased timeout

  // Custom headers to prevent caching and identify the app
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
    'User-Agent': 'OvarianCystApp/1.0',
    'X-Requested-With': 'XMLHttpRequest',
    'Origin': '*',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': '*'
  };

  MLPredictionService._internal() {
    // Initialize logging
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
      http.Response? response;
      Exception? lastError;

      // Try primary URL first
      try {
        response = await _makeRequest(_baseUrl, requestData);
        return _processPredictionResponse(response);
      } catch (e) {
        _logger.warning('Error with primary URL: $e');
        lastError = e is Exception ? e : Exception(e.toString());
      }

      // Try fallback URL if primary failed
      if (response == null) {
        try {
          response = await _makeRequest(_fallbackUrl, requestData);
          return _processPredictionResponse(response);
        } catch (e) {
          _logger.warning('Error with fallback URL: $e');
          lastError = e is Exception ? e : Exception(e.toString());
        }
      }

      // If both URLs failed, throw a user-friendly error
      _logger.severe('Both URLs failed. Last error: $lastError');
      if (lastError.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      } else if (lastError.toString().contains('timeout')) {
        throw Exception('Request timed out. Please try again.');
      } else {
        throw Exception(
            'Unable to connect to our servers. Please try again later.');
      }
    } catch (e) {
      _logger.severe('Prediction failed: $e');
      throw Exception(
          'Unable to process your request. Please try again later.');
    }
  }

  Future<http.Response> _makeRequest(
      String baseUrl, Map<String, dynamic> data) async {
    var uri = Uri.parse('$baseUrl/predict');
    int retryCount = 0;
    int redirectCount = 0;
    Exception? lastError;
    String? initialUrl = uri.toString();

    while (retryCount < _maxRetries) {
      try {
        final client = http.Client();
        try {
          var currentUri = uri;

          // Skip CORS preflight in Dart - it's handled by the browser

          while (redirectCount < _maxRedirects) {
            _logger.info('Making request to: ${currentUri.toString()}');

            // Add retry attempt number to headers
            final requestHeaders = Map<String, String>.from(_headers)
              ..['X-Retry-Attempt'] = (retryCount + 1).toString();

            final response = await client
                .post(
                  currentUri,
                  headers: requestHeaders,
                  body: json.encode(data),
                )
                .timeout(_timeout);

            _logger.info('Response status: ${response.statusCode}');
            _logger.info('Response headers: ${response.headers}');

            // Log response body for debugging (only in development)
            if (_useLocalServer) {
              _logger.fine('Response body: ${response.body}');
            }

            if (response.statusCode == 200) {
              return response;
            } else if (response.statusCode >= 300 &&
                response.statusCode < 400) {
              final location = response.headers['location'];
              if (location == null) {
                throw Exception('Redirect location header missing');
              }

              final redirectUri = Uri.parse(location);
              currentUri = redirectUri.isAbsolute
                  ? redirectUri
                  : Uri.parse(baseUrl).resolveUri(redirectUri);

              if (currentUri.toString() == initialUrl) {
                _logger.warning('Redirect loop detected');
                break;
              }

              _logger.info('Redirecting to: ${currentUri.toString()}');
              redirectCount++;
              continue;
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
              case 500:
              case 502:
              case 503:
              case 504:
                throw Exception(
                    'Server error (${response.statusCode}). Please try again later.');
              default:
                throw Exception(
                    'Server returned status code ${response.statusCode}: ${response.body}');
            }
          }

          throw Exception('Maximum redirect count ($_maxRedirects) exceeded');
        } finally {
          client.close();
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        _logger.warning('Attempt ${retryCount + 1} failed: $e');
        retryCount++;

        if (retryCount < _maxRetries) {
          // Exponential backoff with jitter
          final baseDelay = 1 << retryCount;
          final jitter =
              (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0;
          await Future.delayed(Duration(seconds: baseDelay + jitter.floor()));
        }
      }
    }

    throw lastError ??
        Exception('Failed to make prediction after $_maxRetries attempts');
  }

  PCOSPredictionResult _processPredictionResponse(http.Response response) {
    try {
      final result = json.decode(response.body);
      return PCOSPredictionResult.fromJson(result);
    } catch (e) {
      _logger.severe('Error processing prediction response', e);
      throw Exception('Invalid response from server. Please try again.');
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
