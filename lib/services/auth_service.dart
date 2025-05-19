import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, disabled }

class AuthService with ChangeNotifier {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  final _logger = Logger();

  // Constructor that handles Firebase errors
  AuthService()
      : _auth = _tryGetFirebaseAuth(),
        _firestore = _tryGetFirestore() {
    // If Firebase services are not available, mark as disabled
    if (_auth == null || _firestore == null) {
      _status = AuthStatus.disabled;
      _errorMessage = "Firebase services are not available";
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
      Logger().e('Error initializing FirebaseAuth: $e');
      return null;
    }
  }

  // Try to get Firestore safely
  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      Logger().e('Error initializing Firestore: $e');
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
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      // Create the user with Firebase Auth
      final UserCredential userCredential = await _auth!
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!.uid, {
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
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
        // Update last login timestamp
        await _firestore!
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'lastLogin': FieldValue.serverTimestamp()});
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

  // Create user document in Firestore
  Future<void> _createUserDocument(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _firestore!.collection('users').doc(uid).set(data);
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
}
