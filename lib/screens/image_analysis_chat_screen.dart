import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import '../services/gemini_service.dart';
import '../widgets/chat_message_widget.dart';

class ImageAnalysisChatScreen extends StatefulWidget {
  const ImageAnalysisChatScreen({Key? key}) : super(key: key);

  @override
  State<ImageAnalysisChatScreen> createState() =>
      _ImageAnalysisChatScreenState();
}

class _ImageAnalysisChatScreenState extends State<ImageAnalysisChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isProcessing = false;
  String? _analysisResult;

  @override
  void initState() {
    super.initState();
    // Start a new chat session
    _geminiService.startNewChat();

    // Add a welcome message
    _addBotMessage(
        "Welcome to the Ovarian Cyst Image Analysis. You can upload images of ultrasounds or other relevant medical images for educational insights. Remember, this is not a diagnostic tool and cannot replace medical advice.");
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addUserMessage(String text, {Uint8List? imageData}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        imageData: imageData,
      ));
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
      ));
    });
  }

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();

    if (text.trim().isEmpty) return;

    _addUserMessage(text);

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await _geminiService.getResponse(text);
      _addBotMessage(response);
    } catch (e) {
      _addBotMessage("I'm having trouble connecting. Please try again later.");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickAndAnalyzeImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Optionally crop the image for better focus
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
        ],
      );

      final String imagePath = croppedFile?.path ?? pickedFile.path;
      final Uint8List imageBytes = await XFile(imagePath).readAsBytes();

      _addUserMessage("Please analyze this image", imageData: imageBytes);

      setState(() {
        _isProcessing = true;
      });

      try {
        final response =
            await _geminiService.analyzeImage(imageBytes: imageBytes);
        _addBotMessage(response);
      } catch (e) {
        _addBotMessage(
            "I'm having trouble analyzing this image. Please ensure it's a clear medical image and try again, or consult with your healthcare provider.");
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      showToast(
        'Error picking or processing the image',
        context: context,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OvaCare Image Analysis'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _geminiService.startNewChat();
                _addBotMessage(
                    "Welcome to the Ovarian Cyst Image Analysis. You can upload images of ultrasounds or other relevant medical images for educational insights. Remember, this is not a diagnostic tool and cannot replace medical advice.");
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: false, // Messages appear from top
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: _isProcessing ? null : _pickAndAnalyzeImage,
            tooltip: 'Upload an image for analysis',
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: _isProcessing ? null : _handleSubmitted,
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
            ),
          ),
          IconButton(
            icon: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.0))
                : Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            onPressed: _isProcessing
                ? null
                : () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }
}
