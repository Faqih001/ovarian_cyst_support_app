import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A utility class to diagnose Google Maps rendering issues
class MapsDiagnostic {
  /// Runs a diagnostic check to verify the Google Maps API is working
  static Future<bool> checkMapRendering(BuildContext context) async {
    bool isSuccess = false;

    try {
      // Create a temporary controller
      Completer<GoogleMapController> controllerCompleter = Completer();

      // Create a temporary widget to test map rendering
      final testWidget = SizedBox(
        width: 1,
        height: 1,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(-1.286389, 36.817223),
            zoom: 10,
          ),
          onMapCreated: (GoogleMapController controller) {
            controllerCompleter.complete(controller);
          },
          liteModeEnabled: false,
        ),
      );

      // Create a temporary overlay to host the widget
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: -100, // Off-screen
          right: -100, // Off-screen
          child: testWidget,
        ),
      );

      // Insert the overlay
      Overlay.of(context).insert(overlayEntry);

      // Wait for map creation or timeout
      try {
        final controller = await controllerCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        try {
          // Try to get the visible region as a test
          await controller.getVisibleRegion();
          isSuccess = true;
        } catch (e) {
          isSuccess = false;
        } finally {
          controller.dispose();
        }
      } on TimeoutException {
        isSuccess = false;
      }

      // Remove the temporary overlay
      overlayEntry.remove();
    } catch (e) {
      isSuccess = false;
    }

    return isSuccess;
  }
}
