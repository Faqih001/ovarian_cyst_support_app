import 'package:flutter/material.dart';

class AppNotifications {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      isError: false,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      isError: true,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required bool isError,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Hide any existing notification
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show new notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          right: 20,
          left: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration,
      ),
    );
  }
}
