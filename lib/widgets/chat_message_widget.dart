import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageData;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageData != null)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.memory(
                              imageData!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      Text(
                        text,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    timeago.format(timestamp, locale: 'en_short'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      margin: const EdgeInsets.only(right: 12.0, left: 12.0),
      child: CircleAvatar(
        backgroundColor: isUser ? Colors.blue.shade800 : Colors.teal.shade700,
        child: Icon(
          isUser ? Icons.person : Icons.medical_services,
          color: Colors.white,
        ),
      ),
    );
  }
}
