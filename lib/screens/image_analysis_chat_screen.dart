import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import '../services/gemini_service.dart';
import '../models/chat_message.dart';
import '../widgets/chat_message_widget.dart';
import '../services/voice_to_text_service.dart';
import '../utils/image_optimizer.dart';

class ImageAnalysisChatScreen extends StatefulWidget {
  const ImageAnalysisChatScreen({super.key});

  @override
  State<ImageAnalysisChatScreen> createState() =>
      _ImageAnalysisChatScreenState();
}

class _ImageAnalysisChatScreenState extends State<ImageAnalysisChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  final VoiceToTextService _voiceToTextService = VoiceToTextService();
  bool _isProcessing = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Start a new chat session
    _geminiService.startNewChat();

    // Add an enhanced welcome message
    _addBotMessage(
      """Welcome to the OvaCare Image Analysis powered by Google Gemini! 

This tool can analyze medical images with advanced AI capabilities:

• Upload ultrasounds or other medical images 
• Get educational insights on visible structures
• Visual object detection highlights important areas
• View the AI's thinking process behind each analysis

To get started, simply tap the photo button below and upload an image. Remember, this is for educational purposes only and cannot replace professional medical advice.
""",
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    if (_isListening) {
      _voiceToTextService.stopListening();
    }
    // Clean up any temporary image files
    ImageOptimizer.cleanupTemporaryImages();
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
              _textController.text = text;
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

  void _addUserMessage(String text, {Uint8List? imageBytes}) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, imageBytes: imageBytes),
      );
    });
  }

  void _addBotMessage(
    String text, {
    String? thinking,
    List<DetectedObject>? detectedObjects,
    Uint8List? imageBytes,
  }) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          thinkingText: thinking,
          detectedObjects: detectedObjects,
          imageBytes: imageBytes,
        ),
      );
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
      // Limit image size to reduce buffer usage
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        // Reduce maximum dimensions to prevent buffer overruns
        maxWidth: 800,
        maxHeight: 800,
        // Lower image quality to reduce memory usage
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      // Optionally crop the image for better focus
      if (!mounted) return;

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        // Configure cropper to use less memory
        compressQuality: 70,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
            ],
          ),
          WebUiSettings(context: context),
        ],
      );

      final String imagePath = croppedFile?.path ?? pickedFile.path;

      // Use a try-catch block specifically for reading bytes to handle any memory issues
      Uint8List? imageBytes;
      try {
        imageBytes = await XFile(imagePath).readAsBytes();
      } catch (e) {
        if (mounted) {
          showToast(
            'The image is too large to process. Please select a smaller image.',
            context: context,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Check if the image is too large (over 5MB)
      if (imageBytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          showToast(
            'The image is too large. Please select a smaller image or lower quality.',
            context: context,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Optimize the image to prevent buffer overruns
      try {
        // First check if it's a JPEG/PNG image that can be safely processed
        final imageHeader = imageBytes.length > 12
            ? imageBytes.sublist(0, 12)
            : imageBytes;
        final isJpeg =
            imageBytes.length >= 2 &&
            imageBytes[0] == 0xFF &&
            imageBytes[1] == 0xD8;
        final isPng =
            imageBytes.length >= 8 &&
            imageHeader[0] == 0x89 &&
            imageHeader[1] == 0x50 &&
            imageHeader[2] == 0x4E &&
            imageHeader[3] == 0x47;

        if (isJpeg || isPng) {
          final optimizedBytes = await ImageOptimizer.optimizeImageBytes(
            imageBytes,
            maxWidth: 800,
            maxHeight: 800,
            quality: 70,
          );

          // Only use optimized bytes if optimization was successful
          if (optimizedBytes.isNotEmpty) {
            imageBytes = optimizedBytes;
          }
        } else {
          debugPrint('Skipping optimization for unsupported image format');
        }
      } catch (e) {
        debugPrint('Failed to optimize image: $e');
        // Continue with original bytes if optimization fails
      }

      _addUserMessage("Please analyze this image", imageBytes: imageBytes);

      setState(() {
        _isProcessing = true;
      });

      try {
        // Ensure imageBytes is not null
        if (imageBytes == null) {
          throw Exception('Image data is null');
        }

        // First, try to detect objects in the image
        List<DetectedObject> detectedObjects = [];
        try {
          detectedObjects = await _geminiService.detectObjectsInImage(
            imageBytes: imageBytes,
          );
          debugPrint('Detected ${detectedObjects.length} objects');
        } catch (e) {
          debugPrint('Object detection failed: $e');
          // Continue even if object detection fails
        }

        // Now get the analysis response
        final ImageAnalysisResult analysisResult = await _geminiService
            .analyzeImageWithThinking(imageBytes: imageBytes);

        // Extract the response and thinking parts
        final String response = analysisResult.response;
        final String thoughts = analysisResult.thinking;

        // Add the response with the detected objects
        _addBotMessage(
          response,
          thinking: thoughts,
          detectedObjects: detectedObjects.isNotEmpty ? detectedObjects : null,
          imageBytes:
              imageBytes, // Include the image so we can display object detection
        );
      } catch (e) {
        _addBotMessage(
          "I'm having trouble analyzing this image. Please ensure it's a clear medical image and try again, or consult with your healthcare provider.",
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(
          'Error picking or processing the image',
          context: context,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OvaCare AI Analysis'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo.svg',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_search_rounded, color: Colors.white),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Theme.of(
          context,
        ).shadowColor.withAlpha((0.4 * 255).round()),
        actions: [
          // Dropdown menu for additional options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  setState(() {
                    _messages.clear();
                    _geminiService.startNewChat();
                    _addBotMessage(
                      """Welcome to the OvaCare Image Analysis powered by Google Gemini! 

This tool can analyze medical images with advanced AI capabilities:

• Upload ultrasounds or other medical images 
• Get educational insights on visible structures
• Visual object detection highlights important areas
• View the AI's thinking process behind each analysis

To get started, simply tap the photo button below and upload an image. Remember, this is for educational purposes only and cannot replace professional medical advice.
""",
                    );
                  });
                  break;
                case 'about':
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      titlePadding: const EdgeInsets.all(16),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('About Gemini Image Analysis'),
                        ],
                      ),
                      content: const SingleChildScrollView(
                        child: Text(
                          'This feature uses Google\'s Gemini multimodal AI to analyze medical images. '
                          'Gemini can detect objects within images, provide detailed analysis, and generate '
                          'educational insights based on the content of uploaded images.\n\n'
                          'Key capabilities:\n'
                          '• Object detection with bounding boxes\n'
                          '• Educational descriptions of medical structures\n'
                          '• Transparent AI reasoning process\n\n'
                          'This is for educational purposes only. Always consult healthcare professionals for medical advice.',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'reset',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 8),
                    const Text('New Analysis'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    const Text('About Image Analysis'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: false, // Messages appear from top
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    ChatMessageWidget(message: _messages[index]),
              ),
            ),
            const Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              padding: EdgeInsets.only(
                bottom:
                    0, // Remove bottom padding to place it directly above the navigation bar
              ),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        top: 8.0,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? 8.0
            : 0.0, // Add padding only if there's system navigation
      ),
      child: Column(
        children: [
          // Feature description bar
          if (!_isProcessing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureChip(
                        icon: Icons.image_search,
                        label: 'Image Analysis',
                      ),
                      _buildFeatureChip(
                        icon: Icons.lens_blur,
                        label: 'Object Detection',
                      ),
                      _buildFeatureChip(
                        icon: Icons.psychology,
                        label: 'AI Reasoning',
                      ),
                      _buildFeatureChip(
                        icon: Icons.blur_circular,
                        label: 'Segmentation',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Input area
          Row(
            children: [
              // Image upload button with enhanced appearance
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_photo_alternate),
                  iconSize: 24.0,
                  onPressed: (_isProcessing || _isListening)
                      ? null
                      : _pickAndAnalyzeImage,
                  tooltip: 'Upload an image for AI analysis',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_isProcessing || _isListening)
                      ? null
                      : _handleSubmitted,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _isListening
                        ? 'Listening...'
                        : 'Ask about an image...',
                    prefixIcon: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600],
                      ),
                      onPressed: _isProcessing ? null : _toggleListening,
                      tooltip: _isListening ? 'Stop listening' : 'Voice input',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: _isListening
                        ? Theme.of(context).colorScheme.primary.withAlpha(
                            13,
                          ) // 0.05 opacity
                        : Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button with enhanced appearance
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((0.3 * 255).round()),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed:
                      (_isProcessing ||
                          _isListening ||
                          _textController.text.trim().isEmpty)
                      ? null
                      : () => _handleSubmitted(_textController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip({required IconData icon, required String label}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Chip(
        avatar: Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outline.withAlpha((0.3 * 255).round()),
        ),
      ),
    );
  }
}
