import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ovarian_cyst_support_app/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

enum PaymentStatus { pending, processing, completed, failed, cancelled }

class PaymentService {
  // Base URL for API (Express.js backend)
  static const String baseUrl = 'https://ovacare-backend.example.com/api';

  // Singleton instance
  static final PaymentService _instance = PaymentService._internal();

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal();

  // Database service for offline handling
  final DatabaseService _databaseService = DatabaseService();

  // Initialize payment service
  static Future<void> initialize() async {
    debugPrint('Payment service initialized');
  }

  // Process payment (stub implementation, since M-Pesa plugin is unavailable)
  Future<Map<String, dynamic>> processPayment({
    required String phoneNumber,
    required double amount,
    required String appointmentId,
    required String description,
  }) async {
    try {
      // Check connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        debugPrint('No internet connection, cannot process payment now.');
        return {
          'success': false,
          'message':
              'No internet connection. Please try again when you are online.',
          'status': PaymentStatus.failed.toString(),
        };
      }

      // Simulate payment processing (since M-Pesa plugin is missing)
      final fakeTransactionId =
          'FAKE_${appointmentId}_${DateTime.now().millisecondsSinceEpoch}';

      // Store payment attempt in local DB for tracking
      await _storePaymentAttempt({
        'id': '${appointmentId}_${DateTime.now().millisecondsSinceEpoch}',
        'appointmentId': appointmentId,
        'phoneNumber': phoneNumber,
        'amount': amount,
        'description': description,
        'status': PaymentStatus.processing.toString(),
        'transactionId': fakeTransactionId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Return initial response
      return {
        'success': true,
        'message':
            'Payment request simulated. (M-Pesa plugin not available in this build.)',
        'status': PaymentStatus.processing.toString(),
        'transactionId': fakeTransactionId,
      };
    } catch (e) {
      debugPrint('Error processing payment: $e');

      // Store failed payment attempt
      await _storePaymentAttempt({
        'id': '${appointmentId}_${DateTime.now().millisecondsSinceEpoch}',
        'appointmentId': appointmentId,
        'phoneNumber': phoneNumber,
        'amount': amount,
        'description': description,
        'status': PaymentStatus.failed.toString(),
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      return {
        'success': false,
        'message': 'Payment failed: ${e.toString()}',
        'status': PaymentStatus.failed.toString(),
      };
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      // Check connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        debugPrint('No internet connection, cannot check payment status now.');

        // Return local status if available
        final localStatus = await _getLocalPaymentStatus(transactionId);
        if (localStatus != null) {
          return {
            'success': true,
            'status': localStatus,
            'message':
                'Using locally cached payment status due to offline mode.',
            'offline': true,
          };
        }

        return {
          'success': false,
          'message': 'Cannot check payment status while offline.',
          'status': PaymentStatus.pending.toString(),
          'offline': true,
        };
      }

      // Call backend to check status
      final response = await http.get(
        Uri.parse('$baseUrl/payments/status/$transactionId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Update local payment status
        await _updateLocalPaymentStatus(transactionId, data['status']);

        return {
          'success': true,
          'status': data['status'],
          'message': data['message'],
          'details': data['details'],
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to check payment status. Server returned ${response.statusCode}',
          'status': PaymentStatus.pending.toString(),
        };
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return {
        'success': false,
        'message': 'Error checking payment status: ${e.toString()}',
        'status': PaymentStatus.pending.toString(),
      };
    }
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final db = await _databaseService.database;

    final List<Map<String, dynamic>> results = await db.query(
      'payment_attempts',
      orderBy: 'timestamp DESC',
    );

    return results;
  }

  // Store payment attempt
  Future<void> _storePaymentAttempt(Map<String, dynamic> payment) async {
    final db = await _databaseService.database;

    // Check if payment_attempts table exists, create if not
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='payment_attempts'",
    );
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE payment_attempts(
          id TEXT PRIMARY KEY,
          appointmentId TEXT,
          phoneNumber TEXT,
          amount REAL,
          description TEXT,
          status TEXT,
          transactionId TEXT,
          error TEXT,
          timestamp TEXT,
          isUploaded INTEGER DEFAULT 0
        )
      ''');
    }

    await db.insert(
      'payment_attempts',
      payment,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get local payment status
  Future<String?> _getLocalPaymentStatus(String transactionId) async {
    final db = await _databaseService.database;

    final List<Map<String, dynamic>> results = await db.query(
      'payment_attempts',
      columns: ['status'],
      where: 'transactionId = ?',
      whereArgs: [transactionId],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['status'] as String;
    }

    return null;
  }

  // Update local payment status
  Future<void> _updateLocalPaymentStatus(
    String transactionId,
    String status,
  ) async {
    final db = await _databaseService.database;

    await db.update(
      'payment_attempts',
      {'status': status},
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
  }

  // Generate receipt
  Future<String> generateReceipt(String transactionId) async {
    try {
      // Check connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return 'Cannot generate receipt while offline.';
      }

      // Call backend to generate receipt
      final response = await http.get(
        Uri.parse('$baseUrl/payments/receipt/$transactionId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['receiptUrl'];
      } else {
        return 'Failed to generate receipt.';
      }
    } catch (e) {
      debugPrint('Error generating receipt: $e');
      return 'Error generating receipt: ${e.toString()}';
    }
  }

  // Format currency
  static String formatCurrency(double amount) {
    // Assuming Kenyan Shillings (KES)
    return 'KES ${amount.toStringAsFixed(2)}';
  }
}
