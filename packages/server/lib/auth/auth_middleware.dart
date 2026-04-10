import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Extracts user ID from a request. Returns null if unauthorized.
typedef UserExtractor = Future<String?> Function(HttpRequest request);

/// Simple HMAC-based token auth.
///
/// Tokens are issued by the login endpoint: `sha256(userId + ':' + secret)`.
/// The Authorization header is: `Bearer <userId>:<hmac>`.
class TokenAuth {
  final String _secret;

  TokenAuth(this._secret);

  /// Create a token for a given user ID.
  String createToken(String userId) {
    final hmac = _sign(userId);
    return '$userId:$hmac';
  }

  /// Verify a bearer token. Returns the user ID if valid, null otherwise.
  String? verify(String token) {
    final parts = token.split(':');
    if (parts.length != 2) return null;
    final userId = parts[0];
    final providedHmac = parts[1];
    final expectedHmac = _sign(userId);
    if (providedHmac != expectedHmac) return null;
    return userId;
  }

  String _sign(String userId) {
    final hmac = Hmac(sha256, utf8.encode(_secret));
    return hmac.convert(utf8.encode(userId)).toString();
  }
}

/// Middleware that extracts user ID from the Authorization header.
///
/// Supports:
/// - `Bearer <userId>:<hmac>` (simple token auth)
///
/// Returns a [UserExtractor] function.
UserExtractor createTokenExtractor(TokenAuth tokenAuth) {
  return (HttpRequest request) async {
    final authHeader = request.headers.value('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    final token = authHeader.substring('Bearer '.length);
    return tokenAuth.verify(token);
  };
}

/// Convenience: reject request with 401 if user is not authenticated.
Future<String?> requireAuth(HttpRequest request, UserExtractor extractor) async {
  final userId = await extractor(request);
  if (userId == null) {
    request.response
      ..statusCode = HttpStatus.unauthorized
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Unauthorized'}))
      ..close();
    return null;
  }
  return userId;
}
