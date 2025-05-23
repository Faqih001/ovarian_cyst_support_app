import 'dart:math';
import 'package:flutter/material.dart';

class VoiceVisualizerWidget extends StatefulWidget {
  final bool isRecording;
  final bool isPlaying;

  const VoiceVisualizerWidget({
    super.key,
    required this.isRecording,
    this.isPlaying = false,
  });

  @override
  State<VoiceVisualizerWidget> createState() => _VoiceVisualizerWidgetState();
}

class _VoiceVisualizerWidgetState extends State<VoiceVisualizerWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final List<double> _barHeights = [];
  final int _totalBars = 20;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Initialize bars with random heights
    for (int i = 0; i < _totalBars; i++) {
      _barHeights.add(0.2 + _random.nextDouble() * 0.2);
    }

    // Create animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Add listener to update bar heights
    _animationController.addListener(_updateBarHeights);
  }

  @override
  void didUpdateWidget(VoiceVisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start or stop animation based on recording/playing state
    if (widget.isRecording || widget.isPlaying) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    } else {
      if (_animationController.isAnimating) {
        _animationController.stop();

        // Reset heights when stopped
        for (int i = 0; i < _totalBars; i++) {
          _barHeights[i] = 0.2 + _random.nextDouble() * 0.2;
        }
        setState(() {});
      }
    }
  }

  void _updateBarHeights() {
    if (widget.isRecording || widget.isPlaying) {
      setState(() {
        for (int i = 0; i < _totalBars; i++) {
          if (_random.nextBool()) {
            _barHeights[i] = 0.2 + _random.nextDouble() * 0.8;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_totalBars, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 4,
            height: _barHeights[index] * 50,
            decoration: BoxDecoration(
              color: widget.isRecording
                  ? Colors.red.shade400
                  : Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
