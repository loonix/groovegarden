import 'dart:html' as html;

class SecureStorage {
  static const String _tokenKey = 'auth_token';

  // Save token to storage
  static Future<void> saveToken(String token) async {
    html.window.localStorage[_tokenKey] = token;

    // Signal token change to other tabs
    html.window.localStorage['oauth_token_received'] = 'true';

    return;
  }

  // Get token from storage
  static Future<String?> getToken() async {
    final token = html.window.localStorage[_tokenKey];
    return token;
  }

  // Clear token from storage
  static Future<void> clearToken() async {
    html.window.localStorage.remove(_tokenKey);
    return;
  }

  // Alias for clearToken for backward compatibility
  static Future<void> deleteToken() async {
    return clearToken();
  }
}
