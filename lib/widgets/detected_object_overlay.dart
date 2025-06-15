import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

/// Widget that displays an image with object detection overlay
class DetectedObjectOverlay extends StatelessWidget {
  final Uint8List imageBytes;
  final List<DetectedObject> detectedObjects;
  final double confidence;

  const DetectedObjectOverlay({
    super.key,
    required this.imageBytes,
    required this.detectedObjects,
    this.confidence = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Base image with memory optimization
            Image.memory(
              imageBytes,
              fit: BoxFit.contain,
              width: constraints.maxWidth,
              cacheHeight: 800, // Limit cache height
              cacheWidth:
                  (constraints.maxWidth * 1.5)
                      .toInt(), // Appropriate cache width
              gaplessPlayback: true, // Prevents flickering when updating
              filterQuality: FilterQuality.medium, // Optimize quality
            ),
            // Overlay for object detection
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxWidth),
              painter: BoundingBoxPainter(
                imageBytes: imageBytes,
                detectedObjects: detectedObjects,
                confidence: confidence,
                boxWidth: constraints.maxWidth,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter to draw bounding boxes over detected objects
class BoundingBoxPainter extends CustomPainter {
  final Uint8List imageBytes;
  final List<DetectedObject> detectedObjects;
  final double confidence;
  final double boxWidth;

  BoundingBoxPainter({
    required this.imageBytes,
    required this.detectedObjects,
    required this.confidence,
    required this.boxWidth,
  });

  // Define static colors to avoid recreating them for each paint
  static final List<Color> _objectColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
  ];

  // Define static text style to avoid recreating it for each paint
  static const TextStyle _labelTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Filter objects by confidence threshold
    final validObjects =
        detectedObjects.where((obj) => obj.confidence >= confidence).toList();

    // Paint each detected object
    for (var i = 0; i < validObjects.length; i++) {
      final object = validObjects[i];
      final color = _objectColors[i % _objectColors.length];

      final yMin = object.boundingBox[0] / 1000 * size.height;
      final xMin = object.boundingBox[1] / 1000 * size.width;
      final yMax = object.boundingBox[2] / 1000 * size.height;
      final xMax = object.boundingBox[3] / 1000 * size.width;

      final rect = Rect.fromLTRB(xMin, yMin, xMax, yMax);

      // Draw bounding box
      final paint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
      canvas.drawRect(rect, paint);

      // Draw label background
      final labelBg =
          Paint()
            ..color = color.withAlpha(179) // 0.7 opacity (179/255)
            ..style = PaintingStyle.fill;

      final textPainter = TextPainter(
        text: TextSpan(
          text:
              '${object.label} ${(object.confidence * 100).toStringAsFixed(0)}%',
          style: _labelTextStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.drawRect(
        Rect.fromLTWH(xMin, yMin - 20, textPainter.width + 10, 20),
        labelBg,
      );

      textPainter.paint(canvas, Offset(xMin + 5, yMin - 18));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
