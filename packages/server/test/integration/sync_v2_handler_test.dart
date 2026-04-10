import 'dart:convert';
import 'dart:io';

import 'package:cat_calories_core/http/router.dart';
import 'package:cat_calories_server/auth/auth_middleware.dart';
import 'package:cat_calories_server/data/sqlite/profile_repository.dart';
import 'package:cat_calories_server/data/sqlite/sync_entry_repository.dart';
import 'package:cat_calories_server/handler/sync_v2_handler.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

/// Sets up an in-memory SQLite DB with the needed schema.
Database _openTestDb() {
  final db = sqlite3.openInMemory();
  db.execute('PRAGMA journal_mode=WAL');
  db.execute('PRAGMA foreign_keys=ON');
  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      name TEXT NOT NULL DEFAULT '',
      password_hash TEXT NOT NULL DEFAULT '',
      provider TEXT NOT NULL DEFAULT 'local',
      subject TEXT NOT NULL DEFAULT '',
      created_at DATETIME NOT NULL DEFAULT (datetime('now')),
      updated_at DATETIME NOT NULL DEFAULT (datetime('now')),
      UNIQUE(provider, subject)
    )
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS profiles (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id),
      name TEXT NOT NULL DEFAULT '',
      waking_time_seconds INTEGER NOT NULL DEFAULT 57600,
      calories_limit_goal REAL NOT NULL DEFAULT 2000,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS calorie_items (
      id TEXT PRIMARY KEY,
      profile_id TEXT NOT NULL,
      waking_period_id TEXT,
      product_id TEXT,
      value REAL NOT NULL DEFAULT 0,
      description TEXT NOT NULL DEFAULT '',
      sort_order INTEGER NOT NULL DEFAULT 0,
      weight_grams REAL,
      protein_grams REAL,
      fat_grams REAL,
      carb_grams REAL,
      created_at_day INTEGER,
      eaten_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER
    )
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS sync_entries (
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      scope TEXT NOT NULL DEFAULT '',
      user_id TEXT NOT NULL,
      client_hlc TEXT NOT NULL DEFAULT '',
      server_hlc TEXT NOT NULL DEFAULT '',
      version INTEGER NOT NULL DEFAULT 1,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      payload TEXT,
      created_at DATETIME NOT NULL DEFAULT (datetime('now')),
      PRIMARY KEY (entity_type, entity_id)
    )
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS sync_idempotency (
      idempotency_key TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      accepted INTEGER NOT NULL DEFAULT 0,
      created_at DATETIME NOT NULL DEFAULT (datetime('now'))
    )
  ''');
  db.execute('''
    CREATE INDEX IF NOT EXISTS idx_sync_entries_pull
      ON sync_entries(user_id, entity_type, server_hlc)
  ''');
  return db;
}

void main() {
  late Database db;
  late SyncEntryRepository syncEntries;
  late ServerProfileRepository profiles;
  late TokenAuth tokenAuth;
  late HttpServer server;
  late String baseUrl;
  late String validToken;
  const userId = 'test-user-1';
  const secret = 'test-secret';

  setUp(() async {
    db = _openTestDb();
    syncEntries = SyncEntryRepository(db, HlcGenerator());
    profiles = ServerProfileRepository(db);
    tokenAuth = TokenAuth(secret);
    validToken = tokenAuth.createToken(userId);

    // Create the user so profile creation works (FK constraint).
    db.execute(
      "INSERT INTO users (id, email, name) VALUES (?, ?, ?)",
      [userId, 'test@test.com', 'Test'],
    );

    final userExtractor = createTokenExtractor(tokenAuth);

    final handler = SyncV2Handler(
      syncEntries: syncEntries,
      db: db,
      profiles: profiles,
      userExtractor: userExtractor,
    );

    final router = Router();
    router.register(handler);

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://localhost:${server.port}';

    server.listen((request) async {
      final result = router.resolve(request.method, request.uri.path);
      if (result != null) {
        final (routeHandler, params) = result;
        await routeHandler(request, params);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found')
          ..close();
      }
    });
  });

  tearDown(() async {
    await server.close(force: true);
    db.dispose();
  });

  Map<String, String> authHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $validToken',
      };

  // ---------------------------------------------------------------
  // Push endpoint
  // ---------------------------------------------------------------
  group('POST /api/v1/sync/push', () {
    test('returns 401 without auth', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idempotency_key': 'k1',
          'entity_type': 'calorie_item',
          'entries': [],
        }),
      );
      expect(response.statusCode, 401);
    });

    test('accepts new entries', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: jsonEncode({
          'idempotency_key': 'k1',
          'entity_type': 'calorie_item',
          'entries': [
            {
              'entity_id': 'e1',
              'version': 1,
              'hlc': '1000-0',
              'is_deleted': false,
              'scope': 'profile-1',
              'payload': {
                'id': 'e1',
                'value': 250.0,
                'description': 'Lunch',
                'sort_order': 0,
                'profile_id': 'profile-1',
                'created_at': 1000000,
                'updated_at': 1000000,
              },
            },
            {
              'entity_id': 'e2',
              'version': 1,
              'hlc': '1001-0',
              'is_deleted': false,
              'scope': 'profile-1',
              'payload': {
                'id': 'e2',
                'value': 100.0,
                'description': 'Snack',
                'sort_order': 1,
                'profile_id': 'profile-1',
                'created_at': 1001000,
                'updated_at': 1001000,
              },
            },
          ],
        }),
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['accepted'], 2);
      expect(body['rejected'], 0);
      expect(body['conflicts'], isEmpty);
      expect(body['server_timestamp'], isNotNull);
    });

    test('returns conflicts for stale versions', () async {
      // First push version 2
      await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: jsonEncode({
          'idempotency_key': 'k-setup',
          'entity_type': 'calorie_item',
          'entries': [
            {
              'entity_id': 'e1',
              'version': 2,
              'hlc': '2000-0',
              'is_deleted': false,
              'scope': 's',
              'payload': {'id': 'e1', 'value': 200.0, 'description': '', 'sort_order': 0, 'profile_id': 's', 'created_at': 1000, 'updated_at': 2000},
            },
          ],
        }),
      );

      // Then push version 1 — should be rejected
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: jsonEncode({
          'idempotency_key': 'k-stale',
          'entity_type': 'calorie_item',
          'entries': [
            {
              'entity_id': 'e1',
              'version': 1,
              'hlc': '1000-0',
              'is_deleted': false,
              'scope': 's',
              'payload': {'id': 'e1', 'value': 100.0, 'description': '', 'sort_order': 0, 'profile_id': 's', 'created_at': 1000, 'updated_at': 1000},
            },
          ],
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['accepted'], 0);
      expect(body['rejected'], 1);
      expect((body['conflicts'] as List).length, 1);

      final conflict = (body['conflicts'] as List).first;
      expect(conflict['entity_id'], 'e1');
      expect(conflict['server']['version'], 2);
      expect(conflict['local']['version'], 1);
    });

    test('idempotency returns cached result on duplicate key', () async {
      final pushBody = jsonEncode({
        'idempotency_key': 'idem-1',
        'entity_type': 'calorie_item',
        'entries': [
          {
            'entity_id': 'e1',
            'version': 1,
            'hlc': '1000-0',
            'is_deleted': false,
            'scope': 's',
            'payload': {'id': 'e1', 'value': 100.0, 'description': '', 'sort_order': 0, 'profile_id': 's', 'created_at': 1000, 'updated_at': 1000},
          },
        ],
      });

      final first = await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: pushBody,
      );
      final firstBody = jsonDecode(first.body) as Map<String, dynamic>;
      expect(firstBody['accepted'], 1);

      // Same idempotency key again
      final second = await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: pushBody,
      );
      final secondBody = jsonDecode(second.body) as Map<String, dynamic>;
      expect(secondBody['accepted'], 1);
      expect(secondBody['rejected'], 0);
      expect(secondBody['conflicts'], isEmpty);

      // Only one entry in DB despite two pushes
      final row = syncEntries.findByEntityId('calorie_item', 'e1');
      expect(row, isNotNull);
    });

    test('materializes calorie_item into calorie_items table', () async {
      await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: jsonEncode({
          'idempotency_key': 'k-mat',
          'entity_type': 'calorie_item',
          'entries': [
            {
              'entity_id': 'mat-1',
              'version': 1,
              'hlc': '1000-0',
              'is_deleted': false,
              'scope': 's',
              'payload': {
                'id': 'mat-1',
                'value': 350.0,
                'description': 'Dinner',
                'sort_order': 2,
                'profile_id': 's',
                'waking_period_id': null,
                'product_id': null,
                'weight_grams': 200.0,
                'protein_grams': 30.0,
                'fat_grams': 15.0,
                'carb_grams': 40.0,
                'created_at_day': 19000,
                'eaten_at': 2000000,
                'created_at': 1000000,
                'updated_at': 1000000,
              },
            },
          ],
        }),
      );

      final rows = db.select(
        'SELECT * FROM calorie_items WHERE id = ?',
        ['mat-1'],
      );
      expect(rows.length, 1);
      expect(rows.first['value'], 350.0);
      expect(rows.first['description'], 'Dinner');
      expect(rows.first['weight_grams'], 200.0);
      expect(rows.first['protein_grams'], 30.0);
    });

    test('materializes delete removes from calorie_items', () async {
      // First insert
      await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: jsonEncode({
          'idempotency_key': 'k-del-1',
          'entity_type': 'calorie_item',
          'entries': [
            {
              'entity_id': 'del-1',
              'version': 1,
              'hlc': '1000-0',
              'is_deleted': false,
              'scope': 's',
              'payload': {
                'id': 'del-1', 'value': 100.0, 'description': '',
                'sort_order': 0, 'profile_id': 's',
                'created_at': 1000, 'updated_at': 1000,
              },
            },
          ],
        }),
      );
      expect(
        db.select('SELECT * FROM calorie_items WHERE id = ?', ['del-1']).length,
        1,
      );

      // Delete
      await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: jsonEncode({
          'idempotency_key': 'k-del-2',
          'entity_type': 'calorie_item',
          'entries': [
            {
              'entity_id': 'del-1',
              'version': 2,
              'hlc': '2000-0',
              'is_deleted': true,
              'scope': 's',
            },
          ],
        }),
      );
      expect(
        db.select('SELECT * FROM calorie_items WHERE id = ?', ['del-1']).length,
        0,
      );
    });

    test('push with empty entries succeeds', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: jsonEncode({
          'idempotency_key': 'k-empty',
          'entity_type': 'calorie_item',
          'entries': [],
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['accepted'], 0);
      expect(body['rejected'], 0);
    });
  });

  // ---------------------------------------------------------------
  // Pull endpoint
  // ---------------------------------------------------------------
  group('GET /api/v1/sync/pull', () {
    test('returns 401 without auth', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/sync/pull?entity_type=calorie_item&since=&limit=100'),
      );
      expect(response.statusCode, 401);
    });

    test('returns empty when no data', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/sync/pull?entity_type=calorie_item&since=&limit=100'),
        headers: authHeaders(),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['entries'], isEmpty);
      expect(body['has_more'], isFalse);
    });

    test('returns pushed entries', () async {
      // Push 2 entries first
      await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: jsonEncode({
          'idempotency_key': 'k-pull-setup',
          'entity_type': 'calorie_item',
          'entries': [
            {
              'entity_id': 'p1', 'version': 1, 'hlc': '1000-0',
              'is_deleted': false, 'scope': 's',
              'payload': {'id': 'p1', 'value': 100.0, 'description': '', 'sort_order': 0, 'profile_id': 's', 'created_at': 1000, 'updated_at': 1000},
            },
            {
              'entity_id': 'p2', 'version': 1, 'hlc': '1001-0',
              'is_deleted': false, 'scope': 's',
              'payload': {'id': 'p2', 'value': 200.0, 'description': '', 'sort_order': 0, 'profile_id': 's', 'created_at': 1001, 'updated_at': 1001},
            },
          ],
        }),
      );

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/sync/pull?entity_type=calorie_item&since=&limit=100'),
        headers: authHeaders(),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final entries = body['entries'] as List;
      expect(entries.length, 2);
      expect(entries[0]['entity_id'], isNotNull);
      expect(entries[0]['payload'], isNotNull);
    });

    test('pagination with limit', () async {
      // Push 3 entries
      await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: authHeaders(),
        body: jsonEncode({
          'idempotency_key': 'k-page-setup',
          'entity_type': 'calorie_item',
          'entries': List.generate(
            3,
            (i) => {
              'entity_id': 'pg-$i', 'version': 1, 'hlc': '${1000 + i}-0',
              'is_deleted': false, 'scope': 's',
              'payload': {'id': 'pg-$i', 'value': i * 100.0, 'description': '', 'sort_order': i, 'profile_id': 's', 'created_at': 1000 + i, 'updated_at': 1000 + i},
            },
          ),
        }),
      );

      // Pull with limit 2
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/sync/pull?entity_type=calorie_item&since=&limit=2'),
        headers: authHeaders(),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect((body['entries'] as List).length, 2);
      expect(body['has_more'], isTrue);

      // Pull next page using server_timestamp from first page's last entry
      final serverHlc = (body['entries'] as List).last['server_hlc'] as String;
      final response2 = await http.get(
        Uri.parse('$baseUrl/api/v1/sync/pull?entity_type=calorie_item&since=$serverHlc&limit=2'),
        headers: authHeaders(),
      );
      final body2 = jsonDecode(response2.body) as Map<String, dynamic>;
      expect((body2['entries'] as List).length, 1);
      expect(body2['has_more'], isFalse);
    });

    test('limit is capped at 1000', () async {
      // Just verify the request succeeds with limit > 1000
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/sync/pull?entity_type=calorie_item&since=&limit=5000'),
        headers: authHeaders(),
      );
      expect(response.statusCode, 200);
    });
  });
}
