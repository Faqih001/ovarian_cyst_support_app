import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:ovarian_cyst_support_app/models/chat_message.dart';
import 'package:ovarian_cyst_support_app/services/ai_service.dart';
import 'package:ovarian_cyst_support_app/services/chat_storage_service.dart';
import 'package:ovarian_cyst_support_app/widgets/voice_recording_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

enum ChatMode {
  textChat,
  imageAnalysis,
}

class ChatbotScreen extends StatefulWidget {
  final ChatMode chatMode;

  const ChatbotScreen({
    super.key,
    this.chatMode = ChatMode.textChat,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final ChatStorageService _chatStorage = ChatStorageService();
  final ImagePicker _picker = ImagePicker();

  // State for currently selected image
  Uint8List? _selectedImageData;
  bool _isImageAnalysisMode = false;
  bool _isAnalyzingImage = false;

  final List<ChatMessage> _messages = [];
  bool _isComposing = false;
  bool _isTyping = false;
  bool _isOffline = false;

  // Track voice processing state
  bool _isProcessingVoice = false;

  // Common questions for quick access
  final List<String> _suggestedQuestions = [
    "What are common symptoms of ovarian cysts?",
    "When should I see a doctor?",
    "What treatments are available?",
    "Can diet affect ovarian cysts?",
    "Is surgery always necessary?",
    "Can cysts affect pregnancy?",
  ];

  // Image analysis specific questions
  final List<String> _imageSuggestedQuestions = [
    "What does this ultrasound show?",
    "Is this a complex or simple cyst?",
    "What size is the cyst in the image?",
    "What are the key features to note?",
    "What should I ask my doctor about this?",
    "How is this type of cyst typically treated?",
  ];

  @override
  void initState() {
    super.initState();
    _isImageAnalysisMode = widget.chatMode == ChatMode.imageAnalysis;
    _checkConnectivity();
    _loadChatHistory();
    _addWelcomeMessage();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    setState(() {
      // Check if we're offline - when the list is empty or contains only ConnectivityResult.none
      _isOffline = connectivityResults.isEmpty ||
          (connectivityResults.contains(ConnectivityResult.none) &&
              connectivityResults.length == 1);
    });

    // Listen for connectivity changes
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      setState(() {
        _isOffline = results.isEmpty ||
            (results.contains(ConnectivityResult.none) && results.length == 1);
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
      // Load messages from Firebase Storage
      final loadedMessages = await _chatStorage.loadMessages();

      if (loadedMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(loadedMessages);
        });
        debugPrint(
            'Loaded ${loadedMessages.length} messages from Firebase Storage');
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  void _addWelcomeMessage() {
    String welcomeText = widget.chatMode == ChatMode.textChat
        ? "Hello! I'm your OvaCare assistant, powered by Google's Gemini AI. I can provide more accurate answers about ovarian cysts, track symptoms, and offer personalized support. How can I help you today?"
        : "Welcome to Image Analysis mode! You can upload images of ultrasounds or other medical images related to ovarian cysts for educational insights. Remember, this is not a diagnostic tool and cannot replace professional medical advice.";

    final welcomeMessage = ChatMessage(
      text: welcomeText,
      source: MessageSource.bot,
      isUser: false,
      timestamp: DateTime.now(),
      isOffline: _isOffline,
    );

    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  void _addSystemMessage(String text) {
    final systemMessage = ChatMessage(
      text: text,
      source: MessageSource.system,
      isUser: false,
      timestamp: DateTime.now(),
    );

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
      _messages.add(ChatMessage(
        text: text,
        source: MessageSource.user,
        isUser: true,
        timestamp: DateTime.now(),
      ));
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
              isUser: false,
              timestamp: DateTime.now(),
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
              isUser: false,
              timestamp: DateTime.now(),
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
      // Only save the last 50 messages to prevent excessive storage use
      final messagesToSave = _messages.length > 50
          ? _messages.sublist(_messages.length - 50)
          : List<ChatMessage>.from(_messages);

      // Save to Firebase Storage
      await _chatStorage.saveMessages(messagesToSave);

      debugPrint('Saved ${messagesToSave.length} messages to Firebase Storage');
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _clearChatHistory() async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text(
              'Are you sure you want to clear your chat history? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Clear chat history in Firebase Storage
                await _chatStorage.clearChatHistory();

                // Clear local messages list except welcome message
                setState(() {
                  _messages.clear();
                  _addWelcomeMessage();
                });

                _showMessage('Chat history cleared');
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
      _showMessage('Failed to clear chat history');
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Flexible(
                child: Text('Chatbot Help', overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gemini',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.auto_awesome, size: 12, color: Colors.green),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This chatbot is powered by Google\'s Gemini AI, designed to provide intelligent and accurate information about ovarian cysts.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildHelpItem(
                  'Voice & Text Input',
                  'Ask questions by typing or using voice messages. Tap the microphone icon to record your question.',
                ),
                const Divider(),
                _buildHelpItem(
                  'Medical Information',
                  'Ask questions about ovarian cysts, symptoms, treatments, etc.',
                ),
                const Divider(),
                _buildHelpItem(
                  'Symptom Tracking',
                  'Ask to track or review your symptoms',
                ),
                const Divider(),
                _buildHelpItem(
                  'Appointment Help',
                  'Get assistance with finding doctors or scheduling appointments',
                ),
                const Divider(),
                _buildHelpItem(
                  'Medication Reminders',
                  'Set up reminders for your medications',
                ),
                const Divider(),
                const Text(
                  'Note: This chatbot provides general information and should not replace professional medical advice.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showVoiceRecordingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return VoiceRecordingWidget(
          onMessageReady: _handleVoiceMessage,
          onError: (error) {
            Navigator.pop(context);
            _showMessage(error);
          },
        );
      },
    );
  }

  void _handleVoiceMessage(String message) async {
    Navigator.pop(context);

    setState(() {
      _isProcessingVoice = true;
      _messages.add(ChatMessage(
        text: "🎤 $message",
        source: MessageSource.user,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // Process the voice message
      final botResponse = await _aiService.getChatbotResponse(
        "Processing voice message: $message",
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _isProcessingVoice = false;
          _messages.add(
            ChatMessage(
              text: botResponse,
              source: MessageSource.bot,
              isOffline: _isOffline,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });

        _saveChatHistory();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isProcessingVoice = false;
          _messages.add(
            ChatMessage(
              text: _isOffline
                  ? "I'm sorry, but I can't process voice messages while offline. Please try again when you're back online, or type your question instead."
                  : "I apologize, but I couldn't process your voice message. This could be due to background noise or unclear audio. Please try again in a quieter environment or type your question.",
              source: MessageSource.bot,
              isOffline: _isOffline,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );

    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageData = bytes;
          _analyzeImage();
        });
      } catch (e) {
        _addSystemMessage("Error processing image: ${e.toString()}");
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImageData == null) return;
    
    setState(() {
      _isAnalyzingImage = true;
    });

    // Add user image message
    _messages.add(ChatMessage(
      text: "Image upload for analysis",
      source: MessageSource.user,
      isUser: true,
      timestamp: DateTime.now(),
      imageBytes: _selectedImageData,
    ));

    _scrollToBottom();

    try {
      // In a real implementation, you would pass the image to the AI service
      final botResponse = await _aiService.getImageAnalysisResponse(_selectedImageData!);

      if (mounted) {
        setState(() {
          _isAnalyzingImage = false;
          _messages.add(
            ChatMessage(
              text: botResponse,
              source: MessageSource.bot,
              isOffline: _isOffline,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });

        // Save chat history
        _saveChatHistory();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzingImage = false;
          _messages.add(
            ChatMessage(
              text: "I'm sorry, I couldn't analyze this image. Please try with another image or check your internet connection.",
              source: MessageSource.bot,
              isOffline: _isOffline,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        // Implement a simpler version of the title that won't overflow
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isImageAnalysisMode ? Icons.image_search : Icons.smart_toy_rounded,
              color: Colors.blue,
              size: 22,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _isImageAnalysisMode ? 'Image Analysis' : 'OvaCare AI',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Add Gemini indicator as an action instead
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gemini',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.auto_awesome, size: 10, color: Colors.green),
              ],
            ),
          ),
          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.grey),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
          // Clear chat history button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: _clearChatHistory,
            tooltip: 'Clear Chat History',
          ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
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
              itemCount: _isImageAnalysisMode 
                  ? _imageSuggestedQuestions.length 
                  : _suggestedQuestions.length,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemBuilder: (context, index) {
                final questionText = _isImageAnalysisMode
                    ? _imageSuggestedQuestions[index]
                    : _suggestedQuestions[index];
                    
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () {
                      _handleSubmitted(questionText);
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
                            maxWidth: MediaQuery.of(context).size.width * 0.7),
                        child: Text(
                          questionText,
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
                  Text(
                    'Typing...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

          // Text input or image upload
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
                  // Show mic or image upload based on mode
                  IconButton(
                    icon: Icon(
                      _isImageAnalysisMode 
                          ? Icons.photo_library
                          : (_isProcessingVoice ? Icons.more_horiz : Icons.mic),
                      color: (_isProcessingVoice || _isAnalyzingImage)
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                    ),
                    onPressed: (_isProcessingVoice || _isAnalyzingImage)
                        ? null
                        : (_isImageAnalysisMode ? _pickImage : () => _showVoiceRecordingModal()),
                    tooltip: _isImageAnalysisMode
                        ? 'Upload image for analysis'
                        : (_isProcessingVoice
                            ? 'Processing voice message...'
                            : 'Send voice message'),
                  ),
                  
                  // Add a camera button for image mode
                  if (_isImageAnalysisMode)
                    IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        color: _isAnalyzingImage
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                      ),
                      onPressed: _isAnalyzingImage
                          ? null
                          : () async {
                              final pickedFile = await _picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 800,
                                maxHeight: 800,
                                imageQuality: 90,
                              );
                              
                              if (pickedFile != null) {
                                try {
                                  final bytes = await pickedFile.readAsBytes();
                                  setState(() {
                                    _selectedImageData = bytes;
                                    _analyzeImage();
                                  });
                                } catch (e) {
                                  _addSystemMessage("Error processing image: ${e.toString()}");
                                }
                              }
                            },
                      tooltip: 'Take a photo',
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
                        hintText: _isImageAnalysisMode 
                            ? 'Ask about the uploaded image...' 
                            : 'Ask a question...',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show image if available
                      if (message.imageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            message.imageBytes!,
                            fit: BoxFit.contain,
                            width: MediaQuery.of(context).size.width * 0.6,
                          ),
                        ),
                      if (message.imageBytes != null)
                        const SizedBox(height: 8),
                      // Text content
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black87,
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
}
