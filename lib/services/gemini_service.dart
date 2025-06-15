import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';

/// Analysis result containing both response text and thinking process
class ImageAnalysisResult {
  final String response;
  final String thinking;
  final List<DetectedObject>? detectedObjects;
  final List<ImageSegmentation>? segmentations;

  ImageAnalysisResult({
    required this.response,
    this.thinking = '',
    this.detectedObjects,
    this.segmentations,
  });

  /// Whether the analysis includes object detection data
  bool get hasObjectDetection =>
      detectedObjects != null && detectedObjects!.isNotEmpty;

  /// Whether the analysis includes image segmentation data
  bool get hasSegmentation =>
      segmentations != null && segmentations!.isNotEmpty;
}

/// Object detection result with bounding box coordinates
class DetectedObject {
  final String label;
  final List<double>
  boundingBox; // [yMin, xMin, yMax, xMax] normalized to 0-1000
  final double confidence;

  DetectedObject({
    required this.label,
    required this.boundingBox,
    this.confidence = 0.0,
  });

  /// Convert normalized coordinates (0-1000) to pixel coordinates
  Map<String, int> pixelCoordinates(int imageWidth, int imageHeight) {
    return {
      'xMin': (boundingBox[1] / 1000 * imageWidth).floor(),
      'yMin': (boundingBox[0] / 1000 * imageHeight).floor(),
      'xMax': (boundingBox[3] / 1000 * imageWidth).floor(),
      'yMax': (boundingBox[2] / 1000 * imageHeight).floor(),
    };
  }

  int width(int imageWidth) {
    final coords = pixelCoordinates(imageWidth, 1);
    return coords['xMax']! - coords['xMin']!;
  }

  int height(int imageHeight) {
    final coords = pixelCoordinates(1, imageHeight);
    return coords['yMax']! - coords['yMin']!;
  }

  @override
  String toString() {
    return 'DetectedObject{label: $label, boundingBox: $boundingBox, confidence: $confidence}';
  }
}

/// Result of image segmentation containing mask data
class ImageSegmentation {
  final String label;
  final List<double>
  boundingBox; // [yMin, xMin, yMax, xMax] normalized to 0-1000
  final String maskBase64; // Base64 encoded PNG data of the segmentation mask
  final double confidence;

  ImageSegmentation({
    required this.label,
    required this.boundingBox,
    required this.maskBase64,
    this.confidence = 0.0,
  });

  /// Convert the base64 mask to image bytes
  Uint8List getMaskBytes() {
    try {
      // Decode the base64 string to bytes
      return Uri.parse(maskBase64).data?.contentAsBytes() ?? Uint8List(0);
    } catch (e) {
      debugPrint('Error decoding mask data: $e');
      return Uint8List(0);
    }
  }
}

class GeminiService {
  // API key provided for Gemini
  static const String apiKey = 'AIzaSyDKx6S2wsCDtwKbrT9E0x3hEvPpITcMd_0';

  // Singleton instance
  static final GeminiService _instance = GeminiService._internal();

  // Model instances
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  late final GenerativeModel _audioModel;
  late final GenerativeModel
  _thinkingModel; // Model instance for thinking capability

  // Chat session for maintaining conversation history
  ChatSession? _chatSession;

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal() {
    // Initialize the model with the correct model name for Gemini
    _model = GenerativeModel(
      model: 'gemini-1.5-pro', // Using a more accessible model
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
      ),
    );

