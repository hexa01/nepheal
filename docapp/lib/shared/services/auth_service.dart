import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../../core/storage/storage_service.dart';
import 'api_service.dart';
import 'doctor_service.dart';
import 'appointment_service.dart';
import 'message_service.dart';
import 'review_service.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  // Service references
  DoctorService? _doctorService;
  AppointmentService? _appointmentService;
  MessageService? _messageService;
  ReviewService? _reviewService;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Check if user is logged in on app start
  Future<void> checkAuthStatus() async {
    final token = StorageService.getToken();
    if (token != null) {
      final userId = StorageService.getUserId();
      if (userId != null) {
        // Load user data from storage
        final userData = StorageService.getUserData();
        if (userData != null) {
          _user = User.fromJson(userData);
          notifyListeners();
          
          // Load background data for authenticated user
          _loadBackgroundData();
        }
      }
    }
  }

  // Set service references
  void setDoctorService(DoctorService doctorService) {
    _doctorService = doctorService;
  }

  void setAppointmentService(AppointmentService appointmentService) {
    _appointmentService = appointmentService;
  }

  void setMessageService(MessageService messageService) {
    _messageService = messageService;
  }

  void setReviewService(ReviewService reviewService) {
    _reviewService = reviewService;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        final token = response['data']['token'];
        final userData = response['data']['user'];

        await StorageService.saveToken(token);
        await StorageService.saveUserData(userData);

        _user = User.fromJson(userData);
        
        // 🆕 Load background data based on user role
        _loadBackgroundData();
        
        _setLoading(false);
        return true;
      } else {
        _error = response['message'] ?? 'Login failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String gender,
    String? phone,
    String? address,
    DateTime? dob,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        role: "patient",
        gender: gender,
        phone: phone,
        address: address,
        dob: dob,
      );

      if (response['success'] == true) {
        final token = response['data']['token'];
        final userData = response['data']['user'];

        await StorageService.saveToken(token);
        await StorageService.saveUserData(userData);

        _user = User.fromJson(userData);
        
        // 🆕 Load background data for new patient
        _loadBackgroundData();
        
        _setLoading(false);
        return true;
      } else {
        _error = response['message'] ?? 'Registration failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await ApiService.logout();
    } catch (e) {
      // Even if logout API fails, we should clear local data
      debugPrint('Logout API error: $e');
    }

    await StorageService.removeToken();
    await StorageService.clearUserData();
    _user = null;
    
    // 🆕 Clear all service caches when logging out
    _clearAllCaches();
    
    _setLoading(false);
  }

  /// Load background data based on user role
  void _loadBackgroundData() {
    if (_user == null) return;
    
    final userRole = _user!.role;
    
    try {
      // Load data based on role
      if (userRole == 'patient') {
        _doctorService?.loadInitialData();
        _appointmentService?.loadInitialData(userRole);
        _messageService?.loadInitialData(userRole);
        _reviewService?.loadInitialData(userRole);
      } else if (userRole == 'doctor') {
        _appointmentService?.loadInitialData(userRole);
        _messageService?.loadInitialData(userRole);
        _reviewService?.loadInitialData(userRole);
      }
      
      debugPrint('🔄 Loading background data for $userRole...');
    } catch (e) {
      debugPrint('Error loading background data: $e');
    }
  }

  /// Clear all service caches
  void _clearAllCaches() {
    _doctorService?.clearCache();
    _appointmentService?.clearCache();
    _messageService?.clearCache();
    _reviewService?.clearCache();
    
    debugPrint('🧹 Cleared all caches');
  }

  /// Refresh all data for current user
  Future<void> refreshAllData() async {
    if (_user == null) return;
    
    final userRole = _user!.role;
    
    try {
      if (userRole == 'patient') {
        await Future.wait([
          _doctorService?.refreshAllData() ?? Future.value(),
          _appointmentService?.refreshAllData(userRole) ?? Future.value(),
          _messageService?.refreshAllData(userRole) ?? Future.value(),
          _reviewService?.refreshAllData(userRole) ?? Future.value(),
        ]);
      } else if (userRole == 'doctor') {
        await Future.wait([
          _appointmentService?.refreshAllData(userRole) ?? Future.value(),
          _messageService?.refreshAllData(userRole) ?? Future.value(),
          _reviewService?.refreshAllData(userRole) ?? Future.value(),
        ]);
      }
      
      debugPrint('🔄 Refreshed all data for $userRole');
    } catch (e) {
      debugPrint('Error refreshing all data: $e');
    }
  }

  // NEW: Update user profile photo
  void updateUserPhoto(String? newPhotoUrl) {
    if (_user != null) {
      _user = _user!.copyWith(
        profilePhotoUrl: newPhotoUrl,
        updateProfilePhotoUrl: true,
      );
      notifyListeners();
    }
  }

  // NEW: Update user data
  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  // NEW: Refresh user data from server
  Future<void> refreshUserData() async {
    try {
      final response = await ApiService.getProfilePhoto();
      if (response['success'] && _user != null) {
        final photoUrl = response['data']['profile_photo_url'];
        updateUserPhoto(photoUrl);
      }
    } catch (e) {
      debugPrint('Failed to refresh user data: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}