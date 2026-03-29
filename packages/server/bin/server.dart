import 'dart:io';

import 'package:cat_calories_core/http/router.dart';
import 'package:cat_calories_server/auth/auth_middleware.dart';
import 'package:cat_calories_server/config/config.dart';
import 'package:cat_calories_server/data/sqlite/database.dart';
import 'package:cat_calories_server/data/sqlite/calorie_record_repository.dart';
import 'package:cat_calories_server/data/sqlite/profile_repository.dart';
import 'package:cat_calories_server/data/sqlite/sync_entry_repository.dart';
import 'package:cat_calories_server/data/sqlite/user_repository.dart';
import 'package:cat_calories_server/handler/auth_handler.dart';
import 'package:cat_calories_server/handler/discovery_handler.dart';
import 'package:cat_calories_server/handler/health_handler.dart';
import 'package:cat_calories_server/handler/sync_v2_handler.dart';

void main() async {
  final config = ServerConfig.fromEnvironment();

  // Database
  final db = openDatabase(config.databasePath);
  print('Database opened: ${config.databasePath}');

  // Repositories
  final userRepo = UserRepository(db);
  // ignore: unused_local_variable
  final profileRepo = ServerProfileRepository(db);
  // ignore: unused_local_variable
  final calorieRecordRepo = ServerCalorieRecordRepository(db);
  final syncEntryRepo = SyncEntryRepository(db, HlcGenerator());

  // Auth
  final tokenAuth = TokenAuth(config.serverSecret);
  final userExtractor = createTokenExtractor(tokenAuth);

  // Router
  final router = Router();

  // Public handlers
  final healthHandler = HealthHandler(db: db, version: config.serverVersion);
  final authHandler = AuthHandler(users: userRepo, tokenAuth: tokenAuth);
  final discoveryHandler = DiscoveryHandler(config: config);

  router.register(healthHandler);
  router.register(authHandler);
  router.register(discoveryHandler);

  // Protected handlers
  final syncV2Handler = SyncV2Handler(
    syncEntries: syncEntryRepo,
    userExtractor: userExtractor,
  );
  router.register(syncV2Handler);

  // Root route
  router.get('/', (HttpRequest request, Map<String, String> params) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write('{"name":"${config.serverName}","version":"${config.serverVersion}"}')
      ..close();
  });

  // Static file serving (SPA)
  final webDistPath = config.webDistPath;

  // Start HTTP server
  final server = await HttpServer.bind(InternetAddress.anyIPv4, config.port);
  print('Server listening on :${config.port}');

  await for (final request in server) {
    try {
      _addCorsHeaders(request.response);

      // CORS preflight
      if (request.method == 'OPTIONS') {
        request.response
          ..statusCode = HttpStatus.ok
          ..close();
        continue;
      }

      // Log request
      print('${request.method} ${request.uri.path}');

      // Try router first
      final match = router.resolve(request.method, request.uri.path);
      if (match != null) {
        final (handler, params) = match;
        await handler(request, params);
        continue;
      }

      // Static file serving
      if (webDistPath != null) {
        await _serveStaticFile(request, webDistPath);
        continue;
      }

      // 404
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.json
        ..write('{"error":"Not found"}')
        ..close();
    } catch (e, st) {
      print('Error handling ${request.uri.path}: $e\n$st');
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..headers.contentType = ContentType.json
          ..write('{"error":"Internal server error"}')
          ..close();
      } catch (_) {}
    }
  }
}

void _addCorsHeaders(HttpResponse response) {
  response.headers.add('Access-Control-Allow-Origin', '*');
  response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

Future<void> _serveStaticFile(HttpRequest request, String webDistPath) async {
  var filePath = '$webDistPath${request.uri.path}';
  var file = File(filePath);

  // SPA fallback: serve index.html for non-file paths
  if (!await file.exists()) {
    file = File('$webDistPath/index.html');
  }

  if (await file.exists()) {
    final contentType = _contentTypeForPath(file.path);
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = contentType;
    await file.openRead().pipe(request.response);
  } else {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Not found')
      ..close();
  }
}

ContentType _contentTypeForPath(String path) {
  if (path.endsWith('.html')) return ContentType.html;
  if (path.endsWith('.js')) return ContentType('application', 'javascript', charset: 'utf-8');
  if (path.endsWith('.css')) return ContentType('text', 'css', charset: 'utf-8');
  if (path.endsWith('.json')) return ContentType.json;
  if (path.endsWith('.svg')) return ContentType('image', 'svg+xml');
  if (path.endsWith('.png')) return ContentType('image', 'png');
  if (path.endsWith('.ico')) return ContentType('image', 'x-icon');
  return ContentType.binary;
}
