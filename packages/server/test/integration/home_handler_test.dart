import 'dart:convert';
import 'dart:io';

import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:cat_calories_core/http/router.dart';
import 'package:cat_calories_server/auth/auth_middleware.dart';
import 'package:cat_calories_server/data/sqlite/calorie_record_repository.dart';
import 'package:cat_calories_server/data/sqlite/database.dart';
import 'package:cat_calories_server/data/sqlite/profile_repository.dart';
import 'package:cat_calories_server/data/sqlite/sync_entry_repository.dart';
import 'package:cat_calories_server/handler/home_handler.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  const userId = 'user-1';
  const secret = 'test-secret';

  late Database db;
  late SyncEntryRepository syncEntries;
  late HttpServer server;
  late String token;
  late String profileId;

  final today = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }();
  DateTime daysAgo(int days) =>
      DateTime(today.year, today.month, today.day - days);

  void insertRecord(String id, DateTime day, double kcal) {
    final at = day.add(const Duration(hours: 12)).millisecondsSinceEpoch;
    db.execute(
      'INSERT INTO calorie_items '
      '(id, profile_id, value, record_day, eaten_at, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, profileId, kcal, day.millisecondsSinceEpoch ~/ 100000, at, at, at],
    );
  }

  void pushGap(
    DateTime start,
    DateTime end, {
    DateTime? deletedAt,
    String owner = userId,
  }) {
    final gap = TrackingGap(
      id: 'g1',
      profileId: 'phone-profile',
      startedAt: start,
      endedAt: end,
      description: null,
      createdAt: start,
      updatedAt: deletedAt ?? start,
      deletedAt: deletedAt,
    );
    syncEntries.upsert(
      entityType: 'tracking_gap',
      entityId: 'g1',
      scope: 'phone-profile',
      userId: owner,
      clientHlc: gap.updatedAt.toUtc().toIso8601String(),
      version: 1,
      isDeleted: false,
      payload: gap.toJson(),
    );
  }

  Future<double> average() async {
    final response = await http.get(
      Uri.parse('http://localhost:${server.port}/api/home'),
      headers: {'Authorization': 'Bearer $token'},
    );
    expect(response.statusCode, 200);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['avg_7_days'] as num).toDouble();
  }

  setUp(() async {
    db = openDatabase(':memory:');
    syncEntries = SyncEntryRepository(db, HlcGenerator());
    final profiles = ServerProfileRepository(db);
    final tokenAuth = TokenAuth(secret);
    token = tokenAuth.createToken(userId);

    db.execute(
      'INSERT INTO users (id, email, name) VALUES (?, ?, ?)',
      [userId, 'test@test.com', 'Test'],
    );
    profileId = (await profiles.getOrCreateForUser(userId)).id!;

    final router = Router();
    router.register(HomeHandler(
      db: db,
      profiles: profiles,
      records: ServerCalorieRecordRepository(db),
      syncEntries: syncEntries,
      userExtractor: createTokenExtractor(tokenAuth),
    ));

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final (handler, params) =
          router.resolve(request.method, request.uri.path)!;
      await handler(request, params);
    });

    insertRecord('r1', daysAgo(10), 2000);
    insertRecord('r2', daysAgo(2), 1400);
  });

  tearDown(() async {
    await server.close(force: true);
    db.dispose();
  });

  test('avg_7_days counts days without records as 0 kcal', () async {
    expect(await average(), 200);
  });

  test('avg_7_days leaves out the days of a pushed gap', () async {
    pushGap(daysAgo(1), today);

    expect(await average(), closeTo(1400 / 6, 0.001));
  });

  test('a gap of another user has no effect', () async {
    pushGap(daysAgo(1), today, owner: 'user-2');

    expect(await average(), 200);
  });

  test('a gap deleted on the phone stops counting', () async {
    pushGap(daysAgo(1), today);
    pushGap(daysAgo(1), today, deletedAt: DateTime.now());

    expect(await average(), 200);
  });
}
