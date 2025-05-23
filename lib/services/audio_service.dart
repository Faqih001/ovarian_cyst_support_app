import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ovarian_cyst_support_app/services/gemini_service.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  final _recorder = AudioRecorder(); // Use AudioRecorder instead of Record
  final AudioPlayer _player = AudioPlayer();
  final GeminiService _geminiService = GeminiService();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  Timer? _recordingTimer;
  int _recordingDuration = 0; // in seconds

  // Maximum recording duration in seconds (2 minutes)
  static const int maxRecordingDuration = 120;

  factory AudioService() {
    return _instance;
  }

  AudioService._internal() {
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    try {
      // Initialize the recorder
      bool hasPermission = await Permission.microphone.request().isGranted;
      if (!hasPermission) {
        debugPrint('No microphone permission');
      }
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  int get recordingDuration => _recordingDuration;

  /// Start recording audio
  Future<void> startRecording({
    required Function(int duration) onProgress,
    required Function(String errorMessage) onError,
  }) async {
    try {
      // Check permission again just in case
      bool hasPermission = await Permission.microphone.request().isGranted;
      if (!hasPermission) {
        onError('Microphone permission not granted');
        return;
      }

      // Get temporary directory to store the recording
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = path;

      // Configure recorder
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _isRecording = true;
      _recordingDuration = 0;

      // Set up timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;
        onProgress(_recordingDuration);

        // Auto-stop if max duration is reached
        if (_recordingDuration >= maxRecordingDuration) {
          stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      onError('Failed to start recording: $e');
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final path = _recordingPath;
      await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  /// Play the recorded audio
  Future<void> playRecording() async {
    final path = _recordingPath;
    if (path == null || !File(path).existsSync()) {
      debugPrint('No recording to play');
      return;
    }

    try {
      await _player.setFilePath(path);
      await _player.play();
      _isPlaying = true;

      // Update isPlaying when playback completes
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
        }
      });
    } catch (e) {
      debugPrint('Error playing recording: $e');
    }
  }

  /// Stop playing the recording
  Future<void> stopPlaying() async {
    if (!_isPlaying) return;

    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }

  /// Process audio with Gemini API
  Future<String> processAudio({
    required String prompt,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return 'Audio file not found. Please try recording again.';
      }

      // Check file size (limit to 10MB for better performance)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        return 'Your voice recording is too long. Please keep it under 1 minute for better results.';
      }

      // Read the file as bytes
      final Uint8List fileBytes = await file.readAsBytes();

      // Determine MIME type
      final mimeType = lookupMimeType(filePath) ?? 'audio/mp4a-latm';

      // Format the prompt for audio processing
      final String enhancedPrompt = '''
$prompt

Please analyze this voice recording about ovarian cysts. The user may be asking a question about symptoms, treatments, or sharing concerns.
Respond with accurate, empathetic information appropriate for a healthcare support app. 
If it's unclear, acknowledge receipt of the voice message and ask for clarification.
''';

      // Process with Gemini API
      final response = await _geminiService.processAudioContent(
        prompt: enhancedPrompt,
        audioBytes: fileBytes,
        mimeType: mimeType,
      );

      return response;
    } catch (e) {
      debugPrint('Error processing audio with Gemini: $e');
      if (e.toString().contains('permission')) {
        return 'I need microphone permission to process voice messages. Please enable it in your device settings.';
      } else if (e.toString().contains('network')) {
        return 'Network error. Please check your internet connection and try again.';
      }
      return 'I couldn\'t process your voice message. Please try speaking more clearly or typing your question.';
    }
  }

  /// Clean up resources
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
  }
}
