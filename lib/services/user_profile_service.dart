import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ovarian_cyst_support_app/models/user_profile.dart';

class UserProfileService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor that listens to auth changes
  UserProfileService() {
    // Listen for authentication state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchUserProfile(user.uid);
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  // Fetch user profile from Firestore
  Future<void> _fetchUserProfile(String uid) async {
    _setLoading(true);

    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        _userProfile = UserProfile.fromMap(data, uid);
      } else {
        // Create a basic profile if it doesn't exist
        final user = _auth.currentUser;
        if (user != null) {
          final newProfile = UserProfile(
            uid: uid,
            email: user.email,
            name: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            phoneNumber: user.phoneNumber,
          );

          await _firestore.collection('users').doc(uid).set(newProfile.toMap());
          _userProfile = newProfile;
        }
      }
    } catch (e) {
      _setError('Error fetching user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_auth.currentUser == null) return false;

    _setLoading(true);

    try {
      final uid = _auth.currentUser!.uid;
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (additionalData != null) updateData.addAll(additionalData);

      await _firestore.collection('users').doc(uid).update(updateData);

      // Update Firebase Auth profile if needed
      if (name != null) {
        await _auth.currentUser!.updateDisplayName(name);
      }

      if (photoUrl != null) {
        await _auth.currentUser!.updatePhotoURL(photoUrl);
      }

      // Refresh profile
      await _fetchUserProfile(uid);
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add health information to user profile
  Future<bool> updateHealthInfo({
    required String diagnosisDate,
    String? doctorName,
    String? hospitalName,
    String? cystType,
    String? cystSize,
    List<String>? medications,
    List<String>? allergies,
  }) async {
    if (_auth.currentUser == null) return false;

    _setLoading(true);

    try {
      final uid = _auth.currentUser!.uid;
      final healthData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'healthInfo': {'diagnosisDate': diagnosisDate},
      };

      if (doctorName != null) {
        healthData['healthInfo']['doctorName'] = doctorName;
      }
      if (hospitalName != null) {
        healthData['healthInfo']['hospitalName'] = hospitalName;
      }
      if (cystType != null) healthData['healthInfo']['cystType'] = cystType;
      if (cystSize != null) healthData['healthInfo']['cystSize'] = cystSize;
      if (medications != null) {
        healthData['healthInfo']['medications'] = medications;
      }
      if (allergies != null) healthData['healthInfo']['allergies'] = allergies;

      await _firestore.collection('users').doc(uid).update(healthData);

      // Refresh profile
      await _fetchUserProfile(uid);
      return true;
    } catch (e) {
      _setError('Failed to update health info: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    if (_auth.currentUser == null) return false;

    _setLoading(true);

    try {
      final uid = _auth.currentUser!.uid;

      // Delete user data from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete user from Firebase Auth
      await _auth.currentUser!.delete();

      _userProfile = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete account: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
