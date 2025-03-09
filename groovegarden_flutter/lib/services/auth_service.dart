import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';

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
}
