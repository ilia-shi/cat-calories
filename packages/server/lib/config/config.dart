import 'dart:io';

class ServerConfig {
  final String databasePath;
  final int port;
  final String serverSecret;
  final String? webDistPath;

  final String serverName;
  final String serverVersion;
  final String serverBaseUrl;

  // OAuth provider
  final String oauthEndpoint;
  final String? oauthClientId;
  final String? oauthClientSecret;
  final String oauthOrganization;
  final String oauthApplication;

  const ServerConfig({
    required this.databasePath,
    required this.port,
    required this.serverSecret,
    this.webDistPath,
    required this.serverName,
    required this.serverVersion,
    required this.serverBaseUrl,
    required this.oauthEndpoint,
    this.oauthClientId,
    this.oauthClientSecret,
    required this.oauthOrganization,
    required this.oauthApplication,
  });

  factory ServerConfig.fromEnvironment() {
    return ServerConfig(
      databasePath: _env('DATABASE_PATH', './data.db'),
      port: int.parse(_env('SERVER_PORT', '8080')),
      serverSecret: _env('SERVER_SECRET', ''),
      webDistPath: Platform.environment['WEB_DIST_PATH'],
      serverName: _env('SERVER_NAME', 'Cat Calories Sync'),
      serverVersion: _env('SERVER_VERSION', '2.0.0'),
      serverBaseUrl: _env('SERVER_BASE_URL', 'http://localhost:8080'),
      oauthEndpoint: _env('OAUTH_ENDPOINT', 'http://casdoor:8000'),
      oauthClientId: Platform.environment['OAUTH_CLIENT_ID'],
      oauthClientSecret: Platform.environment['OAUTH_CLIENT_SECRET'],
      oauthOrganization: _env('OAUTH_ORGANIZATION', 'built-in'),
      oauthApplication: _env('OAUTH_APPLICATION', 'cat-calories'),
    );
  }

  bool get hasOAuth => oauthClientId != null && oauthClientId!.isNotEmpty;

  static String _env(String key, String fallback) {
    return Platform.environment[key] ?? fallback;
  }
}
