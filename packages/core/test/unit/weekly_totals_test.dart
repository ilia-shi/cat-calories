import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/weekly_totals.dart';
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

  group('weeklyTotals', () {
    test('returns 8 weeks by default, oldest first, ending with this week', () {
      final result = weeklyTotals([], now: now);

      expect(result, hasLength(8));
      expect(result.first.weekStart, DateTime(2026, 8, 17));
      expect(result.last.weekStart, DateTime(2026, 10, 5));
    });

    test('a week with no days is reported as 0 kcal', () {
      final result = weeklyTotals([], now: now, weeks: 2);

      expect(result.map((w) => w.kcal), [0, 0]);
    });

    test('sums the days of each week into that week', () {
      final result = weeklyTotals([
        day(DateTime(2026, 10, 5), 2000),
        day(DateTime(2026, 10, 10), 1500),
        day(DateTime(2026, 10, 4), 1800),
        day(DateTime(2026, 9, 28), 1200),
      ], now: now, weeks: 2);

      expect(result.map((w) => w.kcal), [3000, 3500]);
    });

    test('ignores days older than the oldest week shown', () {
      final result = weeklyTotals([
        day(DateTime(2026, 9, 27), 2000),
      ], now: now, weeks: 2);

      expect(result.map((w) => w.kcal), [0, 0]);
    });
  });
}
