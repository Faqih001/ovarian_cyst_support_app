import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum PaymentStatus { pending, processing, completed, failed, cancelled }

class PaymentService {
  static const String baseUrl = 'https://api.ovarianapp.com/v1';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to get user's payments collection
  CollectionReference _getPaymentsCollection() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('No user logged in');
    }
    return _firestore.collection('users').doc(userId).collection('payments');
  }

  /// Save payment transaction
  Future<void> savePaymentTransaction(Map<String, dynamic> transaction) async {
    try {
      await _getPaymentsCollection().add({
        ...transaction,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving payment transaction: $e');
      rethrow;
    }
  }

  // Removed unused method: _checkConnectivity

  /// Process a new payment
  Future<Map<String, dynamic>> processPayment(
    double amount,
    String currency,
    String description,
  ) async {
    try {
      // Check connectivity
      final connectivityResults = await Connectivity().checkConnectivity();

      // Determine if there is an active connection
      final hasConnection = connectivityResults.isNotEmpty && 
          !connectivityResults.contains(ConnectivityResult.none);

      if (!hasConnection) {
        throw Exception('No internet connection');
      }

      // Create payment intent
      final response = await http.post(
        Uri.parse('$baseUrl/payments/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': currency,
          'description': description,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      // Save to Firestore
      final docRef = await _getPaymentsCollection().add({
        'amount': amount,
        'currency': currency,
        'description': description,
        'status': PaymentStatus.pending.toString(),
        'paymentIntentId': responseData['id'],
        'transactionId': responseData['id'], // Add consistent transaction ID
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'id': docRef.id,
        'clientSecret': responseData['clientSecret'],
        ...responseData,
      };
    } catch (e) {
      debugPrint('Error processing payment: $e');
      rethrow;
    }
  }

  /// Check payment status
  Future<PaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      // Check connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();

      // Determine if there is an active connection
      final hasConnection = connectivityResults.isNotEmpty && 
          !connectivityResults.contains(ConnectivityResult.none);

      if (!hasConnection) {
        debugPrint('No internet connection, cannot check payment status now.');

        // Return local status if available
        final localStatus = await _getLocalPaymentStatus(transactionId);
        if (localStatus != null) {
          return _parsePaymentStatus(localStatus);
        }

        return PaymentStatus.pending;
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

        return _parsePaymentStatus(data['status']);
      } else {
        throw Exception(
            'Failed to check payment status. Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      rethrow;
    }
  }

  /// Get payment receipt
  Future<String> getPaymentReceipt(String transactionId) async {
    try {
      // Check connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();

      // Determine if there is an active connection
      final hasConnection = connectivityResults.isNotEmpty && 
          !connectivityResults.contains(ConnectivityResult.none);

      if (!hasConnection) {
        return 'Cannot generate receipt while offline.';
      }

      // Call backend to generate receipt
      final response = await http.get(
        Uri.parse('$baseUrl/payments/receipt/$transactionId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to generate receipt.');
      }
    } catch (e) {
      debugPrint('Error generating receipt: $e');
      rethrow;
    }
  }

  /// Parse payment status from string
  PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.failed;
    }
  }

  // Get local payment status
  Future<String?> _getLocalPaymentStatus(String transactionId) async {
    try {
      final querySnapshot = await _getPaymentsCollection()
          .where('transactionId', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['status'] as String;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting local payment status: $e');
      return null;
    }
  }

  // Update local payment status
  Future<void> _updateLocalPaymentStatus(
    String transactionId,
    String status,
  ) async {
    try {
      // Find the document with the matching transactionId
      final querySnapshot = await _getPaymentsCollection()
          .where('transactionId', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _getPaymentsCollection().doc(docId).update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        debugPrint(
            'No payment document found with transactionId: $transactionId');
      }
    } catch (e) {
      debugPrint('Error updating local payment status: $e');
      rethrow;
    }
  }

  /// Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final querySnapshot = await _getPaymentsCollection()
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      debugPrint('Error getting payment history: $e');
      return [];
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus(
      String paymentId, PaymentStatus status) async {
    try {
      await _getPaymentsCollection().doc(paymentId).update({
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }

  // Format currency
  static String formatCurrency(double amount) {
    // Assuming Kenyan Shillings (KES)
    return 'KES ${amount.toStringAsFixed(2)}';
  }
}
