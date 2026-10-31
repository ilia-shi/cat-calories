import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_recommendation_service.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_status.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/equalization_settings.dart';
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

  TrackingGap gap(DateTime start, DateTime end, {DateTime? deletedAt}) {
    return TrackingGap(
      id: '$start',
      profileId: 'p1',
      startedAt: start,
      endedAt: end,
      description: null,
      createdAt: start,
      updatedAt: start,
      deletedAt: deletedAt,
    );
  }

  final monday = DateTime(2026, 10, 5);
  final tuesday = DateTime(2026, 10, 6);
  final wednesday = DateTime(2026, 10, 7);

  List<DayStat> stats(
    List<DayResult> days,
    List<TrackingGap> gaps, {
    DateTime? firstRecordDay,
  }) {
    return dayStats(
      days: days,
      gaps: gaps,
      firstRecordDay: firstRecordDay ?? monday,
      from: monday,
      to: wednesday,
    );
  }

  group('dayStats', () {
    test('a logged day without a gap is tracked', () {
      expect(stats([day(monday, 2000)], []).first.status, DayStatus.tracked);
    });

    test('a day without records or a gap is empty and shown', () {
      final result = stats([day(monday, 2000)], []);

      expect(result.map((s) => s.day), [monday, tuesday]);
      expect(result.last.status, DayStatus.empty);
      expect(result.last.kcal, 0);
    });

    test('a 30-minute gap makes a logged day partial', () {
      final result = stats([
        day(monday, 2000),
      ], [
        gap(DateTime(2026, 10, 5, 18), DateTime(2026, 10, 5, 18, 30)),
      ]);

      expect(result.first.status, DayStatus.partial);
    });

    test('a gap on a day without records makes it unknown', () {
      final result = stats([], [gap(tuesday, wednesday)]);

      expect(result.last.status, DayStatus.unknown);
    });

    test('a gap ending exactly at midnight leaves the next day alone', () {
      final result = stats([
        day(tuesday, 2000),
      ], [
        gap(DateTime(2026, 10, 5, 20), tuesday),
      ]);

      expect(result.last.status, DayStatus.tracked);
    });

    test('overlapping gaps act like one', () {
      final one = stats([], [gap(monday, tuesday)]);
      final two = stats([], [
        gap(monday, tuesday),
        gap(DateTime(2026, 10, 5, 2), DateTime(2026, 10, 5, 3)),
      ]);

      expect(two.map((s) => s.status), one.map((s) => s.status));
    });

    test('a deleted gap has no effect', () {
      final result = stats([], [
        gap(monday, wednesday, deletedAt: DateTime(2026, 10, 8)),
      ]);

      expect(result.map((s) => s.status), everyElement(DayStatus.empty));
    });

    test('days before the first record are left out', () {
      final result = stats([day(tuesday, 2000)], [], firstRecordDay: tuesday);

      expect(result.map((s) => s.day), [tuesday]);
    });

    test('no first record means no days', () {
      expect(
        dayStats(
          days: [],
          gaps: [],
          firstRecordDay: null,
          from: monday,
          to: wednesday,
        ),
        isEmpty,
      );
    });

    test('a day containing a clock change appears once', () {
      final result = dayStats(
        days: [],
        gaps: [],
        firstRecordDay: DateTime(2026, 10, 24),
        from: DateTime(2026, 10, 24),
        to: DateTime(2026, 10, 27),
      );

      expect(result.map((s) => s.day.day), [24, 25, 26]);
    });

    test('rows of the same local day are merged', () {
      final result = stats([
        day(monday, 500),
        day(DateTime(2026, 10, 5, 3), 700),
      ], []);

      expect(result.first.kcal, 1200);
    });
  });

  group('displayKcal', () {
    test('shows each status as agreed', () {
      final result = stats([
        day(monday, 950),
      ], [
        gap(DateTime(2026, 10, 5, 18), DateTime(2026, 10, 5, 20)),
        gap(tuesday, wednesday),
      ]);

      expect(result.first.displayKcal, '≥ 950');
      expect(result.last.displayKcal, '—');
      expect(stats([day(monday, 950)], []).first.displayKcal, '950');
      expect(stats([day(monday, 950)], []).last.displayKcal, '0');
    });
  });

  group('trackedDays', () {
    final now = DateTime(2026, 10, 10, 12);
    final yesterday = DateTime(2026, 10, 9);
    final older = day(DateTime(2026, 10, 8), 2000);

    double recommended(List<DayResult> history) {
      return CalorieRecommendationService(
        const EqualizationSettings(baseCalorieGoal: 2000),
      )
          .calculate(historicalDays: history, consumedToday: 0, now: now)
          .recommendedToday;
    }

    test('a partial yesterday does not raise the recommendation', () {
      final history = [day(yesterday, 500), older];
      final gaps = [gap(DateTime(2026, 10, 9, 18), DateTime(2026, 10, 9, 20))];

      expect(recommended(history), greaterThan(recommended([older])));
      expect(recommended(trackedDays(history, gaps)), recommended([older]));
    });

    test('a forgotten yesterday has no row and no effect', () {
      expect(recommended(trackedDays([older], [])), recommended([older]));
    });
  });
}
