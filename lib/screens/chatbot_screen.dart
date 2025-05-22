import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/models/chat_message.dart';
import 'package:ovarian_cyst_support_app/services/ai_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();

  final List<ChatMessage> _messages = [];
  bool _isComposing = false;
  bool _isTyping = false;
  bool _isOffline = false;

  // Common questions for quick access
  final List<String> _suggestedQuestions = [
    "What are common symptoms of ovarian cysts?",
    "When should I see a doctor?",
    "What treatments are available?",
    "Can diet affect ovarian cysts?",
    "Is surgery always necessary?",
    "Can cysts affect pregnancy?",
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadChatHistory();
    _addWelcomeMessage();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });

      if (_isOffline) {
        _addSystemMessage(
          "You're now offline. The chatbot will provide limited responses based on common questions.",
        );
      } else {
        _addSystemMessage(
          "You're back online. Full AI capabilities are now available.",
        );
      }
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      // In a full implementation, we would load messages from SQLite
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('chat_history');

      if (historyJson != null) {
        // Would decode and load chat history in a full implementation
        // For example:
        // final List<dynamic> decodedMessages = jsonDecode(historyJson);
        // final List<ChatMessage> loadedMessages = decodedMessages
        //    .map((item) => ChatMessage.fromJson(item)).toList();
        // setState(() {
        //    _messages.addAll(loadedMessages);
        // });
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text:
          "Hello! I'm your OvaCare assistant, powered by Google's Gemini AI. I can provide more accurate answers about ovarian cysts, track symptoms, and offer personalized support. How can I help you today?",
      source: MessageSource.bot,
      isOffline: _isOffline,
    );

    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  void _addSystemMessage(String text) {
    final systemMessage = ChatMessage(text: text, source: MessageSource.system);

    setState(() {
      _messages.add(systemMessage);
    });

    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    // Add user message
    setState(() {
      _isComposing = false;
      _messages.add(ChatMessage(text: text, source: MessageSource.user));
      _isTyping = true;
    });

    _scrollToBottom();

    // Get AI response
    try {
      final botResponse = await _aiService.getChatbotResponse(text);

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text: botResponse,
              source: MessageSource.bot,
              isOffline: _isOffline,
            ),
          );
        });

        // Save chat history - would be implemented with the database
        _saveChatHistory();

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text:
                  "I'm sorry, I couldn't process your request. Please try again later.",
              source: MessageSource.bot,
              isOffline: true,
            ),
          );
        });

        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    // Add a slight delay to ensure the list has been built
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveChatHistory() async {
    try {
      // This would save to SQLite in a full implementation
      // For now using a placeholder implementation with SharedPreferences
      // Only commenting out unused variables to show implementation intent

      // final prefs = await SharedPreferences.getInstance();

      // Only save the last 50 messages to prevent excessive storage use
      final messagesToFilter = _messages.length > 50
          ? _messages.sublist(_messages.length - 50)
          : List<ChatMessage>.from(_messages);

      // Would encode and save chat history - implement this when needed
      // String encodedMessages = jsonEncode(messagesToFilter.map((msg) => msg.toJson()).toList());
      // await prefs.setString('chat_history', encodedMessages);

      // Using the variable to avoid unused variable warning
      debugPrint('Prepared ${messagesToFilter.length} messages for saving');
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Offline indicator
          if (_isOffline)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.wifi_off, size: 20, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'re offline. Limited responses available.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
          ),

          // Suggested questions carousel
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedQuestions.length,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () {
                      _handleSubmitted(_suggestedQuestions[index]);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withAlpha(128),
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.7),
                        child: Text(
                          _suggestedQuestions[index],
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // "Bot is typing" indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DefaultTextStyle(
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    child: AnimatedTextKit(
                      animatedTexts: [WavyAnimatedText('Typing...')],
                      isRepeatingAnimation: true,
                      repeatForever: true,
                    ),
                  ),
                ],
              ),
            ),

          // Text input
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withAlpha(25),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      // Voice input would be implemented here
                      _showMessage('Voice input is not yet implemented.');
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onChanged: (text) {
                        setState(() {
                          _isComposing = text.isNotEmpty;
                        });
                      },
                      onSubmitted: _isComposing ? _handleSubmitted : null,
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: _isComposing
                            ? Theme.of(context).primaryColor
                            : Colors.grey[400],
                      ),
                      onPressed: _isComposing
                          ? () => _handleSubmitted(_textController.text)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUserMessage = message.source == MessageSource.user;
    final isSystemMessage = message.source == MessageSource.system;

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            Container(
              height: 36,
              width: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).primaryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety_outlined,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUserMessage
                        ? Theme.of(context).primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUserMessage ? Colors.white : Colors.black87,
                    ),
                    softWrap: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isOffline && !isUserMessage)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OFFLINE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUserMessage) ...[
            Container(
              height: 36,
              width: 36,
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }
}
