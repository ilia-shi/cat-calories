import 'dart:io';

import 'package:cat_calories/database/migrations/v001_initial_schema.dart';
import 'package:cat_calories/features/metrics/data/day_metric_sync_repository.dart';
import 'package:cat_calories/features/metrics/data/sqlite/day_metric_repository.dart';
import 'package:cat_calories/features/sync/syncer.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:cat_calories_core/features/metrics/sync/day_metric_sync_adapter.dart';
import 'package:cat_calories_core/features/oauth/domain/auth_credentials_repository.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/profile/domain/profile_repository_interface.dart';
import 'package:cat_calories_core/features/sync/domain/scoped_server_link_repository.dart';
import 'package:cat_calories_core/features/sync/domain/sync_server_repository.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../calorie_tracking/day_key_test_client.dart';

class _UnusedServers implements SyncServerRepositoryInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedCredentials implements AuthCredentialsRepositoryInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedLinks implements ScopedServerLinkRepositoryInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles implements ProfileRepositoryInterface {
  final List<Profile> profiles;

  _Profiles(this.profiles);

  @override
  Future<List<Profile>> fetchAll() async => profiles;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Profile _profile(String id) => Profile(
      id: id,
      name: id,
      wakingTimeSeconds: 16 * 60 * 60,
      caloriesLimitGoal: 2000,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );

class _Phone {
  final Directory support;
  final Database db;
  final DayMetricRepository repo;
  final Syncer syncer;

  _Phone._(this.support, this.db, this.repo, this.syncer);

  static Future<_Phone> create(Directory base, String name, String profile) async {
    final support = Directory('${base.path}/$name')..createSync();
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false));
    await db.execute('PRAGMA foreign_keys = OFF');
    await V001InitialSchema().up(db);
    final repo = DayMetricRepository(TestDatabaseClient(db));
    final registry = SyncAdapterRegistry()
      ..register(DayMetricSyncAdapter(), DayMetricSyncRepository(repo));

    return _Phone._(
      support,
      db,
      repo,
      Syncer(
        serverRepo: _UnusedServers(),
        credentialsRepo: _UnusedCredentials(),
        linkRepo: _UnusedLinks(),
        profileRepo: _Profiles([_profile(profile)]),
        registry: registry,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory temp;
  late String folder;

  Future<void> sync(_Phone phone) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => phone.support.path);

    final result = await phone.syncer.syncFolder(folder);

    expect(result.error, isNull);
  }

  DayMetricEntry steps(double value, DateTime now, {String profile = 'p1'}) =>
      DayMetricEntry.manual(
        profileId: profile,
        metric: DayMetric.steps,
        day: DateTime(2026, 10, 9),
        value: value,
        note: null,
        now: now,
      );

  setUp(() {
    temp = Directory.systemTemp.createTempSync('day_metric_sync');
    folder = (Directory('${temp.path}/folder')..createSync()).path;
  });

  tearDown(() => temp.deleteSync(recursive: true));

  test('two phones entering one day end with the later value', () async {
    final phone = await _Phone.create(temp, 'phone', 'p1');
    final tablet = await _Phone.create(temp, 'tablet', 'p1');
    addTearDown(phone.db.close);
    addTearDown(tablet.db.close);

    await phone.repo.save(steps(9000, DateTime(2026, 10, 10, 9)));
    await tablet.repo.save(steps(9500, DateTime(2026, 10, 10, 10)));

    await sync(phone);
    await sync(tablet);
    await sync(phone);

    for (final device in [phone, tablet]) {
      final rows = await device.repo.fetchByProfile(_profile('p1'));
      expect(rows.single.value, 9500);
    }
  });

  test('a cleared value is cleared on the other phone', () async {
    final phone = await _Phone.create(temp, 'phone', 'p1');
    final tablet = await _Phone.create(temp, 'tablet', 'p1');
    addTearDown(phone.db.close);
    addTearDown(tablet.db.close);

    final saved = steps(9000, DateTime(2026, 10, 10, 9));
    await phone.repo.save(saved);
    await sync(phone);
    await sync(tablet);
    expect(await tablet.repo.fetchByProfile(_profile('p1')), hasLength(1));

    await phone.repo.delete(saved);
    await sync(phone);
    await sync(tablet);

    expect(await tablet.repo.fetchByProfile(_profile('p1')), isEmpty);
  });

  test('an entry of a profile the phone does not have is not written', () async {
    final phone = await _Phone.create(temp, 'phone', 'p1');
    final tablet = await _Phone.create(temp, 'tablet', 'p2');
    addTearDown(phone.db.close);
    addTearDown(tablet.db.close);

    await phone.repo.save(steps(9000, DateTime(2026, 10, 10, 9)));
    await sync(phone);
    await sync(tablet);

    expect(await tablet.repo.findAll(), isEmpty);
  });
}
