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
    await _prefs?.setString('user_name', userData['name']);
    await _prefs?.setString('user_email', userData['email']);
    await _prefs?.setString('user_role', userData['role']);
  }

  static String? getUserRole() {
    return _prefs?.getString('user_role');
  }

  static String? getUserId() {
    return _prefs?.getString('user_id');
  }

  static Future<void> clearUserData() async {
    await _prefs?.remove('user_id');
    await _prefs?.remove('user_name');
    await _prefs?.remove('user_email');
    await _prefs?.remove('user_role');
  }
}
