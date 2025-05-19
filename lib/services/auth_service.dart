import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/user_agreement.dart';
import 'package:ovarian_cyst_support_app/widgets/app_toast.dart' as toast;

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

    // Otherwise initialize normally
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

      // Create user account
      final UserCredential result = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;

      // Send email verification
      await _user?.sendEmailVerification();

      // Create user profile in Firestore
      if (_user != null) {
        await _firestore!.collection('users').doc(_user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Store user agreement
        await _firestore!.collection('user_agreements').doc(_user!.uid).set({
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

      _isLoading = false;
      notifyListeners();
      return _user;
    } catch (e) {
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
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final UserCredential userCredential = await _auth!
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Check if the user document exists
        DocumentSnapshot docSnapshot = await _firestore!
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
            
        if (docSnapshot.exists) {
          // Update last login timestamp
          await _firestore!
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({'lastLogin': FieldValue.serverTimestamp()});
        } else {
          // Create a new user document if it doesn't exist
          await _firestore!
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'email': userCredential.user!.email,
                'name': userCredential.user!.displayName ?? 'User',
                'createdAt': FieldValue.serverTimestamp(),
                'lastLogin': FieldValue.serverTimestamp(),
              });
        }
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
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
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _setError('Error resetting password: ${e.toString()}');
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

  // Get user document from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (_user == null) return null;

    try {
      DocumentSnapshot doc =
          await _firestore!.collection('users').doc(_user!.uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      _setError('Error getting user data: ${e.toString()}');
      return null;
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
      return {
        'email': email,
        'password': password,
      };
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

      await _auth!.currentUser?.reload();
      final user = _auth!.currentUser;

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
        message = 'Too many requests. Try again later.';
        break;
      default:
        message = 'Authentication error: ${e.message}';
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
        default:
          return 'An unknown error occurred. Please try again.';
      }
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}
