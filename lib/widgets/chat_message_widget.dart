import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/chat_message.dart';
import '../widgets/detected_object_overlay.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  bool _showThinking = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.message.isUser) _buildAvatar(),
          Expanded(
            child: Column(
              crossAxisAlignment: widget.message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageContent(),
                if (widget.message.thinkingText != null &&
                    !widget.message.isUser)
                  _buildThinkingToggle(),
                if (_showThinking && widget.message.thinkingText != null)
                  _buildThinkingContent(),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 4.0,
                    left: 8.0,
                    right: 8.0,
                  ),
                  child: Text(
                    timeago.format(
                      widget.message.timestamp,
                      locale: 'en_short',
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          if (widget.message.isUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: widget.message.isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageContent(),
          Text(
            widget.message.text,
            style: TextStyle(
              color: widget.message.isUser
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (widget.message.imageBytes == null) {
      return const SizedBox.shrink();
    }

    // If we have detected objects, show the overlay with enhanced visualization
    if (widget.message.detectedObjects != null &&
        widget.message.detectedObjects!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detected objects header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            margin: const EdgeInsets.only(bottom: 4.0),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.6 * 255).round()),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_fix_high, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'AI Object Detection',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // The actual object detection overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 340),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: DetectedObjectOverlay(
                imageBytes: widget.message.imageBytes!,
                detectedObjects: widget.message.detectedObjects!,
                confidence: 0.5,
              ),
            ),
          ),
          // Object detection stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            margin: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              'Detected ${widget.message.detectedObjects!.length} objects',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    } else {
      // Enhanced regular image display
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            margin: const EdgeInsets.only(bottom: 4.0),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.6 * 255).round()),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  widget.message.isUser ? 'Uploaded Image' : 'AI Analysis',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250, maxWidth: 320),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.2 * 255).round()),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.memory(
                widget.message.imageBytes!,
                fit: BoxFit.contain,
                // Optimize memory usage
                cacheHeight: 500,
                cacheWidth: 400,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildThinkingToggle() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showThinking = !_showThinking;
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showThinking ? Icons.visibility_off : Icons.visibility,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              _showThinking ? 'Hide thinking process' : 'Show thinking process',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingContent() {
    // Extract steps from thinking text if possible
    List<String> steps = [];

    final regex = RegExp(r'^\d+\.\s+(.+)$', multiLine: true);
    final matches = regex.allMatches(widget.message.thinkingText ?? '');

    if (matches.isNotEmpty) {
      for (final match in matches) {
        if (match.group(1) != null) {
          steps.add(match.group(1)!);
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[50]!, Colors.pink[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.deepPurple[100]!, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with animated brain icon
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.deepPurple[100],
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.psychology,
                  size: 18,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 6),
                Text(
                  'Gemini\'s Thinking Process',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // If we have parsed steps, show them as a list
          if (steps.isNotEmpty)
            ...List.generate(steps.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2, right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[300],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: TextStyle(
                          color: Colors.deepPurple[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            // Fallback to displaying raw text if no steps could be parsed
            Text(
              widget.message.thinkingText!,
              style: TextStyle(
                color: Colors.deepPurple[900],
                fontSize: 13,
                height: 1.4,
              ),
            ),

          // Attribution to Gemini
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.auto_awesome, size: 12, color: Colors.pink[700]),
                const SizedBox(width: 4),
                Text(
                  'Powered by Google Gemini',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.pink[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      margin: const EdgeInsets.only(right: 12.0, left: 12.0),
      child: CircleAvatar(
        backgroundColor: widget.message.isUser
            ? Colors.blue[800]
            : Colors.pink[700],
        child: Icon(
          widget.message.isUser ? Icons.person : Icons.medical_services,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
