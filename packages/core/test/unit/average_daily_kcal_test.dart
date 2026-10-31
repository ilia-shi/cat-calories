import 'package:cat_calories_core/features/calorie_tracking/domain/average_daily_kcal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
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

  final now = DateTime(2026, 10, 10, 18, 30);
  final olderHistory = day(DateTime(2026, 9, 20), 1800);

  group('averageDailyKcal', () {
    test('no days gives 0', () {
      expect(averageDailyKcal([], now: now), 0);
    });

    test('only today gives 0', () {
      expect(averageDailyKcal([day(DateTime(2026, 10, 10), 900)], now: now), 0);
    });

    test('includes both the seventh day back and yesterday', () {
      final result = averageDailyKcal([
        day(DateTime(2026, 10, 3), 1400),
        day(DateTime(2026, 10, 9), 1400),
        olderHistory,
      ], now: now);

      expect(result, 400);
    });

    test('ignores the eighth day back', () {
      final result = averageDailyKcal([
        day(DateTime(2026, 10, 2), 7000),
        day(DateTime(2026, 10, 9), 700),
      ], now: now);

      expect(result, 100);
    });

    test('a skipped day counts as 0 kcal', () {
      final result = averageDailyKcal([
        day(DateTime(2026, 10, 6), 2000),
        day(DateTime(2026, 10, 7), 2000),
        day(DateTime(2026, 10, 8), 2000),
        day(DateTime(2026, 10, 9), 2000),
        olderHistory,
      ], now: now);

      expect(result.round(), 1143);
    });

    test('a short history is averaged over its own length', () {
      final result = averageDailyKcal([
        day(DateTime(2026, 10, 7), 2000),
        day(DateTime(2026, 10, 8), 2000),
        day(DateTime(2026, 10, 9), 2000),
      ], now: now);

      expect(result, 2000);
    });

    test('today does not change the result', () {
      final past = [day(DateTime(2026, 10, 9), 2000), olderHistory];

      expect(
        averageDailyKcal([...past, day(DateTime(2026, 10, 10), 5000)], now: now),
        averageDailyKcal(past, now: now),
      );
    });

    test('a window over the spring and autumn clock changes still has 7 days',
        () {
      // Both dates fall on a DST switch in the EU and are ordinary days in UTC;
      // the expectations hold in any time zone the tests run in.
      for (final switchDay in [DateTime(2026, 3, 29), DateTime(2026, 10, 25)]) {
        final today = DateTime(switchDay.year, switchDay.month, switchDay.day + 3);
        final result = averageDailyKcal([
          day(DateTime(today.year, today.month, today.day - 7), 700),
          day(DateTime(today.year, today.month, today.day - 8), 700),
        ], now: today);

        expect(result, 100);
      }
    });
  });
}
