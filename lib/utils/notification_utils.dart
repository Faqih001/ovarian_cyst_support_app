import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';

class NotificationUtils {
  static void showTopCenterNotification(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isError ? Colors.red : AppColors.primary,
      behavior:
          SnackBarBehavior.fixed, // Changed to fixed to prevent layout issues
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: duration,
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }
}
