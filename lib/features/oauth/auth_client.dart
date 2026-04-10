import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthClient {
  /// Login with email and password against the server's /auth/login endpoint.
  /// [serverBaseUrl] must be a normalized URL (e.g. http://192.168.1.50:8080).
  /// Returns the access token on success.
  Future<String> login(
      String serverBaseUrl, String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$serverBaseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(json['error'] ?? 'Login failed');
    }

    final token = json['token'] as String?;
    if (token == null || token.isEmpty) {
      throw AuthException('Server returned empty token');
    }
    return token;
  }

  /// Register with email, password and name.
  /// Returns the access token on success.
  Future<String> register(
      String serverBaseUrl, String email, String password, String name) async {
    final response = await http
        .post(
          Uri.parse('$serverBaseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'name': name,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(json['error'] ?? 'Registration failed');
    }

    final token = json['token'] as String?;
    if (token == null || token.isEmpty) {
      throw AuthException('Server returned empty token');
    }
    return token;
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
