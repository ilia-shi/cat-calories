import 'package:cat_calories_core/features/calorie_tracking/domain/average_daily_kcal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
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

  TrackingGap gap(DateTime start, DateTime end) {
    return TrackingGap(
      id: 'g',
      profileId: 'p1',
      startedAt: start,
      endedAt: end,
      description: null,
      createdAt: start,
      updatedAt: start,
    );
  }

  final now = DateTime(2026, 10, 10, 18, 30);
  final oldHistory = DateTime(2026, 9, 20);

  double average(
    List<DayResult> days, {
    List<TrackingGap> gaps = const [],
    DateTime? firstRecordDay,
    DateTime? asOf,
  }) {
    return averageDailyKcal(
      days,
      gaps: gaps,
      firstRecordDay: firstRecordDay ?? oldHistory,
      now: asOf ?? now,
    );
  }

  final mixedWeek = [
    day(DateTime(2026, 10, 3), 2000),
    day(DateTime(2026, 10, 4), 2000),
    day(DateTime(2026, 10, 5), 2000),
    day(DateTime(2026, 10, 6), 2000),
  ];
  final twoUnknownDays = gap(DateTime(2026, 10, 7), DateTime(2026, 10, 9));

  group('averageDailyKcal', () {
    test('no history gives 0', () {
      expect(
        averageDailyKcal([], gaps: [], firstRecordDay: null, now: now),
        0,
      );
    });

    test('a history that starts today gives 0', () {
      final result = average(
        [day(DateTime(2026, 10, 10), 900)],
        firstRecordDay: DateTime(2026, 10, 10),
      );

      expect(result, 0);
    });

    test('includes both the seventh day back and yesterday', () {
      final result = average([
        day(DateTime(2026, 10, 3), 1400),
        day(DateTime(2026, 10, 9), 1400),
      ]);

      expect(result, 400);
    });

    test('ignores the eighth day back', () {
      final result = average([
        day(DateTime(2026, 10, 2), 7000),
        day(DateTime(2026, 10, 9), 700),
      ]);

      expect(result, 100);
    });

    test('an empty day counts as 0 kcal', () {
      expect(average(mixedWeek.sublist(0, 4)).round(), 1143);
    });

    test('a mixed week skips only the unknown days', () {
      expect(average(mixedWeek, gaps: [twoUnknownDays]), 1600);
    });

    test('marking the empty day as a gap removes it from the average', () {
      final result = average(mixedWeek, gaps: [
        twoUnknownDays,
        gap(DateTime(2026, 10, 9), DateTime(2026, 10, 10)),
      ]);

      expect(result, 2000);
    });

    test('a partial day leaves out both its calories and the day', () {
      final result = average([
        ...mixedWeek,
        day(DateTime(2026, 10, 7), 500),
      ], gaps: [
        twoUnknownDays,
        gap(DateTime(2026, 10, 9), DateTime(2026, 10, 10)),
      ]);

      expect(result, 2000);
    });

    test('a short history is averaged over its own length', () {
      final result = average([
        day(DateTime(2026, 10, 7), 2000),
        day(DateTime(2026, 10, 8), 2000),
        day(DateTime(2026, 10, 9), 2000),
      ], firstRecordDay: DateTime(2026, 10, 7));

      expect(result, 2000);
    });

    test('today does not change the result', () {
      final past = [day(DateTime(2026, 10, 9), 2000)];

      expect(
        average([...past, day(DateTime(2026, 10, 10), 5000)]),
        average(past),
      );
    });

    test('a window over the spring and autumn clock changes still has 7 days',
        () {
      // Both dates fall on a DST switch in the EU and are ordinary days in UTC;
      // the expectations hold in any time zone the tests run in.
      for (final switchDay in [DateTime(2026, 3, 29), DateTime(2026, 10, 25)]) {
        final today =
            DateTime(switchDay.year, switchDay.month, switchDay.day + 3);
        final result = average(
          [
            day(DateTime(today.year, today.month, today.day - 7), 700),
            day(DateTime(today.year, today.month, today.day - 8), 700),
          ],
          firstRecordDay: DateTime(2025, 1, 1),
          asOf: today,
        );

        expect(result, 100);
      }
    });
  });
}
