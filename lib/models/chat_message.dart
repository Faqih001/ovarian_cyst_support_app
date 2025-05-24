import 'dart:typed_data';

enum MessageSource { user, bot, system }

enum MessageType { text, image, loading, error }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType messageType;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final MessageSource source;
  final bool isOffline;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.imageUrl,
    this.imageBytes,
    this.source = MessageSource.user,
    this.isOffline = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      messageType: MessageType.values.byName(json['messageType'] ?? 'text'),
      imageUrl: json['imageUrl'],
      source: MessageSource.values.byName(json['source'] ?? 'user'),
      isOffline: json['isOffline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType.name,
      'imageUrl': imageUrl,
      'source': source.name,
      'isOffline': isOffline,
    };
  }
}
