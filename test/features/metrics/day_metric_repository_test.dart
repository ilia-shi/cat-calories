import 'package:cat_calories/database/migrations/v001_initial_schema.dart';
import 'package:cat_calories/database/migrations/v020_add_day_metrics.dart';
import 'package:cat_calories/features/metrics/data/day_metric_sync_repository.dart';
import 'package:cat_calories/features/metrics/data/sqlite/day_metric_repository.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../calorie_tracking/day_key_test_client.dart';

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
  late DayMetricRepository repo;

  DayMetricEntry entry({
    double value = 9000,
    DateTime? day,
    DateTime? now,
    String profileId = 'p1',
  }) =>
      DayMetricEntry.manual(
        profileId: profileId,
        metric: DayMetric.steps,
        day: day ?? DateTime(2026, 10, 9),
        value: value,
        note: null,
        now: now ?? DateTime(2026, 10, 10),
      );

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = OFF');
    await V001InitialSchema().up(db);
    repo = DayMetricRepository(TestDatabaseClient(db));
  });

  tearDown(() async => db.close());

  test('a fresh install and v020 build the same table and index', () async {
    Future<List<Object?>> schema(Database database) async {
      final columns =
          await database.rawQuery('PRAGMA table_info(day_metric_entries)');
      final indexes =
          await database.rawQuery('PRAGMA index_list(day_metric_entries)');

      return [
        ...columns.map((row) => (row['name'], row['type'], row['notnull'])),
        ...indexes.map((row) => row['name']),
      ];
    }

    final upgraded = await databaseFactory.openDatabase(inMemoryDatabasePath);
    addTearDown(upgraded.close);
    await upgraded.execute('CREATE TABLE IF NOT EXISTS profiles(id TEXT)');
    await upgraded.execute('DROP TABLE IF EXISTS day_metric_entries');
    await V020AddDayMetrics().up(upgraded);

    expect(await schema(upgraded), await schema(db));
  });

  test('saving twice for one day leaves one row with the last value', () async {
    await repo.save(entry(value: 9000));
    await repo.save(entry(value: 9500, now: DateTime(2026, 10, 11)));

    final rows = await repo.fetchByProfile(profile);

    expect(rows, hasLength(1));
    expect(rows.single.value, 9500);
    expect(rows.single.createdAt, DateTime(2026, 10, 10));
    expect(rows.single.updatedAt, DateTime(2026, 10, 11));
  });

  test('a cleared value is hidden from lists and kept for sync', () async {
    await repo.save(entry());
    await repo.delete(entry());

    expect(await repo.fetchByProfile(profile), isEmpty);
    expect((await repo.findAll()).single.isDeleted, isTrue);
  });

  test('entering a value after clearing revives the row', () async {
    await repo.save(entry());
    await repo.delete(entry());
    await repo.save(entry(value: 100, now: DateTime(2030)));

    final rows = await repo.fetchByProfile(profile);

    expect(rows.single.value, 100);
    expect(rows.single.isDeleted, isFalse);
    expect(await repo.findAll(), hasLength(1));
  });

  test('lists only the given profile', () async {
    await repo.save(entry());
    await repo.save(entry(profileId: 'p2'));

    expect((await repo.fetchByProfile(profile)).single.profileId, 'p1');
  });

  test('a null note and an unknown metric survive the table', () async {
    final json = entry().toJson()..['metric_key'] = 'heart_rate';
    await repo.save(DayMetricEntry.fromJson(json));

    final row = (await repo.fetchByProfile(profile)).single;

    expect(row.metric, isNull);
    expect(row.note, isNull);
  });

  group('DayMetricSyncRepository', () {
    test('sends deleted rows and only linked profiles', () async {
      await repo.save(entry());
      await repo.delete(entry());
      await repo.save(entry(profileId: 'p2'));

      final rows = await DayMetricSyncRepository(repo).findAllByScopes({'p1'});

      expect(rows.single.isDeleted, isTrue);
    });

    test('a pulled cleared value hides the local one', () async {
      await repo.save(entry());

      await DayMetricSyncRepository(repo)
          .upsert(entry().markedDeleted(DateTime(2030)));

      expect(await repo.fetchByProfile(profile), isEmpty);
    });
  });
}
