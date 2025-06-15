import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ovarian_cyst_support_app/utils/platform_helper.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/services/speech_to_text_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  final Logger _logger = Logger();

  final _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

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
      // Initialize the recorder - skip permission request on web
      if (!kIsWeb) {
        bool hasPermission = await Permission.microphone.request().isGranted;
        if (!hasPermission) {
          _logger.w('No microphone permission');
        }
      }
    } catch (e) {
      _logger.e('Error initializing recorder: $e');
    }
  }

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  int get recordingDuration => _recordingDuration;

  // Start recording audio
  Future<void> startRecording({Function(String)? onError}) async {
    if (await _recorder.isRecording()) {
      _logger.w('Already recording');
      return;
    }

    try {
      // Check if we have microphone permission
      if (!await _recorder.hasPermission()) {
        _logger.w('No permission to record');
        onError?.call('Microphone permission not granted');
        return;
      }

      // For web, we use a different file format and don't need a real path
      final String fileName =
          'voice_message_${DateTime.now().millisecondsSinceEpoch}';
      String path;

      if (kIsWeb) {
        path = '$fileName.webm'; // Web uses webm format
        _recordingPath = path;
      } else {
        // Use our platform helper to get temporary path
        final tempPath = await PlatformHelper.getTemporaryPath();
        path = '$tempPath/$fileName.m4a';
        _recordingPath = path;
      }

      // Choose proper encoder based on platform
      final AudioEncoder encoder =
          kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc;

      // Configure recorder and start recording
      await _recorder.start(
          RecordConfig(
            encoder: encoder,
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

  // Process the recorded audio with Speech-to-Text
  Future<String> processRecordedAudio() async {
    if (_recordingPath == null) {
      return 'No recording available to process';
    }

    try {
      File recordingFile = File(_recordingPath!);

      if (!recordingFile.existsSync()) {
        return 'Recording file not found';
      }

      // Log that we're processing the audio
      _logger.i('Processing audio recording at: $_recordingPath');

      // Create an instance of SpeechToTextService
      final speechToText = SpeechToTextService();

      // Transcribe the audio using the service
      final transcription = await speechToText.transcribeAudio(_recordingPath!);

      // Log the result
      _logger.i('Audio transcription result: $transcription');

      return transcription;
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
