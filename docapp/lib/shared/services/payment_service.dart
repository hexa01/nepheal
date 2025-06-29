import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/storage_service.dart';

class PaymentService {
  static const String _baseUrl = ApiConstants.baseUrl;

  // Get authorization header with token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all payments for current user
  static Future<List<Payment>> getPayments() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.payments),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final List<dynamic> paymentsJson = data['data']['payments'];
        return paymentsJson.map((json) => Payment.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch payments');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  // Get payment details by ID
  static Future<Payment> getPaymentDetails(int paymentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.paymentDetails(paymentId)),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return Payment.fromJson(data['data']['payment']);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch payment details');
      }
    } catch (e) {
      throw Exception('Error fetching payment details: $e');
    }
  }

  // Initiate payment for an appointment
  static Future<Map<String, dynamic>> initiatePayment(int appointmentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.appointmentPaymentInitiate(appointmentId)),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'payment': Payment.fromJson(data['data']['payment']),
          'esewa_config': data['data']['esewa_config'],
        };
      } else {
        throw Exception(data['message'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      throw Exception('Error initiating payment: $e');
    }
  }

  // Verify payment after eSewa callback
  static Future<Payment> verifyPayment(Map<String, dynamic> paymentData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.paymentVerify),
        headers: headers,
        body: json.encode(paymentData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return Payment.fromJson(data['data']['payment']);
      } else {
        throw Exception(data['message'] ?? 'Payment verification failed');
      }
    } catch (e) {
      throw Exception('Error verifying payment: $e');
    }
  }

  // Retry failed payment
  static Future<Map<String, dynamic>> retryPayment(int paymentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.paymentRetry(paymentId)),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'payment': Payment.fromJson(data['data']['payment']),
          'esewa_config': data['data']['esewa_config'],
        };
      } else {
        throw Exception(data['message'] ?? 'Failed to retry payment');
      }
    } catch (e) {
      throw Exception('Error retrying payment: $e');
    }
  }

  // Handle payment failure
  static Future<void> handlePaymentFailure(String pid) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse(ApiConstants.paymentFailure),
        headers: headers,
        body: json.encode({'pid': pid}),
      );
      // We don't throw error here as failure handling is informational
    } catch (e) {
      // Log error but don't throw as it's not critical
      print('Error handling payment failure: $e');
    }
  }
}
