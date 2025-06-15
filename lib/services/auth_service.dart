import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/user_agreement.dart';
import 'package:ovarian_cyst_support_app/widgets/app_toast.dart' as toast;
import 'package:ovarian_cyst_support_app/services/app_check_service.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, disabled }

class AuthService with ChangeNotifier {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final _storage = const FlutterSecureStorage();
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  final _logger = Logger();

  // Expose the current user
  User? get currentUser => _user;

  // Storage keys for credentials
  static const String _emailKey = 'auth_email';
  static const String _passwordKey = 'auth_password';

  // Constructor that handles Firebase errors
  AuthService()
    : _auth = _tryGetFirebaseAuth(),
      _firestore = _tryGetFirestore() {
    // If Firebase services are not available, mark as disabled
    if (_auth == null || _firestore == null) {
      _status = AuthStatus.disabled;
      _errorMessage = "Firebase services are not available";
      _logger.e("Firebase services initialization failed");
      notifyListeners();
      return;
    }

    if (kIsWeb) {
      // Configure persistence for web using Settings
      // At this point we know _firestore is not null due to earlier check
      _firestore.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      _logger.i('Persistence settings configured for web');
    }

    // Initialize normally - App Check is now handled by the AppCheckService
    _init();
  }

  // Try to get Firebase Auth safely
  static FirebaseAuth? _tryGetFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      return null;
    }
  }

  // Try to get Firestore safely
  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _user != null && _status == AuthStatus.authenticated;

  // Initialize auth state changes
  void _init() {
    _auth?.authStateChanges().listen((User? user) {
      _user = user;

      if (user == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.authenticated;
      }

      notifyListeners();
    });
  }

  // Register a new user with email and password
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to refresh App Check token before registration
      try {
        // Reset any previous backoff in AppCheckService to give this attempt best chance
        await AppCheckService.resetBackoff();
        final token = await AppCheckService.forceTokenRefresh();
        if (token != null) {
          _logger.i("Successfully refreshed App Check token for registration");
        } else {
          _logger.w(
            "App Check token refresh returned null, continuing with registration attempt",
          );
        }
      } catch (e) {
        _logger.w("Failed to refresh App Check token: $e");
        // Continue with registration attempt
      }

      int retryCount = 0;
      const maxRetries = 2;

      while (retryCount <= maxRetries) {
        try {
          // Create user account
          final UserCredential result = await _auth!
              .createUserWithEmailAndPassword(email: email, password: password);
          _user = result.user;

          // Send email verification
          await _user?.sendEmailVerification();

          // Create user profile in Firestore
          if (_user != null && _firestore != null) {
            final user = _user!; // Create a local non-nullable variable
            await _firestore.collection('users').doc(user.uid).set({
              'name': name,
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            });

            // Store user agreement
            await _firestore.collection('user_agreements').doc(user.uid).set({
              'agreedToTerms': true,
              'agreedToPrivacyPolicy': true,
              'timestamp': FieldValue.serverTimestamp(),
            });

            // Save credentials for auto-login after verification
            await _storage.write(key: _emailKey, value: email);
            await _storage.write(key: _passwordKey, value: password);

            // Show success notification using AppToast if context is still valid
            if (context.mounted) {
              toast.AppToast.showSuccess(
                context,
                'Registration successful! Please check your email to verify your account.',
              );
            }
          }

          // Successful registration, reset AppCheck backoff mechanism
          await AppCheckService.resetBackoff();

          _isLoading = false;
          notifyListeners();
          return _user;
        } on FirebaseAuthException catch (e) {
          // First check if this is an App Check issue that can be directly handled
          final handled = await AppCheckService.handleAppCheckError(e);

          if (handled) {
            // App Check issue was handled, retry after a short delay
            // to allow the new token to propagate
            _logger.i("App Check issue was handled, retrying shortly");
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }

          if (retryCount < maxRetries &&
              (e.code == 'too-many-requests' ||
                  e.message?.contains('App attestation failed') == true ||
                  e.message?.contains('reCAPTCHA token') == true ||
                  e.message?.contains('Firebase: Error') == true)) {
            // Add exponential backoff delay before retrying
            retryCount++;

            // Use exponential backoff with jitter to avoid thundering herd
            final baseSeconds = math.pow(2, retryCount).toInt();
            final jitter = math.Random().nextInt(1000);
            final backoffMs = (baseSeconds * 1000) + jitter;

            _logger.w(
              "Registration attempt failed, retrying in ${backoffMs / 1000} seconds ($retryCount/$maxRetries): ${e.message}",
            );

            await Future.delayed(Duration(milliseconds: backoffMs));
          } else {
            // We've reached max retries or it's a non-retriable error
            _isLoading = false;
            _errorMessage = _getReadableErrorMessage(e);
            notifyListeners();

            // Show error notification if context is still valid
            if (context.mounted) {
              toast.AppToast.showError(
                context,
                _errorMessage ?? 'Registration failed. Please try again.',
              );
            }
            return null;
          }
        } catch (e) {
          // Handle non-Firebase exceptions
          _isLoading = false;
          _errorMessage = e.toString();
          notifyListeners();

          if (context.mounted) {
            toast.AppToast.showError(
              context,
              'Registration failed: ${e.toString()}',
            );
          }
          return null;
        }
      }

      // If we reach here, all retries failed
      _isLoading = false;
      _errorMessage =
          'Registration failed after multiple attempts. Please try again later.';
      notifyListeners();

      if (context.mounted) {
        toast.AppToast.showError(context, _errorMessage!);
      }
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();

      if (context.mounted) {
        toast.AppToast.showError(
          context,
          'Registration failed: ${e.toString()}',
        );
      }
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      // Try to get a fresh App Check token before authentication
      try {
        await AppCheckService.resetBackoff();
        final token = await AppCheckService.forceTokenRefresh();
        if (token != null) {
          _logger.i("Successfully refreshed App Check token");
        }
      } catch (appCheckError) {
        _logger.w("Failed to refresh App Check token: $appCheckError");
      }

      final UserCredential userCredential = await _auth!
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null && _firestore != null) {
        try {
          // Get the user document
          DocumentSnapshot docSnapshot =
              await _firestore
                  .collection('users')
                  .doc(userCredential.user!.uid)
                  .get();

          // Create or update user data
          // User is guaranteed to be non-null here as we already checked it above,
          // but we create a local variable to satisfy the null safety checker
          final user = userCredential.user!;
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'name': user.displayName ?? 'User',
            'lastLogin': FieldValue.serverTimestamp(),
            if (!docSnapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Reset App Check backoff on successful login
          await AppCheckService.resetBackoff();
          return userCredential.user;
        } catch (e) {
          _logger.e('Error updating user data: $e');
          // Continue with login even if updating user data fails
          return userCredential.user;
        }
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // First check if this is an App Check issue
      final handled = await AppCheckService.handleAppCheckError(e);
      if (handled) {
        // Retry the sign in after App Check is handled
        return signInWithEmailAndPassword(email, password);
      }
      _handleAuthError(e);
      return null;
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _auth!.signOut();
    } catch (e) {
      _setError('Error signing out: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      rethrow;
    } catch (e) {
      _setError('Error sending password reset email: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();

      // Delete user data from Firestore first
      if (_user != null) {
        await _firestore!.collection('users').doc(_user!.uid).delete();

        // Delete user authentication
        await _user!.delete();

        // Update status since user is now deleted
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else {
        throw Exception('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      // Handle authentication-specific exceptions
      _setError(e.message ?? 'Failed to delete account');
      rethrow;
    } catch (e) {
      // Handle general exceptions
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    _setLoading(true);
    _clearError();

    try {
      if (_user == null || _firestore == null) {
        _logger.w('User or Firestore is null');
        return null;
      }

      // Create a local variable to handle the null safety properly
      final user = _user!;
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (!docSnapshot.exists) {
        _logger.w('User document does not exist');
        return null;
      }

      final data = docSnapshot.data();
      if (data == null) {
        _logger.w('Document data is null');
        return null;
      }

      return data;
    } catch (e) {
      _logger.e('Error getting user data: $e');
      _setError('Error retrieving user data: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile in Firebase Auth and Firestore
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (_user == null) {
        _setError('No authenticated user found');
        return;
      }

      // Update Firebase Auth profile if needed
      if (displayName != null || photoURL != null) {
        await _user!.updateDisplayName(displayName);
        await _user!.updatePhotoURL(photoURL);
      }

      // Update additional data in Firestore if provided
      if (additionalData != null && additionalData.isNotEmpty) {
        await _firestore!.collection('users').doc(_user!.uid).update({
          ...additionalData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _setError('Error updating profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Persist login credentials securely
  Future<void> persistLoginCredentials(String email, String password) async {
    try {
      await _storage.write(key: _emailKey, value: email);
      await _storage.write(key: _passwordKey, value: password);
      _logger.i('Credentials saved successfully');
    } catch (e) {
      _logger.e('Error saving credentials: $e');
    }
  }

  // Clear persisted credentials
  Future<void> clearPersistedCredentials() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
      _logger.i('Credentials cleared successfully');
    } catch (e) {
      _logger.e('Error clearing credentials: $e');
    }
  }

  // Check if credentials are saved
  Future<bool> hasPersistedCredentials() async {
    try {
      final email = await _storage.read(key: _emailKey);
      return email != null;
    } catch (e) {
      _logger.e('Error checking credentials: $e');
      return false;
    }
  }

  // Get saved credentials
  Future<Map<String, String?>> getPersistedCredentials() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      return {'email': email, 'password': password};
    } catch (e) {
      _logger.e('Error retrieving credentials: $e');
      return {};
    }
  }

  // Store user agreement status
  Future<void> storeUserAgreement(
    String userId,
    bool hasAcceptedTerms,
    bool hasAcceptedPrivacy,
  ) async {
    try {
      final userAgreement = UserAgreement(
        userId: userId,
        hasAcceptedTerms: hasAcceptedTerms,
        hasAcceptedPrivacy: hasAcceptedPrivacy,
        acceptedAt: DateTime.now(),
      );

      await _firestore!
          .collection('user_agreements')
          .doc(userId)
          .set(userAgreement.toMap());
    } catch (e) {
      _logger.e('Error storing user agreement: $e');
      throw Exception('Failed to store user agreement');
    }
  }

  // Get user agreement status
  Future<UserAgreement?> getUserAgreement(String userId) async {
    try {
      final doc =
          await _firestore!.collection('user_agreements').doc(userId).get();
      if (doc.exists) {
        return UserAgreement.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user agreement: $e');
      return null;
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification(BuildContext context) async {
    try {
      if (!context.mounted) return false;

      if (_auth == null) {
        _logger.w('Auth instance is null');
        return false;
      }

      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        if (context.mounted) {
          toast.AppToast.showSuccess(
            context,
            'Email verified successfully! You can now access all features.',
          );
        }
        return true;
      } else if (user != null) {
        if (context.mounted) {
          toast.AppToast.showSuccess(
            context,
            'Please verify your email to access all features.',
          );
        }
        return false;
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        toast.AppToast.showError(
          context,
          'Failed to check email verification status.',
        );
      }
      return false;
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail(BuildContext context) async {
    try {
      await _auth!.currentUser?.sendEmailVerification();
      if (context.mounted) {
        toast.AppToast.showSuccess(
          context,
          'Verification email sent! Please check your inbox.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        toast.AppToast.showError(
          context,
          'Failed to send verification email. Please try again later.',
        );
      }
    }
  }

  // Handle Firebase Auth errors
  void _handleAuthError(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'weak-password':
        message = 'The password provided is too weak.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed.';
        break;
      case 'too-many-requests':
        message =
            'Too many login attempts. Please try again later or reset your password.';
        break;
      case 'network-request-failed':
        message =
            'Network connection error. Please check your internet connection.';
        break;
      default:
        // Handle App Check and reCAPTCHA specific errors
        if (e.message?.contains('App attestation failed') == true) {
          message = 'Security verification failed. Please try again later.';
          _logger.e("App attestation failed: ${e.message}");
        } else if (e.message?.contains('reCAPTCHA token') == true) {
          message =
              'Security verification failed. Please restart the app and try again.';
          _logger.e("reCAPTCHA token error: ${e.message}");
        } else {
          message = 'Authentication error: ${e.message}';
          _logger.e("Auth error: ${e.code} - ${e.message}");
        }
    }

    _setError(message);
  }

  // Set error state
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error state
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  // Convert error to readable message
  String _getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user has been disabled. Please contact support.';
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'too-many-requests':
          return 'Too many login attempts. Please wait a few minutes before trying again.';
        case 'network-request-failed':
          return 'Network connection error. Please check your internet connection.';
        default:
          // Handle App Check specific errors
          final String errorMsg = error.message ?? '';
          if (errorMsg.contains('App attestation failed')) {
            _logger.e('App attestation error: ${error.message}');
            return 'Security verification failed. This is often temporary - please try again after a minute.';
          } else if (errorMsg.contains('Too many attempts')) {
            _logger.e('Too many attempts error: ${error.message}');
            return 'Too many security verification attempts. Please wait a few minutes before trying again.';
          } else if (errorMsg.contains('reCAPTCHA token')) {
            _logger.e('reCAPTCHA token error: ${error.message}');
            return 'Security verification failed. Please restart the app and try again.';
          } else if (errorMsg.contains('Firebase: Error')) {
            _logger.e('Generic Firebase error: ${error.message}');
            return 'Authentication service temporarily unavailable. Please try again shortly.';
          } else {
            return 'Authentication error. Please try again.';
          }
      }
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}
