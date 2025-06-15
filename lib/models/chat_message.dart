import 'dart:typed_data';
import '../services/gemini_service.dart';

enum MessageSource { user, bot, system }

enum MessageType { text, image, loading, error, thinking }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType messageType;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final MessageSource source;
  final bool isOffline;
  final bool isThinking;
  final String? thinkingText;
  final List<DetectedObject>? detectedObjects;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.messageType = MessageType.text,
    this.imageUrl,
    this.imageBytes,
    this.source = MessageSource.user,
    this.isOffline = false,
    this.isThinking = false,
    this.thinkingText,
    this.detectedObjects,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      messageType: MessageType.values.byName(json['messageType'] ?? 'text'),
      imageUrl: json['imageUrl'],
      source: MessageSource.values.byName(json['source'] ?? 'user'),
      isOffline: json['isOffline'] ?? false,
      isThinking: json['isThinking'] ?? false,
      thinkingText: json['thinkingText'],
      // Detected objects cannot be serialized in JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType.name,
      'imageUrl': imageUrl,
      'source': source.name,
      'isOffline': isOffline,
      'isThinking': isThinking,
      'thinkingText': thinkingText,
      // Detected objects cannot be serialized in JSON
    };
  }
}
