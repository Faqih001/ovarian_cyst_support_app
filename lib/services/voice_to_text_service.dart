import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status.isDenied) return false;

    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Speech to text error: $error'),
      onStatus: (status) => debugPrint('Speech to text status: $status'),
    );

    return _isInitialized;
  }

  Future<bool> startListening(Function(String) onResult) async {
    if (!_isInitialized && !await initialize()) return false;

    return await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      localeId: 'en_US',
    );
  }

  void stopListening() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
