import 'package:flutter/material.dart';

class GeminiBadge extends StatelessWidget {
  final double size;

  const GeminiBadge({
    super.key,
    this.size = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * size, vertical: 2 * size),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(30),
        borderRadius: BorderRadius.circular(10 * size),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gemini',
            style: TextStyle(
              fontSize: 12 * size,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 2 * size),
          Icon(Icons.auto_awesome, size: 12 * size, color: Colors.green),
        ],
      ),
    );
  }
}
