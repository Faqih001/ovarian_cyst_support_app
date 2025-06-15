import 'package:flutter/material.dart';

/// Helper class for Google Maps related utilities
class MapsHelper {
  /// Checks if the map loading failed and returns friendly directions on how to fix it
  static void showMapConfigurationHelp(BuildContext context) {
    // Package name hardcoded for simplicity
    final String packageName = 'com.example.ovarian_cyst_support_app';

    // Check if context is still valid

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Configuration Issue'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'There appears to be an issue with the Google Maps configuration. To fix this:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                '1. Ensure the Google Maps API key in AndroidManifest.xml is correct',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                '2. Verify that "Maps SDK for Android" is enabled in Google Cloud Console',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                '3. Make sure the API key has the correct restrictions and is authorized for this app',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                '4. The SHA-1 fingerprint for this app build must be registered in the Google Cloud Console',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Text(
                'Application Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Package Name: $packageName',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'For detailed setup instructions, refer to docs/google_maps_setup.md',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
