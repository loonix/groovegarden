import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _jwtKey = 'jwt_token';

  // Save token
  static Future<void> saveToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_jwtKey, token);
  }

  // Get token
  static Future<String?> getToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_jwtKey);
  }

  // Delete token
  static Future<void> deleteToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_jwtKey);
  }
}
