import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management
  static Future<void> saveToken(String token) async {
    await _prefs?.setString('auth_token', token);
  }

  static String? getToken() {
    return _prefs?.getString('auth_token');
  }

  static Future<void> removeToken() async {
    await _prefs?.remove('auth_token');
  }

  // User data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs?.setString('user_id', userData['id'].toString());
    await _prefs?.setString('user_name', userData['name'] ?? '');
    await _prefs?.setString('user_email', userData['email'] ?? '');
    await _prefs?.setString('user_role', userData['role'] ?? '');
    
    // Save additional user fields if they exist
    if (userData['gender'] != null) {
      await _prefs?.setString('user_gender', userData['gender']);
    }
    if (userData['phone'] != null) {
      await _prefs?.setString('user_phone', userData['phone']);
    }
    if (userData['address'] != null) {
      await _prefs?.setString('user_address', userData['address']);
    }
    if (userData['profile_photo_url'] != null) {
      await _prefs?.setString('user_profile_photo_url', userData['profile_photo_url']);
    }
    if (userData['created_at'] != null) {
      await _prefs?.setString('user_created_at', userData['created_at']);
    }
    if (userData['updated_at'] != null) {
      await _prefs?.setString('user_updated_at', userData['updated_at']);
    }
  }

  // Get complete user data as Map
  static Map<String, dynamic>? getUserData() {
    final userId = getUserId();
    final userName = getUserName();
    final userEmail = getUserEmail();
    final userRole = getUserRole();
    
    // Return null if essential data is missing
    if (userId == null || userRole == null) {
      return null;
    }
    
    return {
      'id': int.tryParse(userId) ?? 0,
      'name': userName ?? 'User',
      'email': userEmail ?? '',
      'role': userRole,
      'gender': getUserGender() ?? 'male',
      'phone': getUserPhone(),
      'address': getUserAddress(),
      'profile_photo_url': getUserProfilePhotoUrl(),
      'created_at': getUserCreatedAt() ?? DateTime.now().toIso8601String(),
      'updated_at': getUserUpdatedAt() ?? DateTime.now().toIso8601String(),
    };
  }

  // Existing methods
  static String? getUserRole() {
    return _prefs?.getString('user_role');
  }

  static String? getUserId() {
    return _prefs?.getString('user_id');
  }

  // 🆕 ADD: Additional getter methods
  static String? getUserName() {
    return _prefs?.getString('user_name');
  }

  static String? getUserEmail() {
    return _prefs?.getString('user_email');
  }

  static String? getUserGender() {
    return _prefs?.getString('user_gender');
  }

  static String? getUserPhone() {
    return _prefs?.getString('user_phone');
  }

  static String? getUserAddress() {
    return _prefs?.getString('user_address');
  }

  static String? getUserProfilePhotoUrl() {
    return _prefs?.getString('user_profile_photo_url');
  }

  static String? getUserCreatedAt() {
    return _prefs?.getString('user_created_at');
  }

  static String? getUserUpdatedAt() {
    return _prefs?.getString('user_updated_at');
  }

  // Update individual user fields
  static Future<void> updateUserField(String field, String? value) async {
    if (value != null) {
      await _prefs?.setString('user_$field', value);
    } else {
      await _prefs?.remove('user_$field');
    }
  }

  static Future<void> clearUserData() async {
    await _prefs?.remove('user_id');
    await _prefs?.remove('user_name');
    await _prefs?.remove('user_email');
    await _prefs?.remove('user_role');
    
    // Clear additional user fields
    await _prefs?.remove('user_gender');
    await _prefs?.remove('user_phone');
    await _prefs?.remove('user_address');
    await _prefs?.remove('user_profile_photo_url');
    await _prefs?.remove('user_created_at');
    await _prefs?.remove('user_updated_at');
  }
}