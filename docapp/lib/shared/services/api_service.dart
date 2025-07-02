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
  static Future<Map<String, dynamic>> uploadProfilePhoto(
      String imagePath) async {
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
      request.files
          .add(await http.MultipartFile.fromPath('profile_photo', imagePath));

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

// Update patient profile
  static Future<Map<String, dynamic>> updatePatientProfile({
    required int userId,
    required String name,
    required String email,
    String? phone,
    String? address,
    required String gender,
    bool emailChanged = false,
  }) async {
    try {
      // Only include email in the request if it has changed
      Map<String, dynamic> body = {
        'name': name,
        'phone': phone,
        'address': address,
        'gender': gender,
      };

      // Only add email if it has changed to avoid unique constraint issues
      if (emailChanged) {
        body['email'] = email;
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/patients/$userId'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update patient profile: $e');
    }
  }

// Update doctor profile
  static Future<Map<String, dynamic>> updateDoctorProfile({
    required int userId,
    required String name,
    required String email,
    String? phone,
    String? address,
    required String gender,
    String? bio,
    bool emailChanged = false,
  }) async {
    try {
      // Only include email in the request if it has changed
      Map<String, dynamic> body = {
        'name': name,
        'phone': phone,
        'address': address,
        'gender': gender,
        'bio': bio, // Include bio for doctors
      };

      // Only add email if it has changed to avoid unique constraint issues
      if (emailChanged) {
        body['email'] = email;
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/doctors/$userId'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update doctor profile: $e');
    }
  }

  // Get current doctor's profile
  static Future<Map<String, dynamic>> getDoctorProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.doctorView}'), // Use the doctor-view endpoint
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch doctor profile: $e');
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/change-password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Schedule Management Methods

  // Get doctor's weekly schedule
  static Future<Map<String, dynamic>> getDoctorSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/schedules'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch doctor schedule: $e');
    }
  }

  // Update schedule for a specific day
  static Future<Map<String, dynamic>> updateDoctorSchedule({
    required String dayName,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/schedules/${dayName.toLowerCase()}'),
        headers: _getHeaders(),
        body: jsonEncode({
          'start_time': startTime,
          'end_time': endTime,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  // Check if doctor has appointments on specific day
  static Future<Map<String, dynamic>> checkAppointmentsOnDay({
    required String dayName,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/schedules/check-appointments?day=${dayName.toLowerCase()}'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to check appointments: $e');
    }
  }

  // Get all days with appointments
  static Future<Map<String, dynamic>> getDaysWithAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/schedules/days-with-appointments'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get days with appointments: $e');
    }
  }

  // Toggle schedule status for a specific day
  static Future<Map<String, dynamic>> toggleScheduleStatus({
    required String dayName,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${ApiConstants.baseUrl}/schedules/${dayName.toLowerCase()}/toggle-status'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to toggle schedule status: $e');
    }
  }

  // Payment Methods

  /// Get all payments for current user
  static Future<Map<String, dynamic>> getPayments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/payments'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch payments: $e');
    }
  }

  /// Get specific payment details
  static Future<Map<String, dynamic>> getPayment(int paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/payments/$paymentId'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch payment details: $e');
    }
  }

  /// Initiate payment for an appointment
  static Future<Map<String, dynamic>> initiatePayment({
    required int appointmentId,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}/appointments/$appointmentId/payment/initiate'),
        headers: _getHeaders(),
        body: jsonEncode({
          'payment_method': paymentMethod,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to initiate payment: $e');
    }
  }

  /// Initiate eSewa payment and get HTML form
  static Future<String> initiateEsewaPayment({
    required int paymentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payments/esewa/initiate'),
        headers: _getHeaders(),
        body: jsonEncode({
          'payment_id': paymentId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body; // HTML content for WebView
      } else {
        final Map<String, dynamic> data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to initiate eSewa payment');
      }
    } catch (e) {
      throw Exception('Failed to initiate eSewa payment: $e');
    }
  }

  // Enhanced Appointment Methods

  /// Get appointments with categorization
  static Future<Map<String, dynamic>> getAppointmentsByStatus() async {
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

  /// Get appointment statistics
  static Future<Map<String, dynamic>> getAppointmentStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/appointments/stats'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch appointment statistics: $e');
    }
  }

  /// Reschedule appointment (reschedule)
  static Future<Map<String, dynamic>> rescheduleAppointment({
    required int appointmentId,
    required DateTime appointmentDate,
    required String slot,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.appointments}/$appointmentId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'appointment_date': appointmentDate.toIso8601String().split('T')[0],
          'slot': slot,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  // Helper method for parsing categorized appointments
// Parse categorized appointments from API response
  static Map<String, List<Map<String, dynamic>>> parseCategorizedAppointments(
      Map<String, dynamic> response) {
    if (response['success'] && response['data'] != null) {
      final data = response['data'];
      if (data['categorized'] != null) {
        return {
          'pending': List<Map<String, dynamic>>.from(
              data['categorized']['pending'] ?? []),
          'booked': List<Map<String, dynamic>>.from(
              data['categorized']['booked'] ?? []),
          'completed': List<Map<String, dynamic>>.from(
              data['categorized']['completed'] ?? []),
          'missed': List<Map<String, dynamic>>.from(
              data['categorized']['missed'] ?? []),
        };
      }
    }

    return {
      'pending': [],
      'booked': [],
      'completed': [],
      'missed': [],
    };
  }

  ///Messages

  /// Get completed appointments for doctor to send messages
  static Future<Map<String, dynamic>> getCompletedAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/messages/completed-appointments'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch completed appointments: $e');
    }
  }

  /// Send message to patient
  static Future<Map<String, dynamic>> sendMessage({
    required int appointmentId,
    required String doctorMessage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/messages/send'),
        headers: _getHeaders(),
        body: jsonEncode({
          'appointment_id': appointmentId,
          'doctor_message': doctorMessage,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Update existing message
  static Future<Map<String, dynamic>> updateMessage({
    required int messageId,
    required String doctorMessage,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/messages/$messageId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'doctor_message': doctorMessage,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  /// Delete message
  static Future<Map<String, dynamic>> deleteMessage(int messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/messages/$messageId'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get patient messages (for patient side)
  static Future<Map<String, dynamic>> getPatientMessages() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/messages/patient-messages'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch patient messages: $e');
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
