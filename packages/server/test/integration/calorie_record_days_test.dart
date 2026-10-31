import 'dart:io';

import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_server/data/sqlite/calorie_record_repository.dart';
import 'package:cat_calories_server/data/sqlite/database.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late Database db;

  final createdAt = DateTime(2026, 10, 1);
  final profile = Profile(
    id: 'p1',
    name: 'Test',
    wakingTimeSeconds: 57600,
    caloriesLimitGoal: 2000,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  void insert(String id, int? recordDay) {
    final at = createdAt.millisecondsSinceEpoch;
    db.execute(
      'INSERT INTO calorie_items '
      '(id, profile_id, value, record_day, eaten_at, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, 'p1', 500.0, recordDay, at, at, at],
    );
  }

  setUp(() {
    directory = Directory.systemTemp.createTempSync('calorie_record_days');
    db = openDatabase('${directory.path}/test.db');
  });

  tearDown(() {
    db.dispose();
    directory.deleteSync(recursive: true);
  });

  test('a row without record_day does not break the day query', () async {
    final day = DateTime(2026, 10, 1).millisecondsSinceEpoch ~/ 100000;
    insert('with-day', day);
    insert('without-day', null);

    final days =
        await ServerCalorieRecordRepository(db).fetchDaysByProfile(profile, 30);

    expect(days, hasLength(1));
    expect(days.single.day, DateTime(2026, 10, 1));
    expect(days.single.valueSum, 500);
  });
}
