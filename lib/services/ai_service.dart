import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/models/symptom_prediction.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ovarian_cyst_support_app/services/gemini_service.dart';

class AIService {
  // Base URL for FastAPI backend
  static const String baseUrl = 'https://ovacare-ai-backend.example.com/api';

  // Endpoints
  static const String predictionEndpoint = '/predict';
  static const String chatbotEndpoint = '/chat';

  // Singleton instance
  static final AIService _instance = AIService._internal();

  // Gemini service for advanced AI capabilities
  final GeminiService _geminiService = GeminiService();

  factory AIService() {
    return _instance;
  }

  AIService._internal();

  // Method to predict symptom severity based on user's symptom history
  Future<SymptomPrediction?> predictSymptomSeverity(
    List<SymptomEntry> recentSymptoms,
  ) async {
    // Check for internet connectivity
    final connectivityResults = await Connectivity().checkConnectivity();

    // Determine if there is an active connection
    final hasConnection = connectivityResults.isNotEmpty &&
        !connectivityResults.contains(ConnectivityResult.none);

    if (!hasConnection) {
      debugPrint('No internet connection. Using offline prediction logic.');
      return _generateOfflinePrediction(recentSymptoms);
    }

    try {
      // Format the symptoms data for the API
      final List<Map<String, dynamic>> symptomsData = recentSymptoms
          .map(
            (symptom) => {
              'date': symptom.date.toIso8601String(),
              'painLevel': symptom.painLevel,
              'symptoms': symptom.symptoms,
              'mood': symptom.mood,
            },
          )
          .toList();

      // Make API call to the AI backend
      final response = await http
          .post(
            Uri.parse('$baseUrl$predictionEndpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'symptoms': symptomsData}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return SymptomPrediction(
          id: DateTime.now().toIso8601String(), // Generate a unique ID
          predictionDate: DateTime.parse(data['prediction_date']),
          severityScore: data['severity_score'].toDouble(),
          riskLevel: data['risk_level'],
          potentialIssues: List<String>.from(data['potential_issues']),
          recommendation: data['recommendation'],
          requiresMedicalAttention: data['requires_medical_attention'],
        );
      } else {
        debugPrint('Error from prediction API: ${response.statusCode}');
        // Fallback to offline prediction
        return _generateOfflinePrediction(recentSymptoms);
      }
    } catch (e) {
      debugPrint('Exception in prediction API call: $e');
      // Fallback to offline prediction
      return _generateOfflinePrediction(recentSymptoms);
    }
  }

  // Fallback offline prediction logic
  SymptomPrediction _generateOfflinePrediction(
    List<SymptomEntry> recentSymptoms,
  ) {
    // Simple heuristic for offline prediction:
    // 1. Average the pain levels from recent entries
    // 2. Increase severity if certain symptoms appear frequently

    if (recentSymptoms.isEmpty) {
      return SymptomPrediction(
        id: DateTime.now().toIso8601String(),
        predictionDate: DateTime.now(),
        severityScore: 1.0,
        riskLevel: 'Low',
        potentialIssues: ['No recent symptoms recorded'],
        recommendation: 'Continue regular monitoring.',
        requiresMedicalAttention: false,
      );
    }

    // Calculate average pain level
    double avgPainLevel =
        recentSymptoms.fold(0, (sum, entry) => sum + entry.painLevel) /
            recentSymptoms.length;

    // Count frequency of concerning symptoms
    Map<String, int> symptomFrequency = {};
    for (var entry in recentSymptoms) {
      for (var symptom in entry.symptoms) {
        symptomFrequency[symptom] = (symptomFrequency[symptom] ?? 0) + 1;
      }
    }

    // Concerning symptoms that might indicate complications
    List<String> concerningSymptoms = [
      'Severe pain',
      'Fever',
      'Vomiting',
      'Sudden pain',
      'Dizziness',
      'Fainting',
    ];

    // Adjust severity based on concerning symptoms
    double severityAdjustment = 0;
    List<String> detectedIssues = [];

    for (var symptom in concerningSymptoms) {
      if (symptomFrequency.containsKey(symptom)) {
        int frequency = symptomFrequency[symptom] ?? 0;
        double frequencyRatio = frequency / recentSymptoms.length;

        if (frequencyRatio > 0.5) {
          severityAdjustment += 2;
          detectedIssues.add(symptom);
        } else if (frequencyRatio > 0.25) {
          severityAdjustment += 1;
          detectedIssues.add(symptom);
        }
      }
    }

    // Calculate final severity score (0-10 scale)
    double severityScore = (avgPainLevel * 10 / 5) +
        severityAdjustment; // Assuming pain is on 0-5 scale
    severityScore = severityScore.clamp(0, 10); // Ensure within 0-10 range

    // Generate prediction
    String riskLevel = SymptomPrediction.getRiskLevelFromScore(severityScore);
    String recommendation = SymptomPrediction.getRecommendationFromScore(
      severityScore,
    );
    bool requiresAttention = severityScore >= 7;

    List<String> potentialIssues =
        detectedIssues.isEmpty ? ['Mild discomfort'] : detectedIssues;

    return SymptomPrediction(
      id: DateTime.now().toIso8601String(),
      predictionDate: DateTime.now(),
      severityScore: severityScore,
      riskLevel: riskLevel,
      potentialIssues: potentialIssues,
      recommendation: recommendation,
      requiresMedicalAttention: requiresAttention,
    );
  }

