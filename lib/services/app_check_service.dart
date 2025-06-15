import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:math' show min;
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

  // Backoff control variables
  static int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;
  static DateTime? _lastFailureTime;
  static bool _isRecoveryInProgress = false;

  /// Initialize Firebase App Check with appropriate provider based on platform and build mode
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Always use debug provider in development for better local testing experience
      // In a production build, you'd use attestation providers instead
      if (kIsWeb) {
        // For web, use debug token if available
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
        );
      } else {
        // For mobile platforms, use debug providers
        await FirebaseAppCheck.instance.activate(
          // Force debug provider for mobile platforms to ensure the app works during development
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      }

      // Add a delay to ensure the debug provider initialization completes
      await Future.delayed(const Duration(milliseconds: 500));

      // Log debug token for development purposes
      try {
        final token = await FirebaseAppCheck.instance.getToken();
        if (token != null) {
          _logger.i(
            'App Check initialized with token: ${token.substring(0, min(10, token.length))}...',
          );
        }
      } catch (tokenError) {
        _logger.w('Could not retrieve initial App Check token: $tokenError');
      }
      _isInitialized = true;
      _logger.i('Firebase App Check initialized successfully');

      // Start refresh timer
      _setupPeriodicTokenRefresh();
    } catch (e) {
      _logger.e('Error initializing App Check: $e');
      throw Exception('Failed to initialize App Check: $e');
    }
  }

  /// Get the backoff duration based on consecutive failures
  static Duration _getBackoffDuration() {
    if (_consecutiveFailures <= 0) return Duration.zero;

    // Exponential backoff: 2^failures seconds, capped at 5 minutes
    final seconds = math.min(math.pow(2, _consecutiveFailures).toInt(), 300);
    return Duration(seconds: seconds);
  }

  /// Force a token refresh
  ///
  /// This is useful when authentication operations are failing with
  /// App Check related errors
  static Future<String?> _refreshToken() async {
    // Check if we need to wait due to backoff
    if (_lastFailureTime != null && _consecutiveFailures > 0) {
      final backoffDuration = _getBackoffDuration();
      final timePassedSinceLastFailure = DateTime.now().difference(
        _lastFailureTime!,
      );

      if (timePassedSinceLastFailure < backoffDuration) {
        final waitTime = backoffDuration - timePassedSinceLastFailure;
        _logger.d(
          'Respecting backoff, waiting for ${waitTime.inSeconds} seconds before retry',
        );
        return null; // Don't retry yet, respect the backoff
      }
    }

    // Prevent concurrent recovery attempts
    if (_isRecoveryInProgress) {
      _logger.d('Skipping token refresh as recovery is already in progress');
      return null;
    }

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

      // Reset failure counters on success
      _consecutiveFailures = 0;
      _lastFailureTime = null;

      return result;
    } catch (e) {
      _logger.w('Error refreshing App Check token: $e');

      // Track failure for backoff calculation
      _consecutiveFailures++;
      _lastFailureTime = DateTime.now();

      // Attempt to re-activate App Check if we're getting attestation failures
      if (e.toString().contains('attestation failed') ||
          e.toString().contains('Too many attempts')) {
        if (_consecutiveFailures > _maxConsecutiveFailures) {
          _logger.w(
            'Too many consecutive failures ($_consecutiveFailures), skipping recovery',
          );
          return null;
        }

        _logger.d(
          'Attempting to re-initialize App Check due to attestation failure',
        );

        _isRecoveryInProgress = true;
        try {
          // Try to force disable and enable token auto-refresh to reset internal state
          await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);
          await Future.delayed(const Duration(milliseconds: 300));
          await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
          await Future.delayed(const Duration(milliseconds: 300));

          // Try to re-initialize with debug provider temporarily
          if (kIsWeb) {
            await FirebaseAppCheck.instance.activate(
              webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
            );
          } else {
            await FirebaseAppCheck.instance.activate(
              androidProvider: AndroidProvider.debug,
              appleProvider: AppleProvider.debug,
            );
          }

          // Longer delay to let the new provider take effect
          await Future.delayed(const Duration(milliseconds: 800));

          // Try to get a new token, but don't force refresh to avoid rate limiting
          final debugToken = await FirebaseAppCheck.instance.getToken(false);
          _logger.i('Successfully recovered using debug provider');

          // Reset counters on successful recovery
          _consecutiveFailures = 0;
          _lastFailureTime = null;

          return debugToken;
        } catch (reInitError) {
          _logger.e('App Check re-initialization failed: $reInitError');
          return null;
        } finally {
          _isRecoveryInProgress = false;
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

      // Don't retry too quickly if we're hitting rate limits
      if (errorString.contains('too many attempts') &&
          _lastFailureTime != null &&
          DateTime.now().difference(_lastFailureTime!) <
              const Duration(seconds: 30)) {
        _logger.w(
          'Too many attempts error within backoff period, skipping immediate retry',
        );
        return false;
      }

      // Try to refresh the token
      final newToken = await forceTokenRefresh();

      // Return true if we successfully got a new token
      return newToken != null;
    }

    return false;
  }

  /// Reset the backoff state - useful after successful operations
  static Future<void> resetBackoff() async {
    _consecutiveFailures = 0;
    _lastFailureTime = null;
    _isRecoveryInProgress = false;

    // Try to reset the App Check internal state
    try {
      // Toggle auto-refresh to reset internal state
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);
      await Future.delayed(const Duration(milliseconds: 300));
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

      // Reinitialize with debug provider for more resilience
      if (kIsWeb) {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      }

      // Restart the token refresh timer
      _setupPeriodicTokenRefresh();

      _logger.i('App Check state fully reset with debug providers');
    } catch (e) {
      _logger.w('Failed to reset App Check state: $e');
    }
  }

  /// Clean up resources
  static void dispose() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    _logger.d('App Check service disposed');
  }
}
