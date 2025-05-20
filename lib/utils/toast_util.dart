import 'package:flutter/material.dart';

class ToastUtil {
  void showToast(
    BuildContext context,
    String message, {
    IconData? icon,
    Color backgroundColor = Colors.black87,
    int duration = 3,
  }) {
    final scaffold = ScaffoldMessenger.of(context);
    
    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: duration),
      ),
    );
  }
}

// Create a single instance to use throughout the app
final toast = ToastUtil();
