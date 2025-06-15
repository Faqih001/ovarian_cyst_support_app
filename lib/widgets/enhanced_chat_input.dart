import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/services/voice_to_text_service.dart';
import 'package:ovarian_cyst_support_app/widgets/voice_input_button.dart';

/// Enhanced ChatInput widget that includes voice input functionality
class EnhancedChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final bool isProcessing;

  const EnhancedChatInput({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.isProcessing = false,
  });

  @override
  State<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _EnhancedChatInputState extends State<EnhancedChatInput>
    with SingleTickerProviderStateMixin {
  final VoiceToTextService _voiceToTextService = VoiceToTextService();
  bool _isListening = false;
  late AnimationController _sendButtonController;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1,
    );

    // Initialize voice to text service
    _voiceToTextService.initialize();
  }

  @override
  void dispose() {
    _sendButtonController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (widget.controller.text.trim().isNotEmpty) {
      widget.onSubmitted(widget.controller.text);
      widget.controller.clear();
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      _voiceToTextService.stopListening();
      setState(() => _isListening = false);
    } else {
      final success = await _voiceToTextService.startListening((text) {
        if (text.isNotEmpty) {
          setState(() {
            widget.controller.text = text;
            _isListening = false;
          });
        }
      });

      if (success) {
        setState(() => _isListening = true);
      } else {
        // Show snackbar if voice recognition failed to initialize
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not access the microphone. Please check permissions.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice Input Button
            VoiceInputButton(
              isListening: _isListening,
              onTap: widget.isProcessing ? () {} : _toggleListening,
            ),

            const SizedBox(width: 12),

            // Text Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.controller.text.trim().isNotEmpty
                        ? theme.primaryColor.withValues(alpha: 51)
                        : Colors.grey[300]!,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 16),
                  enabled: !widget.isProcessing && !_isListening,
                  decoration: InputDecoration(
                    hintText:
                        _isListening ? 'Listening...' : 'Type your message...',
                    hintStyle: TextStyle(
                      color: _isListening
                          ? theme.primaryColor.withValues(alpha: 153)
                          : Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      _sendButtonController.forward();
                    } else if (_sendButtonController.value == 1) {
                      _sendButtonController.reverse();
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send Button
            AnimatedBuilder(
              animation: _sendButtonController,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.controller.text.trim().isNotEmpty
                      ? 1.0 + (_sendButtonController.value * 0.1)
                      : 1.0,
                  child: child,
                );
              },
              child: Material(
                color: widget.controller.text.trim().isNotEmpty
                    ? theme.primaryColor
                    : Colors.grey[300],
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: widget.isProcessing ||
                          widget.controller.text.trim().isEmpty
                      ? null
                      : _handleSubmit,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.send_rounded,
                      color: widget.controller.text.trim().isNotEmpty
                          ? Colors.white
                          : Colors.grey[400],
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
