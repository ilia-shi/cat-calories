import 'package:cat_calories/database/migrations/v001_initial_schema.dart';
import 'package:cat_calories/database/migrations/v019_add_tracking_gaps.dart';
import 'package:cat_calories/features/calorie_tracking/data/sqlite/calorie_record_repository.dart';
import 'package:cat_calories/features/calorie_tracking/data/sqlite/tracking_gap_repository.dart';
import 'package:cat_calories/features/calorie_tracking/data/tracking_gap_sync_repository.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'day_key_test_client.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final profile = Profile(
    id: 'p1',
    name: 'Test',
    wakingTimeSeconds: 16 * 60 * 60,
    caloriesLimitGoal: 2000,
    createdAt: DateTime(2020),
    updatedAt: DateTime(2020),
  );

  late Database db;
  late TrackingGapRepository repo;

  TrackingGap gap({String? id, String? description}) => TrackingGap(
        id: id,
        profileId: 'p1',
        startedAt: DateTime(2026, 10, 9, 18),
        endedAt: DateTime(2026, 10, 9, 23),
        description: description,
        createdAt: DateTime(2026, 10, 10),
        updatedAt: DateTime(2026, 10, 10),
      );

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = OFF');
    await V001InitialSchema().up(db);
    repo = TrackingGapRepository(TestDatabaseClient(db));
  });

  tearDown(() async => db.close());

  test('a fresh install has the table and v019 builds the same columns',
      () async {
    Future<List<String?>> columns(Database database) async {
      final rows = await database.rawQuery('PRAGMA table_info(tracking_gaps)');
      return rows.map((row) => row['name'] as String?).toList();
    }

    final upgraded =
        await databaseFactory.openDatabase(inMemoryDatabasePath);
    addTearDown(upgraded.close);
    await upgraded.execute('CREATE TABLE IF NOT EXISTS profiles(id TEXT)');
    await upgraded.execute('DROP TABLE IF EXISTS tracking_gaps');
    await V019AddTrackingGaps().up(upgraded);

    expect(await columns(upgraded), await columns(db));
  });

  test('insert assigns an id and the gap round-trips', () async {
    final saved = await repo.insert(gap(description: 'Dinner out'));

    final found = await repo.find(saved.id!);

    expect(saved.id, isNotNull);
    expect(found!.description, 'Dinner out');
    expect(found.endedAt, DateTime(2026, 10, 9, 23));
  });

  test('a deleted gap leaves the profile list but stays for sync', () async {
    final saved = await repo.insert(gap());

    await repo.delete(saved);

    expect(await repo.fetchByProfile(profile), isEmpty);
    final syncRepo = TrackingGapSyncRepository(repo);
    final forSync = await syncRepo.findAllByScopes({'p1'});
    expect(forSync.single.isDeleted, isTrue);
    expect((await syncRepo.findById(saved.id!))!.isDeleted, isTrue);
  });

  test('a delete moves updatedAt so it wins last-write-wins', () async {
    final saved = await repo.insert(gap());
    final before = saved.updatedAt;

    await repo.delete(saved);

    final found = await repo.find(saved.id!);
    expect(found!.updatedAt.isAfter(before), isTrue);
  });

  test('sync skips gaps of an unlinked profile', () async {
    await repo.insert(gap());

    final forSync =
        await TrackingGapSyncRepository(repo).findAllByScopes({'other'});

    expect(forSync, isEmpty);
  });

  test('fetchFirstRecordDay returns the earliest eaten day only', () async {
    final records = CalorieRecordRepository(TestDatabaseClient(db));

    expect(await records.fetchFirstRecordDay(profile), isNull);

    await records.insert(CalorieRecord(
      id: 'eaten',
      value: 300,
      description: null,
      sortOrder: 0,
      eatenAt: DateTime(2026, 10, 5, 12),
      createdAt: DateTime(2026, 10, 5, 12),
      profileId: 'p1',
      wakingPeriodId: null,
    ));
    await records.insert(CalorieRecord(
      id: 'not-eaten',
      value: 300,
      description: null,
      sortOrder: 0,
      eatenAt: null,
      createdAt: DateTime(2026, 9, 1, 12),
      profileId: 'p1',
      wakingPeriodId: null,
    ));

    expect(await records.fetchFirstRecordDay(profile), DateTime(2026, 10, 5));
  });
}
