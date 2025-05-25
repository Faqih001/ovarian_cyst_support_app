import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service to handle Firebase App Check initialization and maintenance
///
/// Firebase App Check helps protect your backend resources from abuse by
/// ensuring that API requests are coming from your app, not from a malicious source.
class AppCheckService {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;
  static Timer? _tokenRefreshTimer;
  static const int _tokenRefreshInterval = 45; // minutes

  /// Initialize Firebase App Check with appropriate provider based on platform and build mode
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // First try - standard implementation
      await FirebaseAppCheck.instance.activate(
        // Use appropriate provider based on platform and build mode
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        // For iOS, device check is used in debug mode, app attest in release
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
        // Use real reCAPTCHA key for web implementation
        webProvider: kIsWeb
            ? ReCaptchaV3Provider('6Lf16b8pAAAAAEkLzl-RQQ9cj7dLWm_32QDmEr_d')
            : null,
      );

      // Force token refresh to ensure we have a valid token at startup
      await _refreshToken();

      // Setup periodic token refresh to prevent expiration issues
      _setupPeriodicTokenRefresh();

      _isInitialized = true;
      _logger.i('Firebase App Check initialized successfully');
    } catch (e) {
      _logger.w(
          'Initial App Check activation failed: $e, attempting fallback method');

      // Fallback method - try with debug provider only
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
          webProvider: kIsWeb
              ? ReCaptchaV3Provider('6Lf16b8pAAAAAEkLzl-RQQ9cj7dLWm_32QDmEr_d')
              : null,
        );

        await _refreshToken();
        _setupPeriodicTokenRefresh();

        _isInitialized = true;
        _logger
            .i('Firebase App Check initialized with fallback debug provider');
      } catch (fallbackError) {
        _logger
            .e('All App Check initialization attempts failed: $fallbackError');
      }
    }
  }

  /// Force a token refresh
  ///
  /// This is useful when authentication operations are failing with
  /// App Check related errors
  static Future<String?> _refreshToken() async {
    try {
      // Clear any cached tokens first
      try {
        // This is an undocumented but useful workaround to force a completely fresh token
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);
        await Future.delayed(const Duration(milliseconds: 300));
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      } catch (e) {
        _logger.d('Token auto-refresh toggle failed, continuing: $e');
      }

      // Now request a new token
      final result = await FirebaseAppCheck.instance.getToken(true);
      _logger.d('App Check token refreshed successfully');
      return result;
    } catch (e) {
      _logger.w('Error refreshing App Check token: $e');

      // Attempt to re-activate App Check if we're getting attestation failures
      if (e.toString().contains('attestation failed') ||
          e.toString().contains('Too many attempts')) {
        _logger.d(
            'Attempting to re-initialize App Check due to attestation failure');

        try {
          // Try to re-initialize with debug provider temporarily
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
            appleProvider: AppleProvider.debug,
          );
          final debugToken = await FirebaseAppCheck.instance.getToken();
          _logger.i('Successfully recovered using debug provider');
          return debugToken;
        } catch (reInitError) {
          _logger.e('App Check re-initialization failed: $reInitError');
        }
      }

      return null;
    }
  }

  /// Setup a periodic timer to refresh the token before it expires
  static void _setupPeriodicTokenRefresh() {
    // Cancel any existing timer first
    _tokenRefreshTimer?.cancel();

    // Create a new periodic timer that fires every 45 minutes
    // (tokens expire at 60 minutes, so refresh 15 minutes earlier)
    _tokenRefreshTimer = Timer.periodic(
      Duration(minutes: _tokenRefreshInterval),
      (_) => _refreshToken(),
    );

    _logger.d('App Check token refresh timer started');
  }

  /// Get a fresh App Check token
  ///
  /// Returns null if token retrieval fails
  static Future<String?> getToken() async {
    try {
      final result = await FirebaseAppCheck.instance.getToken();
      return result;
    } catch (e) {
      _logger.w('Error getting App Check token: $e');
      return null;
    }
  }

  /// Force token refresh when needed
  ///
  /// This can be called when token errors are detected in Firebase operations
  static Future<String?> forceTokenRefresh() async {
    return await _refreshToken();
  }

  /// Check if a Firebase error is related to App Check and handle it
  ///
  /// Returns true if the error was handled, false otherwise
  static Future<bool> handleAppCheckError(dynamic error) async {
    final errorString = error.toString().toLowerCase();

    // Check if this is an App Check related error
    if (errorString.contains('app check') ||
        errorString.contains('attestation') ||
        errorString.contains('recaptcha token') ||
        errorString.contains('too many attempts')) {
      _logger.w('Detected App Check error, attempting recovery: $error');

      // Try to refresh the token
      final newToken = await forceTokenRefresh();

      // Return true if we successfully got a new token
      return newToken != null;
    }

    return false;
  }

  /// Clean up resources
  static void dispose() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    _logger.d('App Check service disposed');
  }
}
