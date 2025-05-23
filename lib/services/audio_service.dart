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

  final _recorder = AudioRecorder();
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

  // Start recording audio
  Future<void> startRecording({Function(String)? onError}) async {
    if (await _recorder.isRecording()) {
      debugPrint('Already recording');
      return;
    }

    try {
      // Check if we have microphone permission
      if (!await _recorder.hasPermission()) {
        debugPrint('No permission to record');
        onError?.call('Microphone permission not granted');
        return;
      }

      // Get temporary directory to store the recording
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = path;

      // Configure recorder and start recording
      await _recorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path);

      _isRecording = true;
      _recordingDuration = 0;

      // Start a timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;

        // Stop recording if max duration is reached
        if (_recordingDuration >= maxRecordingDuration) {
          stopRecording();
        }
      });

      debugPrint('Started recording to: $path');
    } catch (e) {
      debugPrint('Error starting recording: $e');
      onError?.call('Could not start recording: ${e.toString()}');
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      debugPrint('Not recording');
      return null;
    }

    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Stop recording
      final path = await _recorder.stop();
      _isRecording = false;

      debugPrint('Recording stopped: $path');
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  // Play recorded audio
  Future<void> playRecording() async {
    if (_isPlaying || _recordingPath == null) return;

    try {
      await _player.setFilePath(_recordingPath!);
      await _player.play();
      _isPlaying = true;

      // Listen for playback to complete
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
        }
      });
    } catch (e) {
      debugPrint('Error playing recording: $e');
      _isPlaying = false;
    }
  }

  // Stop playing
  Future<void> stopPlaying() async {
    if (!_isPlaying) return;

    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }

  // Process the recorded audio with Gemini API
  Future<String> processRecordedAudio() async {
    if (_recordingPath == null) {
      return 'No recording available to process';
    }

    try {
      File recordingFile = File(_recordingPath!);

      if (!recordingFile.existsSync()) {
        return 'Recording file not found';
      }

      // Get file as bytes
      Uint8List audioBytes = await recordingFile.readAsBytes();

      // Determine MIME type
      String? mimeType = lookupMimeType(_recordingPath!) ?? 'audio/m4a';

      // Process with Gemini
      final result = await _geminiService.processAudioContent(
        prompt: "Interpret this audio recording about ovarian cysts",
        audioBytes: audioBytes,
        mimeType: mimeType,
      );

      return result;
    } catch (e) {
      debugPrint('Error processing audio: $e');
      return 'Unable to process audio: ${e.toString()}';
    }
  }

  void dispose() {
    _recordingTimer?.cancel();
    _player.dispose();
    _recorder.dispose();
  }
}
