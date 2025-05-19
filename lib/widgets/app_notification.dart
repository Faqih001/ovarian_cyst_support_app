import 'package:flutter/material.dart';

class AppNotification extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  const AppNotification({
    super.key,
    required this.message,
    this.isError = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        margin: EdgeInsets.only(
          top: 10,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).size.height - 100,
        ),
        decoration: BoxDecoration(
          color: isError ? Colors.red.shade800 : Colors.green.shade800,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51), // equivalent to opacity 0.2
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
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
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}

class NotificationOverlay {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remove any existing notification first
    hide();

    // Create the overlay entry
    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 10,
        left: 0,
        right: 0,
        child: AppNotification(
          message: message,
          isError: isError,
          onDismiss: hide,
        ),
      ),
    );

    // Show the overlay
    Overlay.of(context).insert(_currentOverlay!);

    // Auto hide after duration
    Future.delayed(duration, () {
      hide();
    });
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, isError: false);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, isError: true);
  }
}
