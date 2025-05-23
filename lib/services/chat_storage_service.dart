import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:ovarian_cyst_support_app/models/chat_message.dart';

/// Service to handle storing and retrieving chat messages using Firebase Storage
/// This is more reliable across platforms, especially on web where SQLite has issues
class ChatStorageService {
  static final ChatStorageService _instance = ChatStorageService._internal();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Path where chat histories are stored
  static const String _chatBasePath = 'user_chats';

  factory ChatStorageService() {
    return _instance;
  }

  ChatStorageService._internal();

  /// Get the storage path for the current user's chat history
  String get _userChatPath {
    final String userId = _auth.currentUser?.uid ?? 'anonymous';
    return '$_chatBasePath/$userId/chat_history.json';
  }

  /// Save chat messages to Firebase Storage
  Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      if (messages.isEmpty) return;

      // Convert messages to JSON
      final List<Map<String, dynamic>> jsonMessages =
          messages.map((msg) => msg.toJson()).toList();
      final String jsonData = jsonEncode(jsonMessages);

      // Create a reference to the file location
      final ref = _storage.ref().child(_userChatPath);

      // Upload the JSON data as a string
      await ref.putString(
        jsonData,
        format: PutStringFormat.raw,
        metadata: SettableMetadata(contentType: 'application/json'),
      );

      debugPrint('Chat history saved to Firebase Storage');
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  /// Load chat messages from Firebase Storage
  Future<List<ChatMessage>> loadMessages() async {
    try {
      // Create a reference to the file
      final ref = _storage.ref().child(_userChatPath);

      // Check if the file exists
      try {
        // Try to download the file
        final bytes = await ref.getData();
        if (bytes == null || bytes.isEmpty) {
          debugPrint('No chat history found in storage');
          return [];
        }

        // Decode the JSON data
        final String jsonData = utf8.decode(bytes);
        final List<dynamic> decodedMessages = jsonDecode(jsonData);

        // Convert to ChatMessage objects
        final List<ChatMessage> messages =
            decodedMessages.map((item) => ChatMessage.fromJson(item)).toList();

        debugPrint('Loaded ${messages.length} messages from Firebase Storage');
        return messages;
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          debugPrint('No chat history file found in storage (first-time user)');
          return [];
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      return [];
    }
  }

  /// Delete all chat history for the current user
  Future<void> clearChatHistory() async {
    try {
      final ref = _storage.ref().child(_userChatPath);

      try {
        await ref.delete();
        debugPrint('Chat history deleted successfully');
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          debugPrint('No chat history to delete');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Error deleting chat history: $e');
    }
  }
}