  // Method to get chatbot response
  Future<String> getChatbotResponse(String userQuery) async {
    // Check for internet connectivity
    final connectivityResults = await Connectivity().checkConnectivity();

    // Determine if there is an active connection
    final hasConnection = connectivityResults.isNotEmpty &&
        !connectivityResults.contains(ConnectivityResult.none);

    if (!hasConnection) {
      debugPrint('No internet connection. Using offline chatbot responses.');
      return _getOfflineChatbotResponse(userQuery);
    }

    try {
      // Use Gemini API for smart responses
      final response = await _geminiService.getResponse(userQuery);
      return response;
    } catch (e) {
      debugPrint('Exception in Gemini API call: $e');

      // Try the previous implementation as a fallback
      try {
        // Make API call to the chatbot AI backend
        final response = await http
            .post(
              Uri.parse('$baseUrl$chatbotEndpoint'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'query': userQuery}),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return data['response'] as String;
        } else {
          debugPrint('Error from chatbot API: ${response.statusCode}');
          // Fallback to offline responses
          return _getOfflineChatbotResponse(userQuery);
        }
      } catch (httpError) {
        debugPrint('Exception in fallback chatbot API call: $httpError');
        // Fallback to offline responses
        return _getOfflineChatbotResponse(userQuery);
      }
    }
  }

  // Method to get the latest symptom prediction
  Future<SymptomPrediction?> getLatestPrediction() async {
    try {
      // In a real implementation, this would retrieve the latest prediction
      // from local storage or from the server

      // For now, return a placeholder prediction
      return SymptomPrediction(
        id: DateTime.now().toIso8601String(),
        predictionDate: DateTime.now(),
        severityScore: 3.5,
        riskLevel: 'Moderate',
        potentialIssues: ['Mild discomfort', 'Bloating'],
        recommendation: 'Continue monitoring symptoms and record any changes.',
        requiresMedicalAttention: false,
      );
    } catch (e) {
      debugPrint('Error retrieving latest prediction: $e');
      return null;
    }
  }

  // Fallback offline chatbot responses
  String _getOfflineChatbotResponse(String userQuery) {
    // Common user questions and predefined responses
    final Map<String, String> commonResponses = {
      'pain':
          'Pain related to ovarian cysts can vary from a dull ache to sharp, severe pain. If you\'re experiencing persistent or severe pain, it\'s important to contact your healthcare provider.',
      'doctor':
          'You should see a doctor if you experience: severe or sudden pain, pain with fever or vomiting, faintness, dizziness, or rapid breathing. These may be signs of a ruptured cyst or ovarian torsion, which require immediate medical attention.',
      'symptoms':
          'Common symptoms of ovarian cysts include pelvic pain, fullness or heaviness in the abdomen, bloating, and painful periods. Some women may also experience pain during intercourse or changes in their menstrual cycle.',
      'treatment':
          'Treatment for ovarian cysts depends on the type, size, and symptoms. Options may include watchful waiting, hormonal contraceptives, pain medications, or in some cases, surgery. Your healthcare provider can recommend the best approach for your specific situation.',
      'causes':
          'Ovarian cysts most commonly develop during ovulation as part of the normal menstrual cycle (functional cysts). Other types can be caused by conditions like endometriosis, polycystic ovary syndrome (PCOS), or abnormal cell growth.',
      'prevention':
          'While you can\'t prevent all ovarian cysts, regular gynecological exams can help with early detection. Hormonal contraceptives may reduce the formation of new functional cysts in some women.',
      'pregnancy':
          'Most ovarian cysts don\'t affect fertility. However, some conditions that cause cysts, like endometriosis or PCOS, may impact fertility. It\'s best to discuss any concerns about fertility with your healthcare provider.',
      'cancer':
          'Most ovarian cysts are benign (non-cancerous). Cancerous cysts are more common in women over 50. Regular check-ups and ultrasounds can help monitor cysts for any concerning changes.',
      'diet':
          'While no specific diet has been proven to treat ovarian cysts, some women find that an anti-inflammatory diet helps reduce pain. This includes foods rich in omega-3 fatty acids, fruits, vegetables, and whole grains, while limiting processed foods, red meat, and alcohol.',
      'exercise':
          'Light to moderate exercise like walking, swimming, or yoga can help manage symptoms by improving blood flow and reducing inflammation. However, avoid high-impact activities during painful episodes.',
    };

    // Check if the user query contains any keywords from our response map
    String lowercaseQuery = userQuery.toLowerCase();

    for (var keyword in commonResponses.keys) {
      if (lowercaseQuery.contains(keyword)) {
        return commonResponses[keyword]!;
      }
    }

    // Default response if no keywords match
    return 'I understand you\'re asking about "$userQuery". For specific medical advice about ovarian cysts, please consult with your healthcare provider. If you have urgent symptoms like severe pain, fever, dizziness, or vomiting, please seek immediate medical attention.';
  }

  Future<String> getImageAnalysisResponse(Uint8List imageBytes) async {
    // Check connectivity first
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isEmpty ||
        (connectivityResult.contains(ConnectivityResult.none) &&
            connectivityResult.length == 1)) {
      return "I can't analyze images while offline. Please connect to the internet and try again.";
    }

    try {
      // In a real implementation, you would send the image to your backend or directly to Gemini
      // For now, we'll just mock the response
      await Future.delayed(
          const Duration(seconds: 2)); // Simulate processing time

      // Commented out for now until implementation is ready
      // final geminiService = GeminiService();
      // return await geminiService.analyzeImage(imageBytes);

      // Mock response for now
      return "I've analyzed the image and it appears to show signs consistent with an ovarian cyst. "
          "The dark circular area suggests a fluid-filled sac. However, please note that this is "
          "not a medical diagnosis. You should always consult with your doctor who can properly "
          "interpret these images and provide appropriate medical advice.";
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      return "I encountered an error while analyzing the image. Please try again or use a different image.";
    }
  }
}
