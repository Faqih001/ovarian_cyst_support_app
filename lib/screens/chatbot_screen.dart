import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ovarian_cyst_support_app/models/chat_message.dart';
import 'package:ovarian_cyst_support_app/services/voice_to_text_service.dart';
import 'package:ovarian_cyst_support_app/services/gemini_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final VoiceToTextService _voiceToTextService = VoiceToTextService();
  final GeminiService _geminiService = GeminiService();

  late AnimationController _sendButtonScaleController;
  late AnimationController _typingAnimationController;
  bool _isTyping = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _setupAnimationControllers();
    _initializeChatbot();
  }

  void _setupAnimationControllers() {
    _sendButtonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      value: 1,
    );

    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  void _initializeChatbot() {
    // Start a new chat session with the Gemini API
    _geminiService.startNewChat();

    setState(() {
      _messages.add(
        ChatMessage(
          text:
              'Hello! I\'m your PCOS Assistant powered by Gemini AI. How can I help you today?',
          isUser: false,
          source: MessageSource.bot,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _sendButtonScaleController.dispose();
    _typingAnimationController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    if (_isListening) {
      _voiceToTextService.stopListening();
    }
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _voiceToTextService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      final available = await _voiceToTextService.initialize();
      if (available) {
        setState(() {
          _isListening = true;
        });

        await _voiceToTextService.startListening((text) {
          if (text.isNotEmpty) {
            setState(() {
              _messageController.text = text;
              _isListening = false;
            });
          }
        });
      } else {
        // Show error if speech recognition is not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Speech recognition not available or microphone permission denied',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Keep as fallback in case streaming is not available
  // ignore: unused_element
  void _handleSubmit() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: message,
          isUser: true,
          source: MessageSource.user,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // First show the thinking message
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Let me think about that...",
            isUser: false,
            source: MessageSource.bot,
            timestamp: DateTime.now(),
            messageType: MessageType.thinking,
            isThinking: true,
          ),
        );
      });
      _scrollToBottom();

      // Get response with thinking from Gemini API
      final responseData = await _geminiService.getResponseWithThinking(
        message,
      );
      final response = responseData['response'] as String;
      final thoughts = responseData['thoughts'] as String?;

      // Remove the thinking message
      setState(() {
        _messages.removeWhere((msg) => msg.isThinking);

        // Add the response with thinking if available
        if (thoughts != null) {
          _messages.add(
            ChatMessage(
              text: thoughts,
              isUser: false,
              source: MessageSource.bot,
              timestamp: DateTime.now(),
              messageType: MessageType.thinking,
              isThinking: true,
            ),
          );
        }

        // Add the final response
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            source: MessageSource.bot,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Sorry, I encountered an error while processing your request. Please try again later.',
            isUser: false,
            source: MessageSource.bot,
            timestamp: DateTime.now(),
            messageType: MessageType.error,
          ),
        );
        _isTyping = false;
      });
      debugPrint('Error getting response from Gemini: $e');
    }

    _scrollToBottom();
  }

  // Use streaming thinking capability for more interactive experience
  void _handleStreamingSubmit() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // Add the user message
    setState(() {
      _messages.add(
        ChatMessage(
          text: message,
          isUser: true,
          source: MessageSource.user,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // Create a temporary thinking message that will be updated
      int thinkingMessageIndex = _messages.length;
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Analyzing your question...",
            isUser: false,
            source: MessageSource.bot,
            timestamp: DateTime.now(),
            messageType: MessageType.thinking,
            isThinking: true,
          ),
        );
      });
      _scrollToBottom();

      // Use streaming response for more interactive experience
      await for (final update in _geminiService
          .getStreamingResponseWithThinking(message)) {
        // If it's a thinking update, replace the thinking message
        if (update['type'] == 'thinking') {
          setState(() {
            if (thinkingMessageIndex < _messages.length) {
              _messages[thinkingMessageIndex] = ChatMessage(
                text: update['content']!,
                isUser: false,
                source: MessageSource.bot,
                timestamp: DateTime.now(),
                messageType: MessageType.thinking,
                isThinking: true,
              );
            }
          });
          _scrollToBottom();
        }
        // If it's the final response
        else if (update['type'] == 'response') {
          setState(() {
            // Remove the thinking message
            if (thinkingMessageIndex < _messages.length) {
              _messages.removeAt(thinkingMessageIndex);
            }

            // Add the final response
            _messages.add(
              ChatMessage(
                text: update['content']!,
                isUser: false,
                source: MessageSource.bot,
                timestamp: DateTime.now(),
              ),
            );
            _isTyping = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Sorry, I encountered an error while processing your request. Please try again later.',
            isUser: false,
            source: MessageSource.bot,
            timestamp: DateTime.now(),
            messageType: MessageType.error,
          ),
        );
        _isTyping = false;
      });
      debugPrint('Error getting streaming response from Gemini: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define pinkish color for the theme
    final pinkColor = Color(0xFFF06292); // This is a nice pink shade

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with PCOS Assistant'),
        backgroundColor: pinkColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          // Enhanced pinkish gradient background
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFFCE4EC), // Very light pink
              Color(0xFFF8BBD0), // Light pink
              Color(0xFFF06292).withValues(
                alpha: 153,
              ), // Medium pink with opacity (0.6 * 255 ≈ 153)
            ],
            stops: const [0.1, 0.5, 0.9],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _messageFocusNode.unfocus(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessage(_messages[index]);
                  },
                ),
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUserMessage = message.isUser;
    final isSystemMessage = message.source == MessageSource.system;
    final isThinkingMessage = message.isThinking;

    // For system messages (info/status messages)
    if (isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                child: Text(
                  message.text,
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // For thinking messages (bot's thought process)
    if (isThinkingMessage) {
      return Padding(
        padding: EdgeInsets.only(left: 16, right: 64, top: 4, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              height: 32,
              width: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.purple[100],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    spreadRadius: 0.1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.psychology_outlined,
                  color: Colors.purple[700],
                  size: 18,
                ),
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple[100]!.withValues(alpha: 100),
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.purple[300],
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Thinking Process',
                              style: TextStyle(
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          message.text,
                          style: TextStyle(
                            color: Colors.purple[900],
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4),
                    child: Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isUserMessage ? 64 : 16,
        right: isUserMessage ? 16 : 64,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUserMessage) ...[
            Container(
              height: 40,
              width: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Color(0xFFF06292).withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFFF06292), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    spreadRadius: 0.5,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.smart_toy_rounded, // Better icon for AI assistant
                  color: Color(0xFFF06292),
                  size: 22,
                ),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUserMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isUserMessage
                            ? Color(
                              0xFFF06292,
                            ) // Use the pinkish color for user messages
                            : Colors.white, // White background for bot messages
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUserMessage ? 20 : 4),
                      topRight: Radius.circular(isUserMessage ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 20,
                        ), // 0.08 * 255 ≈ 20
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                    border:
                        !isUserMessage
                            ? Border.all(
                              color: Colors.grey.withValues(alpha: 51),
                              width: 1,
                            ) // 0.2 * 255 ≈ 51
                            : null,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imageBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            message.imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isOffline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange[200]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'OFFLINE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUserMessage) ...[
            Container(
              height: 40,
              width: 40,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF06292).withValues(alpha: 204), // 0.8 * 255 ≈ 204
                    Color(0xFFF06292),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    spreadRadius: 0.5,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: ClipOval(
                  child: Icon(
                    Icons.person_rounded, // Better icon for user
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 64),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Color(0xFFF06292).withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFFF06292), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  spreadRadius: 0.5,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                Icons.smart_toy_rounded, // Match bot avatar icon
                color: Color(0xFFF06292),
                size: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[300]!.withValues(alpha: 38),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final double bounce =
            sin(
              (_typingAnimationController.value * pi * 2) + (index * pi * 0.5),
            ) *
            4;
        return Transform.translate(offset: Offset(0, -bounce), child: child);
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 153),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF06292).withValues(alpha: 25), // 0.1 * 255 ≈ 25
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Color(0xFFF06292).withValues(alpha: 51), // 0.2 * 255 ≈ 51
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText:
                      _isListening ? 'Listening...' : 'Type your message...',
                  hintStyle: TextStyle(
                    color:
                        _isListening
                            ? Theme.of(context).primaryColor
                            : Colors.grey[400],
                  ),
                  prefixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color:
                          _isListening
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                    ),
                    onPressed: _toggleListening,
                    tooltip: _isListening ? 'Stop listening' : 'Voice input',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor:
                      _isListening
                          ? Theme.of(context).primaryColor.withValues(
                            alpha: 13,
                          ) // 0.05 * 255 ≈ 13
                          : Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _sendButtonScaleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sendButtonScaleController.value,
                  child: child,
                );
              },
              child: Material(
                color:
                    _messageController.text.trim().isNotEmpty
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                shape: const CircleBorder(),
                child: InkWell(
                  onTap:
                      _messageController.text.trim().isNotEmpty
                          ? _handleStreamingSubmit // Use streaming handler for more interactive experience
                          : null,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.send_rounded,
                      color:
                          _messageController.text.trim().isNotEmpty
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
