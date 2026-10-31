import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/eaten_in_last_24h.dart';
import 'package:test/test.dart';

void main() {
  CalorieRecord record(String id, DateTime? eatenAt) {
    return CalorieRecord(
      id: id,
      value: 300,
      description: null,
      sortOrder: 0,
      eatenAt: eatenAt,
      createdAt: DateTime(2026, 10, 10, 8),
      profileId: 'p1',
      wakingPeriodId: null,
    );
  }

  final now = DateTime(2026, 10, 10, 18);

  List<String?> ids(List<CalorieRecord> records) {
    return eatenInLast24h(records, now).map((r) => r.id).toList();
  }

  test('keeps a record eaten inside the window', () {
    expect(ids([record('a', now.subtract(const Duration(hours: 3)))]), ['a']);
  });

  test('drops a record eaten 30 hours ago', () {
    expect(ids([record('a', now.subtract(const Duration(hours: 30)))]), isEmpty);
  });

  test('the window start itself is outside', () {
    expect(ids([record('a', now.subtract(const Duration(hours: 24)))]), isEmpty);
  });

  test('the current moment itself is inside', () {
    expect(ids([record('a', now)]), ['a']);
  });

  test('a moment later than now is outside', () {
    expect(ids([record('a', now.add(const Duration(minutes: 1)))]), isEmpty);
  });

  test('a record not eaten yet is dropped', () {
    expect(ids([record('a', null)]), isEmpty);
  });
}
