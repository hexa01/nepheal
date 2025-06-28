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

  // Enhanced Doctors API with filtering support
  static Future<Map<String, dynamic>> getDoctors({
    int? specializationId,
    String? search,
  }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};

      if (specializationId != null) {
        queryParams['specialization_id'] = specializationId.toString();
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Build URI with query parameters
      Uri uri = Uri.parse(ApiConstants.doctors);
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch doctors: $e');
    }
  }

  // Get single doctor details
  static Future<Map<String, dynamic>> getDoctorById(int doctorId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.doctors}/$doctorId'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch doctor details: $e');
    }
  }

  // Review API Methods

  // Get reviews for a specific doctor
  static Future<Map<String, dynamic>> getDoctorReviews({
    required int doctorId,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/reviews?doctor_id=$doctorId&page=$page&per_page=$perPage'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch doctor reviews: $e');
    }
  }

  // Get doctor rating statistics
  static Future<Map<String, dynamic>> getDoctorRatingStats(int doctorId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/reviews/doctor/$doctorId/stats'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch doctor rating stats: $e');
    }
  }

  // Create a new review
  static Future<Map<String, dynamic>> createReview({
    required int appointmentId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/reviews'),
        headers: _getHeaders(),
        body: jsonEncode({
          'appointment_id': appointmentId,
          'rating': rating,
          'comment': comment,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // Get patient's reviews
  static Future<Map<String, dynamic>> getPatientReviews() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/reviews/my-reviews'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch patient reviews: $e');
    }
  }

  // Get appointments that can be reviewed
  static Future<Map<String, dynamic>> getReviewableAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/reviews/reviewable-appointments'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch reviewable appointments: $e');
    }
  }

  // Update a review
  static Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/reviews/$reviewId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review
  static Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/reviews/$reviewId'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Profile Photo Methods
  
  // Upload profile photo
  static Future<Map<String, dynamic>> uploadProfilePhoto(String imagePath) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/profile-photo/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Add authorization header
      final token = StorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      
      // Add image file
      request.files.add(await http.MultipartFile.fromPath('profile_photo', imagePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  // Delete profile photo
  static Future<Map<String, dynamic>> deleteProfilePhoto() async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/profile-photo/delete'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete profile photo: $e');
    }
  }

  // Get profile photo
  static Future<Map<String, dynamic>> getProfilePhoto({int? userId}) async {
    try {
      final url = userId != null 
          ? '${ApiConstants.baseUrl}/profile-photo/show/$userId'
          : '${ApiConstants.baseUrl}/profile-photo/show';
          
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get profile photo: $e');
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