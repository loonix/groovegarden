import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:groovegarden_flutter/utils/secure_storage.dart';
import 'package:groovegarden_flutter/services/api_service.dart'; // Add this import

class AuthService {
  /// Decode a JWT token
  static Map<String, dynamic> decodeJWT(String token) {
    try {
      // JWT token has three parts separated by dots
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint('Invalid JWT format - parts: ${parts.length}');
        return {};
      }

      // Decode the payload (second part)
      String normalizedPayload = parts[1].replaceAll('-', '+').replaceAll('_', '/');

      // Add padding if needed
      switch (normalizedPayload.length % 4) {
        case 0:
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
        default:
          throw Exception('Invalid base64 string');
      }

      // Decode the base64 string
      final payloadBytes = base64Url.decode(normalizedPayload);
      final payloadString = utf8.decode(payloadBytes);
      final payload = jsonDecode(payloadString);

      debugPrint('JWT Payload decoded: $payload');
      return payload;
    } catch (e) {
      debugPrint('Error decoding JWT: $e');
      return {};
    }
  }

  /// Check if the token is expired
  static bool isTokenExpired(String token) {
    try {
      final payload = decodeJWT(token);
      if (payload.containsKey('exp')) {
        final expTimestamp = payload['exp'] as int;
        final expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);

        // Consider token expired if it expires in less than 5 minutes
        return DateTime.now().isAfter(expDate.subtract(const Duration(minutes: 5)));
      }
      return true; // If no expiration claim, consider it expired
    } catch (e) {
      debugPrint('Error checking token expiry: $e');
      return true; // Consider expired on error
    }
  }

  /// Refresh the JWT token
  static Future<String?> refreshToken(String currentToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'] as String;

        // Save the refreshed token
        await SecureStorage.saveToken(newToken);

        debugPrint('Token refreshed successfully');
        return newToken;
      } else {
        debugPrint('Failed to refresh token: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }
}