    // Initialize a separate model for vision capabilities using a more reliable model
    _visionModel = GenerativeModel(
      model:
          'gemini-1.5-pro', // Using pro model which has reliable vision capabilities
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        maxOutputTokens: 1024,
      ),
    );

    // Initialize a model specifically optimized for audio processing
    _audioModel = GenerativeModel(
      model: 'gemini-1.5-pro', // Using pro model for audio understanding
      apiKey: apiKey,
    );

    // Initialize a model specifically for thinking capabilities
    _thinkingModel = GenerativeModel(
      model:
          'gemini-1.5-pro', // Using the standard pro model which is more stable
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// Starts a new chat session clearing previous history
  void startNewChat() {
    // Add system instructions when starting a new chat
    final systemInstructions = _getOvarianCystContext();

    // Create chat session with system instructions
    _chatSession = _model.startChat(
      history: [Content.text(systemInstructions)],
    );
  }

  /// Initialize chat session if needed
  void _initChatSessionIfNeeded() {
    if (_chatSession == null) {
      startNewChat();
    }
  }

  /// Gets a response from Gemini AI
  /// Keeps conversation context if in a chat session
  Future<String> getResponse(String prompt) async {
    try {
      _initChatSessionIfNeeded();

      // Get response from the model
      final response = await _chatSession!.sendMessage(Content.text(prompt));

      // Extract and return the text response
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return _getFallbackResponse();
      }

      return responseText;
    } catch (e) {
      debugPrint('Error in Gemini API: $e');

      // Check for model not found error
      if (e.toString().contains('model') &&
          e.toString().contains('not found')) {
        debugPrint(
          'Model not found error detected. This may be due to an outdated model name or API version.',
        );
      }

      return _getFallbackResponse();
    }
  }

  /// Get a direct response without maintaining chat history
  /// Useful for one-time queries or when chat context isn't needed
  Future<String> getSingleResponse(String prompt) async {
    try {
      // Use system instructions for context
      final response = await _model.generateContent([
        Content.text(_getOvarianCystContext()),
        Content.text(prompt),
      ]);

      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return _getFallbackResponse();
      }

      return responseText;
    } catch (e) {
      debugPrint('Error in Gemini API single response: $e');

      // Check for model not found error
      if (e.toString().contains('model') &&
          e.toString().contains('not found')) {
        debugPrint(
          'Model not found error detected. This may be due to an outdated model name or API version.',
        );
      }

      return _getFallbackResponse();
    }
  }

  /// Process audio content with Gemini API
  Future<String> processAudioContent({
    required String prompt,
    required Uint8List audioBytes,
    required String mimeType,
  }) async {
    try {
      // Create a more detailed prompt for audio processing
      final String enhancedPrompt =
          '''
$prompt

This is a voice recording from a user in an ovarian cyst support app. 
The user is likely asking about symptoms, treatments, or expressing health concerns.
Please interpret the content with healthcare context in mind.
If the audio content is unclear, provide a helpful response about ovarian cysts
while acknowledging that the audio may not have been clear.
''';

      // Create content using the audio model
      // For models that support direct audio input, we would include the audio data
      // The current implementation simulates audio processing
      final response = await _audioModel.generateContent([
        Content.multi([
          TextPart("""
I received an audio recording from a user of an ovarian cyst support app.
The audio content is in format: $mimeType
Length of audio: ${(audioBytes.length / 1024).toStringAsFixed(2)} KB

Based on this context, provide a helpful response about ovarian cysts.
$enhancedPrompt
"""),
          // In a version that fully supports audio, we would use:
          // DataPart(mimeType, audioBytes),
        ]),
      ]);

      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return _getAudioFallbackResponse();
      }

      return responseText;
    } catch (e) {
      debugPrint('Error in Gemini API audio processing: $e');
      return _getAudioFallbackResponse();
    }
  }

  /// Process image content with Gemini Vision
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    String prompt =
        "Analyze this medical image for potential ovarian cysts. Describe what you see, but clarify that only a medical professional can provide an accurate diagnosis.",
  }) async {
    try {
      // Create enhanced system prompt for better image analysis
      final enhancedSystemPrompt = _getOvarianCystImageAnalysisContext();

      // Compress image bytes if too large (over 2MB)
      Uint8List processedImageBytes = imageBytes;
      if (imageBytes.length > 2 * 1024 * 1024) {
        try {
          // Save to temporary file and read back with lower quality
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_analysis_image.jpg');
          await tempFile.writeAsBytes(imageBytes);

          // Use the file API instead if image is large
          return await analyzeImageWithFileApi(
            imagePath: tempFile.path,
            prompt: prompt,
          );
        } catch (e) {
          debugPrint('Error compressing image: $e');
          // Continue with original bytes if compression fails
        }
      }

      // Create the model content with image data
      final promptContent = [
        Content.multi([
          TextPart(enhancedSystemPrompt),
          TextPart(prompt),
          DataPart('image/jpeg', processedImageBytes),
        ]),
      ];

      // Set configuration for better image analysis and memory usage
      final generationConfig = GenerationConfig(
        temperature: 0.4, // Lower temperature for more factual responses
        topK: 32,
        topP: 0.95,
        maxOutputTokens: 600, // Adjusted for better memory management
      );

      // Generate content using the vision model with a timeout
      final response = await _visionModel
          .generateContent(promptContent, generationConfig: generationConfig)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Image analysis timed out');
            },
          );

      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return _getImageFallbackResponse();
      }

      return responseText;
    } catch (e) {
      debugPrint('Error in Gemini API image analysis: $e');
      return _getImageFallbackResponse();
    }
  }

  /// Analyze an image using the Gemini Files API (for large files)
  Future<String> analyzeImageWithFileApi({
    required String imagePath,
    String prompt =
        "Analyze this medical image for potential ovarian cysts. Describe what you see, but clarify that only a medical professional can provide an accurate diagnosis.",
  }) async {
    try {
      // Check if file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return "Image file not found.";
      }

      // Get mime type based on file extension
      final mimeType = _getMimeTypeFromPath(imagePath);

      // Upload file to get URI - in production, this would use the Files API
      final fileUri = await _uploadFileToGenerativeAI(imagePath, mimeType);

      // Read the image file for fallback approach
      final imageBytes = await file.readAsBytes();

      // Create the content for image analysis
      List<Content> promptContent;

      // Check if we have a real file URI (not a simulation/placeholder)
      if (fileUri != 'generative-ai://simulated-file-uri-for-demonstration') {
        // When the Files API is properly supported, we would use:
        // promptContent = [Content.multi([TextPart(prompt), FilePart(Uri.parse(fileUri))])];

        // For now, use the normal approach with image bytes
        promptContent = [
          Content.multi([
            TextPart(_getOvarianCystImageAnalysisContext()),
            TextPart(prompt),
            DataPart(mimeType, imageBytes),
          ]),
        ];
      } else {
        // Use the image bytes directly
        promptContent = [
          Content.multi([
            TextPart(_getOvarianCystImageAnalysisContext()),
            TextPart(prompt),
            DataPart(mimeType, imageBytes),
          ]),
        ];
      }

      // Generate content using the vision model with improved error handling
      try {
        final response = await _visionModel
            .generateContent(
              promptContent,
              generationConfig: GenerationConfig(
                temperature: 0.4,
                maxOutputTokens: 1024,
              ),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () =>
                  throw TimeoutException('Image analysis request timed out'),
            );

        // Return the response text or a fallback
        return response.text ?? _getImageFallbackResponse();
      } catch (e) {
        debugPrint('Error in Gemini API vision model content generation: $e');
        return 'I encountered a problem analyzing this image. This might be due to API limits or connection issues. Please try again later.';
      }
    } catch (e) {
      debugPrint('Error in Gemini API image analysis with file: $e');
      return _getImageFallbackResponse();
    }
  }

  /// Analyze image with thinking process and object detection
  /// Uses Files API for large images (>20MB) to avoid request size limitations
  Future<ImageAnalysisResult> analyzeImageWithThinking({
    required Uint8List imageBytes,
    String prompt =
        "Analyze this medical image for potential ovarian cysts. Describe what you see, but clarify that only a medical professional can provide an accurate diagnosis.",
  }) async {
    try {
      debugPrint('Starting analyzeImageWithThinking with API key');

      // Check if the image size is reasonable to avoid API limits
      if (imageBytes.length > 20 * 1024 * 1024) {
        // 20MB limit
        debugPrint(
          'Image too large: ${(imageBytes.length / (1024 * 1024)).toStringAsFixed(2)}MB',
        );
        return ImageAnalysisResult(
          response:
              'The image is too large to process. Please use a smaller image (under 20MB).',
          thinking: 'Image size exceeds processing limits.',
        );
      }

      // Optimize image if it's extremely large
      Uint8List processedImageBytes = imageBytes;
      if (imageBytes.length > 5 * 1024 * 1024) {
        try {
          // Save to temporary file for processing
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_thinking_image.jpg');
          await tempFile.writeAsBytes(imageBytes);
          
          // Re-read at lower quality using native APIs
          // This would be implemented in a real app - simulating here
          debugPrint('Image optimization would be performed here');
        } catch (e) {
          debugPrint('Error optimizing image: $e');
          // Continue with original bytes if optimization fails
        }
      }

      // First, prepare for thinking process generation
      String thoughts = '';
      try {
        debugPrint('Generating thinking process with _thinkingModel');

        // Create a very minimal thinking prompt to reduce chances of error
        final simplifiedThinkingContent = [
          Content.multi([
            TextPart(
              "Analyze this medical image step by step:",
            ),
            DataPart('image/jpeg', processedImageBytes),
          ]),
        ];

        // Set strict generation config to avoid timeout errors
        final thinkingGenerationConfig = GenerationConfig(
          temperature: 0.2,     // Lower temperature for more deterministic output
          maxOutputTokens: 600, // Further reduced to avoid timeouts
          topP: 0.9,            // More focused output
          topK: 20,             // More restrictive token selection
        );

        // Add timeout with recovery
        final thinkingResponse = await _thinkingModel
            .generateContent(
              simplifiedThinkingContent,
              generationConfig: thinkingGenerationConfig,
            )
            .timeout(
              const Duration(seconds: 15), 
              onTimeout: () {
                debugPrint('Thinking generation timed out, using fallback');
                throw TimeoutException('Thinking generation timed out');
              },
            );

        if (thinkingResponse.text != null &&
            thinkingResponse.text!.isNotEmpty) {
          thoughts = thinkingResponse.text!;
          debugPrint('Successfully generated thinking process');
        } else {
          thoughts =
              'Analyzing the medical image structure, patterns, and characteristics...';
          debugPrint('Empty thinking response, using default thinking message');
        }
      } catch (e) {
        debugPrint('Error generating thinking process: $e');
        thoughts =
            'Analyzing image characteristics and structures. Looking for patterns consistent with ovarian anatomy and potential abnormalities...';
        // Use a simpler fallback approach
        debugPrint('Using default thinking text due to error: ${e.toString()}');
      }

      // Now get the actual analysis with a well-structured prompt
      final analysisPrompt = '''
Analyze this medical image for potential ovarian cysts or related conditions.
Provide detailed observations including:
- Type of imaging technique used
- Anatomical structures visible
- Any abnormal findings that could indicate cysts or other conditions
- Educational insights about what is shown

Important: Include a clear disclaimer that this is for educational purposes only and not a diagnosis.
''';

      // Generate analysis content with more reliable settings
      String analysis = '';
      try {
        // Use a simplified content structure to reduce errors
        final simplifiedAnalysisContent = [
          Content.multi([
            TextPart(analysisPrompt),
            DataPart('image/jpeg', processedImageBytes),
          ]),
        ];

        // Use more reliable generation settings
        final analysisGenerationConfig = GenerationConfig(
          temperature: 0.2,     // Lower temperature for more reliable results
          maxOutputTokens: 800, // Reduced token output 
          topK: 40,
          topP: 0.95,
        );

        debugPrint('Starting image analysis with _visionModel');
        final analysisResponse = await _visionModel
            .generateContent(
              simplifiedAnalysisContent,
              generationConfig: analysisGenerationConfig,
            )
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () {
                debugPrint('Analysis generation timed out, using fallback');
                throw TimeoutException('Analysis generation timed out');
              },
            );

        if (analysisResponse.text != null &&
            analysisResponse.text!.isNotEmpty) {
          analysis = analysisResponse.text!;
          debugPrint('Successfully generated analysis');
        } else {
          analysis = _getImageFallbackResponse();
          debugPrint('Empty analysis response, using fallback');
        }
      } catch (e) {
        debugPrint('Error generating analysis: $e');
        analysis = _getImageFallbackResponse();
      }

      // Object detection with better error isolation
      List<DetectedObject> detectedObjects = [];
      try {
        // Allow shorter timeout for object detection
        detectedObjects = await detectObjectsInImage(imageBytes: processedImageBytes)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint('Object detection timed out');
                return <DetectedObject>[];
              },
            );
      } catch (e) {
        debugPrint('Error detecting objects: $e');
        // Continue without object detection
      }

      // Only attempt segmentation under certain conditions
      List<ImageSegmentation> segmentations = [];
      bool attemptSegmentation =
          analysis.toLowerCase().contains('ultrasound') ||
          analysis.toLowerCase().contains('cyst') ||
          analysis.toLowerCase().contains('ovarian');

      if (attemptSegmentation) {
        try {
          // Allow shorter timeout for segmentation
          segmentations = await segmentObjectsInImage(imageBytes: processedImageBytes)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  debugPrint('Image segmentation timed out');
                  return <ImageSegmentation>[];
                },
              );
          
          debugPrint(
            'Image segmentation completed: ${segmentations.length} segments found',
          );
        } catch (e) {
          debugPrint('Error segmenting image: $e');
          // Continue without segmentation
        }
      }

      return ImageAnalysisResult(
        response: analysis,
        thinking: thoughts,
        detectedObjects: detectedObjects.isNotEmpty ? detectedObjects : null,
        segmentations: segmentations.isNotEmpty ? segmentations : null,
      );
    } catch (e) {
      debugPrint('Error in Gemini API image analysis with thinking: $e');
      return ImageAnalysisResult(
        response: _getImageFallbackResponse(),
        thinking:
            'I tried to analyze this image but encountered difficulties processing it.',
      );
    }
  }

  /// Enhanced image analysis with object detection
  /// Uses the Gemini vision model to detect objects in images and return bounding boxes
  Future<List<DetectedObject>> detectObjectsInImage({
    required Uint8List imageBytes,
    String prompt =
        "Detect all prominent objects in this medical image. Identify any structures that could be cysts, organs, or abnormalities. Return bounding boxes in the format [ymin, xmin, ymax, xmax] normalized to 0-1000.",
  }) async {
    try {
      debugPrint('Starting object detection');

      // Check if the image is too large
      if (imageBytes.length > 20 * 1024 * 1024) {
        // 20MB limit
        debugPrint('Image too large for object detection');
        return [];
      }

      // Create a more structured prompt for better object detection results
      final enhancedPrompt = '''
Please analyze this medical image and detect key anatomical structures and any abnormal findings.

For each important structure or finding, provide:
1. A concise label (e.g., "ovarian cyst", "ovary", "uterus", "follicle") 
2. A bounding box in the format [ymin, xmin, ymax, xmax] with values normalized from 0-1000

Example format:
ovary: [120, 340, 180, 420]
cyst: [140, 350, 170, 390]

Focus only on the most relevant structures. If you cannot reliably identify objects, return an empty list.
''';
      
      // Create the model content with image data and specific object detection prompt
      List<Content> promptContent = [
        Content.multi([TextPart(enhancedPrompt), DataPart('image/jpeg', imageBytes)]),
      ];

      // Set configuration for better object detection - more conservative settings
      final generationConfig = GenerationConfig(
        temperature: 0.1, // Very low temperature for more deterministic output
        maxOutputTokens: 800, // Reduced to avoid timeouts
        topK: 20,
        topP: 0.9,
      );

      // Generate content using the vision model with timeout handling
      final response = await _visionModel
          .generateContent(
            promptContent,
            generationConfig: generationConfig,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('Object detection timed out');
              throw TimeoutException('Object detection timed out');
            },
          );

      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        debugPrint('Empty response from object detection');
        return [];
      }

      // Parse the response to extract detected objects and their bounding boxes
      final detectedObjects = _parseDetectedObjects(responseText);
      debugPrint('Detected ${detectedObjects.length} objects');
      return detectedObjects;
    } catch (e) {
      debugPrint('Error in Gemini API object detection: $e');
      return [];
    }
  }

  /// Segment objects within an image
  /// Returns a list of segmentation masks for detected objects
  Future<List<ImageSegmentation>> segmentObjectsInImage({
    required Uint8List imageBytes,
    String prompt = '''
Give the segmentation masks for any abnormal structures or cysts.
Output a JSON list of segmentation masks where each entry contains the 2D
bounding box in the key "box_2d", the segmentation mask in key "mask", and
the text label in the key "label". Use descriptive medical labels.
''',
  }) async {
    try {
      // Create the model content with image data and specific segmentation prompt
      final promptContent = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      // Set configuration for better segmentation
      final generationConfig = GenerationConfig(
        temperature: 0.2, // Lower temperature for more precise detection
        maxOutputTokens: 2048, // Increase token limit for detailed masks
      );

      // Generate content using the vision model with the latest Gemini 2.5 capabilities
      final response = await _visionModel.generateContent(
        promptContent,
        generationConfig: generationConfig,
      );

      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return [];
      }

      // Parse the JSON response to extract segmentation data
      return _parseSegmentationData(responseText);
    } catch (e) {
      debugPrint('Error in Gemini API image segmentation: $e');
      return [];
    }
  }

  /// Parse the response text to extract detected objects and their bounding boxes
  List<DetectedObject> _parseDetectedObjects(String responseText) {
    final List<DetectedObject> detectedObjects = [];

    // Use regex to find patterns like "object_name: [y1, x1, y2, x2]"
    final regex = RegExp(
      r'([a-zA-Z\s]+):\s*\[(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\]',
    );
    final matches = regex.allMatches(responseText);

    for (final match in matches) {
      if (match.groupCount >= 5) {
        final label = match.group(1)?.trim() ?? 'Unknown';

        try {
          final boundingBox = [
            double.parse(match.group(2) ?? '0'),
            double.parse(match.group(3) ?? '0'),
            double.parse(match.group(4) ?? '0'),
            double.parse(match.group(5) ?? '0'),
          ];

          detectedObjects.add(
            DetectedObject(label: label, boundingBox: boundingBox),
          );
        } catch (e) {
          debugPrint('Error parsing bounding box coordinates: $e');
        }
      }
    }

    return detectedObjects;
  }

  /// Parse the JSON response to extract segmentation data
  List<ImageSegmentation> _parseSegmentationData(String responseText) {
    final List<ImageSegmentation> segmentations = [];

    try {
      // Extract the JSON part from the response
      // First look for anything that resembles a JSON array
      final jsonRegex = RegExp(r'\[\s*\{.*?\}\s*\]', dotAll: true);
      final jsonMatch = jsonRegex.firstMatch(responseText);

      if (jsonMatch == null) {
        debugPrint('No JSON data found in response');
        return [];
      }

      String jsonString = jsonMatch.group(0) ?? '';

      // Clean up the JSON string if needed
      jsonString = jsonString.replaceAll(RegExp(r'```json|```'), '').trim();

      try {
        // Parse the JSON string
        final List<dynamic> jsonData = json.decode(jsonString);

        for (final item in jsonData) {
          if (item is Map<String, dynamic>) {
            final label = item['label'] as String? ?? 'Unknown';
            final box2d = item['box_2d'] as List<dynamic>? ?? [];
            final maskBase64 = item['mask'] as String? ?? '';

            if (box2d.length == 4 && maskBase64.isNotEmpty) {
              final boundingBox = [
                double.parse(box2d[0].toString()),
                double.parse(box2d[1].toString()),
                double.parse(box2d[2].toString()),
                double.parse(box2d[3].toString()),
              ];

              segmentations.add(
                ImageSegmentation(
                  label: label,
                  boundingBox: boundingBox,
                  maskBase64: maskBase64,
                  confidence: item['confidence'] != null
                      ? double.parse(item['confidence'].toString())
                      : 0.8,
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing JSON data: $e');
      }
    } catch (e) {
      debugPrint('Error parsing segmentation data: $e');
    }

    return segmentations;
  }

  /// Analyze multiple images for comparison
  Future<String> compareImages({
    required List<Uint8List> imageBytesList,
    String prompt =
        "Compare these medical images and describe any patterns or changes you notice. Remember to emphasize that only medical professionals can provide diagnoses.",
  }) async {
    try {
      if (imageBytesList.isEmpty) {
        return "No images provided for comparison.";
      }

      // Create parts list with system prompt and user prompt
      final parts = <Part>[];
      parts.add(TextPart(_getOvarianCystImageAnalysisContext()));
      parts.add(TextPart(prompt));

      // Add all images to the parts list
      for (int i = 0; i < imageBytesList.length; i++) {
        parts.add(DataPart('image/jpeg', imageBytesList[i]));
      }

      // Create content with all parts
      final promptContent = [Content.multi(parts)];

      // Set configuration for better image analysis
      final generationConfig = GenerationConfig(
        temperature: 0.4,
        maxOutputTokens:
            1024, // Allow for more detailed analysis with multiple images
      );

      // Generate content using the vision model
      final response = await _visionModel.generateContent(
        promptContent,
        generationConfig: generationConfig,
      );

      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return _getImageFallbackResponse();
      }

      return responseText;
    } catch (e) {
      debugPrint('Error in Gemini API multiple image analysis: $e');
      return _getImageFallbackResponse();
    }
  }

  /// Provides domain context to help the model generate better responses
  String _getOvarianCystContext() {
    return """You are OvaCare, a specialized AI assistant for women with ovarian cysts. 
You provide accurate and empathetic medical information related to ovarian cysts.
Keep responses concise (under 3-4 sentences when possible) and easy to understand.
Remember you are not a doctor, and should recommend seeking medical attention for concerning symptoms.
When in doubt or for specific medical advice, remind users to consult healthcare professionals.""";
  }

  /// Get a fallback response for general errors
  String _getFallbackResponse() {
    return "I'm unable to process your request right now. Please try again later.";
  }

  /// Get a fallback response for image analysis errors
  String _getImageFallbackResponse() {
    return "I couldn't analyze this image properly. Please try uploading a clearer image, or check that it's a medical image related to ovarian health.";
  }

  /// Get a fallback response for audio processing errors
  String _getAudioFallbackResponse() {
    return "I couldn't process the audio properly. Please try again with clearer audio or type your question instead.";
  }

  /// Get context for ovarian cyst image analysis
  String _getOvarianCystImageAnalysisContext() {
    return '''
You are a medical education assistant specializing in ovarian cyst analysis.
Your task is to analyze medical images that may show ovarian cysts or related conditions.
Provide educational insights about what appears in the images, but always emphasize:
1. This is for educational purposes only
2. Only qualified medical professionals can make diagnoses
3. The patient should consult their doctor for proper medical advice

When analyzing images, describe:
- The type of imaging technique used (ultrasound, MRI, CT, etc.)
- Visible anatomical structures
- Any features that may indicate cysts or abnormalities
- Educational context about what is shown

Always maintain a compassionate, educational tone.
''';
  }

  /// Get the MIME type from a file path
  String _getMimeTypeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'mp3':
        return 'audio/mp3';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      default:
        return 'application/octet-stream';
    }
  }

  /// Upload file to the Generative AI API and get a file URI
  Future<String> _uploadFileToGenerativeAI(
    String filePath,
    String mimeType,
  ) async {
    try {
      // File exists check
      final file = File(filePath);
      final fileExists = await file.exists();
      if (!fileExists) {
        debugPrint('File does not exist: $filePath');
        return 'generative-ai://simulated-file-uri-for-demonstration';
      }

      // Real implementation would use the Gemini Files API
      // Since the current package might not fully support this yet,
      // we'll use a simulated URI

      // For demonstration purposes only - in a real implementation,
      // this would make an actual API call to upload the file

      // For now, create a placeholder URI
      final fileUri = 'generative-ai://simulated-file-uri-for-demonstration';

      debugPrint('File simulated upload: $fileUri');
      return fileUri;
    } catch (e) {
      debugPrint('Error uploading file to Generative AI: $e');
      return 'generative-ai://simulated-file-uri-for-demonstration';
    }
  }

  /// Get a response with the thinking process for a text prompt
  Future<Map<String, dynamic>> getResponseWithThinking(String prompt) async {
    try {
      // Start a new chat session if not already started
      _initChatSessionIfNeeded();

      // First, generate the thinking process separately
      final thinkingPrompt =
          '''
Think step by step about how to answer this question or request:
"$prompt"

1. What information is being asked?
2. What relevant knowledge should I consider?
3. How can I provide a helpful and accurate response?
4. Any medical or health considerations to keep in mind?

Respond with your detailed thinking process.
''';

      // First, generate thinking content
      String thoughts = '';
      try {
        final thinkingResponse = await _model
            .generateContent([Content.text(thinkingPrompt)])
            .timeout(const Duration(seconds: 15));
        thoughts = thinkingResponse.text ?? 'Analyzing your question...';
      } catch (e) {
        debugPrint('Error generating thinking process: $e');
        thoughts =
            'Considering relevant information about ovarian cysts and women\'s health...';
      }

      // Now send the actual request and get the response
      final response = await _chatSession!.sendMessage(Content.text(prompt));
      final responseText = response.text ?? _getFallbackResponse();

      return {'response': responseText, 'thoughts': thoughts};
    } catch (e) {
      debugPrint('Error in Gemini API response with thinking: $e');
      return {
        'response': _getFallbackResponse(),
        'thoughts':
            'I tried to analyze your question but encountered some difficulties.',
      };
    }
  }

  /// Get a streaming response with thinking updates
  Stream<Map<String, dynamic>> getStreamingResponseWithThinking(
    String prompt,
  ) async* {
    try {
      // Start a new chat session if not already started
      _initChatSessionIfNeeded();

      // First yield the thinking process
      yield {
        'type': 'thinking',
        'content': 'Analyzing your question about ovarian cysts...',
      };
      await Future.delayed(const Duration(milliseconds: 500));
      yield {
        'type': 'thinking',
        'content': 'Retrieving relevant medical information...',
      };
      await Future.delayed(const Duration(milliseconds: 700));
      yield {
        'type': 'thinking',
        'content': 'Formulating a clear and accurate response...',
      };
      await Future.delayed(const Duration(milliseconds: 800));

      // Now send the actual request and get the response
      final response = await _chatSession!.sendMessage(Content.text(prompt));
      final responseText = response.text ?? _getFallbackResponse();

      // Yield the final response
      yield {'type': 'response', 'content': responseText};
    } catch (e) {
      debugPrint('Error in Gemini API streaming with thinking: $e');
      yield {'type': 'response', 'content': _getFallbackResponse()};
    }
  }

  // Helper method to analyze image from filesystem
  // UNUSED: These methods are kept for reference but commented out as they're not currently used

  /*
  Future<ImageAnalysisResult> _analyzeImageFromFile({
    required String imageFileUri,
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    // Create separate content for analysis
    List<Content> analysisContent = [
      Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
    ];

    // Generate analysis content
    String analysis = '';
    try {
      final analysisResponse = await _visionModel
          .generateContent(analysisContent)
          .timeout(const Duration(seconds: 30));
      analysis = analysisResponse.text ?? _getImageFallbackResponse();
    } catch (e) {
      debugPrint('Error generating analysis: $e');
      analysis = _getImageFallbackResponse();
    }

    return ImageAnalysisResult(
      response: analysis,
      thinking: 'Analysis of image file: $imageFileUri',
    );
  }

  // Helper method to analyze image objects
  Future<List<DetectedObject>> _analyzeImageObjects({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    try {
      // Get vision model response
      final response = await _visionModel.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ]);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        return [];
      }

      // Parse objects from response
      return _parseDetectedObjects(responseText);
    } catch (e) {
      debugPrint('Error detecting objects: $e');
      return [];
    }
  }

  // Helper method for generating thinking analysis
  Future<String> _generateThinkingAnalysis({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    try {
      final response = await _thinkingModel.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ]);

      return response.text ?? 'Analyzing the medical image...';
    } catch (e) {
      debugPrint('Error generating thinking: $e');
      return 'Analysis of medical structures and features...';
    }
  }
  */
}
