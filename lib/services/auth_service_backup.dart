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
      : _auth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance {
    // Set up auth state listener
    _auth?.authStateChanges().listen(_onAuthStateChanged);
  }
