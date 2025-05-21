enum MessageSource { user, bot, system }

class ChatMessage {
  final String text;
  final DateTime timestamp;
  final MessageSource source;
  final bool isOffline;

  ChatMessage({
    required this.text,
    required this.source,
    this.isOffline = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      source: MessageSource.values.byName(json['source']),
      isOffline: json['isOffline'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'source': source.name,
      'isOffline': isOffline,
    };
  }
}
