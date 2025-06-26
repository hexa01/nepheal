import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../../core/storage/storage_service.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Check if user is logged in on app start
  Future<void> checkAuthStatus() async {
    final token = StorageService.getToken();
    if (token != null) {
      // TODO: Verify token with backend or load user data
      // For now, we'll assume token is valid
      final userId = StorageService.getUserId();
      if (userId != null) {
        // Create a basic user object from stored data
        // In production, you might want to fetch fresh user data
        notifyListeners();
      }
    }
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
    required String role,
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
        role: role,
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
    _setLoading(false);
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
