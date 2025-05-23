import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/services/audio_service.dart';
import 'package:ovarian_cyst_support_app/widgets/gemini_badge.dart';
import 'package:ovarian_cyst_support_app/widgets/voice_visualizer_widget.dart';

class VoiceRecordingWidget extends StatefulWidget {
  final Function(String message) onMessageReady;
  final Function(String error)? onError;

  const VoiceRecordingWidget({
    super.key,
    required this.onMessageReady,
    this.onError,
  });

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget>
    with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasRecording = false;
  int _recordingDuration = 0;
  String? _recordingPath;
  Timer? _recordingTimer;

  // Animation for recording effect
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _recordingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  // Format seconds into MM:SS
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Start recording
  void _startRecording() async {
    try {
      await _audioService.startRecording(
        onError: (errorMessage) {
          if (widget.onError != null) {
            widget.onError!(errorMessage);
          }
        },
      );

      // Start a timer to update recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordingDuration = _audioService.recordingDuration;
        });
      });

      setState(() {
        _isRecording = true;
        _hasRecording = false;
        _recordingPath = null;
      });
    } catch (e) {
      if (widget.onError != null) {
        widget.onError!('Failed to start recording: $e');
      }
    }
  }

  // Stop recording
  void _stopRecording() async {
    try {
      final path = await _audioService.stopRecording();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
        _hasRecording = path != null;
      });
    } catch (e) {
      if (widget.onError != null) {
        widget.onError!('Failed to stop recording: $e');
      }
    }
  }

  // Process the recording
  void _processRecording() async {
    if (_recordingPath == null) {
      if (widget.onError != null) {
        widget.onError!('No recording available to process');
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _audioService.processRecordedAudio();

      widget.onMessageReady(result);

      setState(() {
        _hasRecording = false;
        _recordingPath = null;
      });
    } catch (e) {
      if (widget.onError != null) {
        widget.onError!('Failed to process recording: $e');
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Cancel the recording
  void _cancelRecording() {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
    });
  }

  // Play the recording
  void _playRecording() async {
    if (_recordingPath == null) {
      if (widget.onError != null) {
        widget.onError!('No recording available to play');
      }
      return;
    }

    try {
      await _audioService.playRecording();
    } catch (e) {
      if (widget.onError != null) {
        widget.onError!('Failed to play recording: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Voice Input',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const GeminiBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isRecording
                ? 'Recording... ${_formatDuration(_recordingDuration)}'
                : _hasRecording
                    ? 'Recording completed'
                    : 'Tap to start recording',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Add the voice visualizer
          VoiceVisualizerWidget(
            isRecording: _isRecording,
            isPlaying: _audioService.isPlaying,
          ),
          const SizedBox(height: 16),
          if (_isRecording) ...[
            // Recording in progress UI
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .primaryColor
                        .withAlpha(51), // 0.2 * 255
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor.withAlpha(
                            (76 + _animationController.value * 128)
                                .toInt()), // (0.3 + value * 0.5) * 255
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 32 + (_animationController.value * 8),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _stopRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(Icons.stop, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to stop recording',
              style: TextStyle(fontSize: 12),
            ),
          ] else if (_hasRecording) ...[
            // Recording completed UI
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _playRecording,
                  tooltip: 'Play recording',
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processRecording,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isProcessing ? 'Processing...' : 'Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _cancelRecording,
                  tooltip: 'Delete recording',
                ),
              ],
            ),
          ] else ...[
            // Initial state UI
            GestureDetector(
              onTap: _startRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      Theme.of(context).primaryColor.withAlpha(51), // 0.2 * 255
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.mic,
                  color: Theme.of(context).primaryColor,
                  size: 40,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!_isRecording && !_hasRecording)
            const Text(
              'Tap the microphone to start recording your question',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          if (_isProcessing)
            Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Processing your voice message...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
