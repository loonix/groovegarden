import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthService {
  static Map<String, dynamic> decodeJWT(String token) {
    try {
      final jwt = JWT.decode(token); // Decode without verifying for now
      return jwt.payload as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JWT: $e');
      return {};
    }
  }
}
