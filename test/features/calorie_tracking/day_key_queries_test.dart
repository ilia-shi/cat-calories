import 'package:cat_calories/database/migration_runner.dart';
import 'package:cat_calories/database/migrations/v001_initial_schema.dart';
import 'package:cat_calories/features/calorie_tracking/data/sqlite/calorie_record_repository.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'day_key_test_client.dart';

/// Exercises the day queries against a real SQLite database, because what they
/// answer depends on the stored `record_day` key rather than on any Dart
/// the fakes could stand in for.
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
  late CalorieRecordRepository repo;

  DateTime day(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset);
  }

  CalorieRecord record({
    required String id,
    required DateTime createdAt,
    double value = 100,
    DateTime? eatenAt,
    DateTime? plannedFor,
  }) {
    return CalorieRecord(
      id: id,
      value: value,
      description: null,
      sortOrder: 0,
      eatenAt: eatenAt,
      createdAt: createdAt,
      profileId: profile.id!,
      wakingPeriodId: null,
      plannedFor: plannedFor,
    );
  }

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await V001InitialSchema().up(db);
    repo = CalorieRecordRepository(TestDatabaseClient(db));
  });

  tearDown(() async => db.close());

  test('a record planned for another day answers for that day', () async {
    await repo.insert(record(
      id: 'planned',
      createdAt: day(0).add(const Duration(hours: 9)),
      plannedFor: day(3),
    ));

    expect((await repo.fetchByRecordDay(day(0))).map((r) => r.id), isEmpty);
    expect(
      (await repo.fetchByRecordDay(day(3))).map((r) => r.id),
      ['planned'],
    );
  });

  test('a record eaten on another day answers for the day it was eaten',
      () async {
    await repo.insert(record(
      id: 'late',
      createdAt: day(-2).add(const Duration(hours: 18)),
      plannedFor: day(-1),
      eatenAt: day(0).add(const Duration(hours: 13)),
    ));

    expect((await repo.fetchByRecordDay(day(-2))).map((r) => r.id), isEmpty);
    expect((await repo.fetchByRecordDay(day(-1))).map((r) => r.id), isEmpty);
    expect((await repo.fetchByRecordDay(day(0))).map((r) => r.id), ['late']);
  });

  test('today no longer sweeps up everything dated later', () async {
    await repo.insert(record(
      id: 'today',
      createdAt: day(0).add(const Duration(hours: 8)),
      eatenAt: day(0).add(const Duration(hours: 8)),
    ));
    await repo.insert(record(
      id: 'next-week',
      createdAt: day(0).add(const Duration(hours: 9)),
      plannedFor: day(7),
    ));

    final today = await repo.fetchByRecordDay(day(0));

    expect(today.map((r) => r.id), ['today']);
  });

  test('day totals count only what was eaten', () async {
    await repo.insert(record(
      id: 'eaten',
      value: 500,
      createdAt: day(-1).add(const Duration(hours: 12)),
      eatenAt: day(-1).add(const Duration(hours: 12)),
    ));
    await repo.insert(record(
      id: 'planned-same-day',
      value: 900,
      createdAt: day(-1).add(const Duration(hours: 13)),
      plannedFor: day(-1),
    ));

    final days = await repo.fetchDaysByProfile(profile, 30);

    expect(days.length, 1);
    expect(days.single.valueSum, 500,
        reason: 'the 900 kcal plan is not eaten calories');
  });

  test('a day holding only a plan is not a day result at all', () async {
    await repo.insert(record(
      id: 'eaten',
      value: 500,
      createdAt: day(-1).add(const Duration(hours: 12)),
      eatenAt: day(-1).add(const Duration(hours: 12)),
    ));
    await repo.insert(record(
      id: 'future',
      value: 700,
      createdAt: day(0),
      plannedFor: day(5),
    ));

    final days = await repo.fetchDaysByProfile(profile, 2);

    expect(
      days.map((d) => d.day),
      [day(-1)],
      reason: 'a future plan must not push a real day out of the window',
    );
  });

  test('updating a record moves its day key with it', () async {
    final item = record(
      id: 'r1',
      createdAt: day(-1).add(const Duration(hours: 20)),
      plannedFor: day(0),
    );
    await repo.insert(item);
    expect((await repo.fetchByRecordDay(day(0))).map((r) => r.id), ['r1']);

    item.eatenAt = day(1).add(const Duration(hours: 9));
    await repo.update(item);

    expect((await repo.fetchByRecordDay(day(0))), isEmpty);
    expect((await repo.fetchByRecordDay(day(1))).map((r) => r.id), ['r1']);
  });

  test('upgrading recomputes stale keys and renames the column', () async {
    // Back to the pre-rename shape, which is what a database that has not run
    // v018 still has. v001 now creates the column under its new name, so the
    // old one has to be put back to have anything to migrate.
    await db.execute(
        'ALTER TABLE calorie_items RENAME COLUMN record_day TO created_at_day');

    final eatenLate = record(
      id: 'stale',
      createdAt: day(-3).add(const Duration(hours: 18)),
      eatenAt: day(-1).add(const Duration(hours: 12)),
    );
    final json = eatenLate.toJson()..remove('record_day');
    // What the old rule stored: the day it was entered, not the day eaten.
    json['created_at_day'] =
        (DateTime(day(-3).year, day(-3).month, day(-3).day)
                    .millisecondsSinceEpoch /
                100000)
            .round();
    await db.insert('calorie_items', json);

    await MigrationRunner().onUpgrade(db, 16, 18);

    expect(
      (await repo.fetchByRecordDay(day(-1))).map((r) => r.id),
      ['stale'],
      reason: 'v017 recomputed the value, v018 renamed the column it sits in',
    );
    final columns = (await db.rawQuery('PRAGMA table_info(calorie_items)'))
        .map((row) => row['name'])
        .toSet();
    expect(columns, contains('record_day'));
    expect(columns, isNot(contains('created_at_day')));
  });
}
