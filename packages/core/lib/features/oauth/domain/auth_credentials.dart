final class AuthCredentials {
  final String id;
  final String serverId;
  final String accessToken;
  final String tokenType;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const AuthCredentials({
    required this.id,
    required this.serverId,
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.createdAt,
    this.expiresAt,
  });

  factory AuthCredentials.fromJson(Map<String, dynamic> json) =>
      AuthCredentials(
        id: json['id'],
        serverId: json['server_id'],
        accessToken: json['access_token'],
        tokenType: json['token_type'] ?? 'bearer',
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
        expiresAt: json['expires_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['expires_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'server_id': serverId,
        'access_token': accessToken,
        'token_type': tokenType,
        'created_at': createdAt.millisecondsSinceEpoch,
        'expires_at': expiresAt?.millisecondsSinceEpoch,
      };
}
