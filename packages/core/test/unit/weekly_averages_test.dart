import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/weekly_averages.dart';
import 'package:test/test.dart';

void main() {
  DayResult day(DateTime date, double kcal) {
    return DayResult(
      valueSum: kcal,
      positiveValueSum: kcal,
      negativeValueSum: 0,
      day: date,
    );
  }

  // Saturday, 2026-10-10. Its week starts on Monday, 2026-10-05.
  final now = DateTime(2026, 10, 10, 18, 30);

  group('weekOf', () {
    test('a Monday is the start of its own week', () {
      expect(weekOf(DateTime(2026, 10, 5, 9)), DateTime(2026, 10, 5));
    });

    test('a Sunday belongs to the week that started six days earlier', () {
      expect(weekOf(DateTime(2026, 10, 11, 23)), DateTime(2026, 10, 5));
    });

    test('a week spanning a month boundary starts in the previous month', () {
      expect(weekOf(DateTime(2026, 10, 1)), DateTime(2026, 9, 28));
    });
  });

  group('weeklyAverages', () {
    List<WeekAverage> averages(
      List<DayResult> days, {
      List<TrackingGap> gaps = const [],
      DateTime? firstRecordDay,
      DateTime? asOf,
      int weeks = 2,
    }) {
      return weeklyAverages(
        days,
        gaps: gaps,
        firstRecordDay: firstRecordDay ?? DateTime(2026, 1, 1),
        now: asOf ?? now,
        weeks: weeks,
      );
    }

    test('returns 8 weeks by default, oldest first, ending with this week', () {
      final result = weeklyAverages(
        [],
        gaps: [],
        firstRecordDay: null,
        now: now,
      );

      expect(result, hasLength(8));
      expect(result.first.weekStart, DateTime(2026, 8, 17));
      expect(result.last.weekStart, DateTime(2026, 10, 5));
    });

    test('a week without history has no data, not 0 kcal', () {
      final result = averages([], firstRecordDay: DateTime(2026, 10, 5));

      expect(result.first.kcalPerDay, isNull);
    });

    test('a finished week counts its empty days as 0 kcal', () {
      final result = averages([
        day(DateTime(2026, 9, 28), 7000),
      ]);

      expect(result.first.kcalPerDay, 1000);
    });

    test('a week in progress is averaged over its finished days', () {
      final result = averages([
        day(DateTime(2026, 10, 12), 2000),
        day(DateTime(2026, 10, 13), 2000),
        day(DateTime(2026, 10, 14), 9000),
      ], asOf: DateTime(2026, 10, 14, 9));

      expect(result.last.kcalPerDay, 2000);
    });

    test('a Monday leaves the new week without data', () {
      final result = averages([
        day(DateTime(2026, 10, 12), 500),
      ], asOf: DateTime(2026, 10, 12, 9));

      expect(result.last.kcalPerDay, isNull);
    });

    test('a week inside a gap has no data', () {
      final result = averages([], gaps: [
        TrackingGap(
          id: 'g',
          profileId: 'p1',
          startedAt: DateTime(2026, 9, 28),
          endedAt: DateTime(2026, 10, 5),
          description: null,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      expect(result.first.kcalPerDay, isNull);
    });

    test('ignores days older than the oldest week shown', () {
      final result = averages([
        day(DateTime(2026, 9, 27), 2000),
      ]);

      expect(result.first.kcalPerDay, 0);
    });
  });
}
