import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // API key provided for Gemini
  static const String apiKey = 'AIzaSyDEFsF9visXbuZfNEvtPvC8wI_deQBH-ro';

  // Singleton instance
  static final GeminiService _instance = GeminiService._internal();

  // Model instance
  late final GenerativeModel _model;

  // Chat session for maintaining conversation history
  ChatSession? _chatSession;

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal() {
    // Initialize the model with Gemini-pro (text only model)
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  /// Starts a new chat session clearing previous history
  void startNewChat() {
    _chatSession = _model.startChat();
  }

  /// Gets a response from Gemini AI
  /// Keeps conversation context if in a chat session
  Future<String> getResponse(String prompt) async {
    try {
      // Create a chat session if one doesn't exist
      if (_chatSession == null) {
        startNewChat();
      }

      // Get response from the model
      final response = await _chatSession!.sendMessage(
        Content.text(
          prompt + _getOvarianCystContext(),
        ),
      );

      // Extract and return the text response
      final responseText = response.text;
      
      if (responseText == null || responseText.isEmpty) {
        return _getFallbackResponse();
      }
      
      return responseText;
    } catch (e) {
      debugPrint('Error in Gemini API: $e');
      return _getFallbackResponse();
    }
  }

  /// Get a direct response without maintaining chat history
  /// Useful for one-time queries or when chat context isn't needed
  Future<String> getSingleResponse(String prompt) async {
    try {
      final response = await _model.generateContent(
        [Content.text(prompt + _getOvarianCystContext())],
      );

      final responseText = response.text;
      
      if (responseText == null || responseText.isEmpty) {
        return _getFallbackResponse();
      }
      
      return responseText;
    } catch (e) {
      debugPrint('Error in Gemini API single response: $e');
      return _getFallbackResponse();
    }
  }

  /// Provides domain context to help the model generate better responses
  String _getOvarianCystContext() {
    return '''

You are OvaCare, a specialized AI assistant for women with ovarian cysts. 
Please respond with accurate and empathetic medical information related to ovarian cysts.
Keep responses concise (under 3-4 sentences when possible) and easy to understand.
Remember you are not a doctor, and should recommend seeking medical attention for concerning symptoms.
When in doubt or for specific medical advice, remind users to consult healthcare professionals.
''';
  }

  /// Fallback response for when the API fails
  String _getFallbackResponse() {
    return "I apologize, but I am unable to process your request right now. "
        "For medical questions about ovarian cysts, please consult with your healthcare provider. "
        "If you have urgent symptoms like severe pain, fever, dizziness, or vomiting, "
        "seek immediate medical attention.";
  }
}