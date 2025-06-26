import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/storage/storage_service.dart';

class ApiService {
  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Auth Methods
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    required String gender,
    String? phone,
    String? address,
    DateTime? dob,
  }) async {
    try {
      Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
        'gender': gender,
      };

      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;
      if (dob != null) body['dob'] = dob.toIso8601String().split('T')[0];

      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.logout),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Doctors
  static Future<Map<String, dynamic>> getDoctors() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.doctors),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch doctors: $e');
    }
  }

  // Specializations
  static Future<Map<String, dynamic>> getSpecializations() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.specializations),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch specializations: $e');
    }
  }

  // Get available slots for booking
  static Future<Map<String, dynamic>> getAvailableSlots({
    required int doctorId,
    required String appointmentDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/slots?doctor_id=$doctorId&appointment_date=$appointmentDate'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch available slots: $e');
    }
  }

  // Appointments
  static Future<Map<String, dynamic>> getAppointments() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.appointments),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch appointments: $e');
    }
  }

  static Future<Map<String, dynamic>> createAppointment({
    required int doctorId,
    required DateTime appointmentDate,
    required String slot,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.appointments),
        headers: _getHeaders(),
        body: jsonEncode({
          'doctor_id': doctorId,
          'appointment_date': appointmentDate.toIso8601String().split('T')[0],
          'slot': slot,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required int appointmentId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/appointment/status/$appointmentId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'status': status,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Cancel appointment
  static Future<Map<String, dynamic>> cancelAppointment(
      int appointmentId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.appointments}/$appointmentId'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Helper method to handle responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'API Error: ${response.statusCode}');
    }
  }
}
