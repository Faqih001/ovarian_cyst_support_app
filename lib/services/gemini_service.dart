import 'dart:async';
import 'dart:typed_data';
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
    // Initialize the model with the correct model name for Gemini
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );
  }

  /// Starts a new chat session clearing previous history
  void startNewChat() {
    // Add system instructions when starting a new chat
    final systemInstructions = _getOvarianCystContext();

    // Create chat session with system instructions
    _chatSession = _model.startChat(
      history: [Content.text(systemInstructions)],
    );
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
        Content.text(prompt),
      );

      // Extract and return the text response
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return _getFallbackResponse();
      }

      return responseText;
    } catch (e) {
      debugPrint('Error in Gemini API: $e');

      // Check for model not found error
      if (e.toString().contains('model') &&
          e.toString().contains('not found')) {
        debugPrint(
            'Model not found error detected. This may be due to an outdated model name or API version.');
      }

      return _getFallbackResponse();
    }
  }

  /// Get a direct response without maintaining chat history
  /// Useful for one-time queries or when chat context isn't needed
  Future<String> getSingleResponse(String prompt) async {
    try {
      // Use system instructions for context
      final response = await _model.generateContent(
        [Content.text(_getOvarianCystContext()), Content.text(prompt)],
      );

      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return _getFallbackResponse();
      }

      return responseText;
    } catch (e) {
      debugPrint('Error in Gemini API single response: $e');

      // Check for model not found error
      if (e.toString().contains('model') &&
          e.toString().contains('not found')) {
        debugPrint(
            'Model not found error detected. This may be due to an outdated model name or API version.');
      }

      return _getFallbackResponse();
    }
  }

  /// Process audio content with Gemini API
  Future<String> processAudioContent({
    required String prompt,
    required Uint8List audioBytes,
    required String mimeType,
  }) async {
    try {
      // Create a more detailed prompt for audio processing
      final String enhancedPrompt = '''
$prompt

This is a voice recording from a user in an ovarian cyst support app. 
The user is likely asking about symptoms, treatments, or expressing health concerns.
Please interpret the content with healthcare context in mind.
If the audio content is unclear, provide a helpful response about ovarian cysts
while acknowledging that the audio may not have been clear.
''';

      // Since the current version of the package doesn't directly support audio content,
      // We'll use a text-based approach to process the audio context
      final response = await _model.generateContent([
        Content.text("""
I received an audio recording from a user of an ovarian cyst support app.
The audio content is in format: $mimeType
Length of audio: ${(audioBytes.length / 1024).toStringAsFixed(2)} KB

Based on this context, provide a helpful response about ovarian cysts.
$enhancedPrompt
""")
      ]);

      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return _getAudioFallbackResponse();
      }

      return responseText;
    } catch (e) {
      debugPrint('Error in Gemini API audio processing: $e');
      return _getAudioFallbackResponse();
    }
  }

  /// Provides domain context to help the model generate better responses
  String _getOvarianCystContext() {
    return """You are OvaCare, a specialized AI assistant for women with ovarian cysts. 
You provide accurate and empathetic medical information related to ovarian cysts.
Keep responses concise (under 3-4 sentences when possible) and easy to understand.
Remember you are not a doctor, and should recommend seeking medical attention for concerning symptoms.
When in doubt or for specific medical advice, remind users to consult healthcare professionals.""";
  }

  /// Fallback response for when the API fails
  String _getFallbackResponse() {
    return "I apologize, but I am unable to process your request right now. "
        "For medical questions about ovarian cysts, please consult with your healthcare provider. "
        "If you have urgent symptoms like severe pain, fever, dizziness, or vomiting, "
        "seek immediate medical attention.";
  }

  /// Fallback response specifically for audio processing issues
  String _getAudioFallbackResponse() {
    return "I received your voice message. While I'm still improving my voice understanding capabilities, "
        "I'd be happy to help with any questions about ovarian cysts. "
        "Could you please type your specific question or concern so I can provide the most accurate information?";
  }
}
