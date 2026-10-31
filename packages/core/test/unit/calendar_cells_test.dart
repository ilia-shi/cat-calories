import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_nutrition.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_status.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:test/test.dart';

void main() {
  DayNutrition item(
    DateTime day,
    double kcal, {
    double protein = 0,
    int records = 1,
    int withMacros = 0,
  }) =>
      DayNutrition(
        day: day,
        kcal: kcal,
        protein: protein,
        fat: 0,
        carbs: 0,
        recordCount: records,
        recordsWithMacros: withMacros,
      );

  TrackingGap gap(DateTime start, DateTime end, {DateTime? deletedAt}) =>
      TrackingGap(
        id: '$start',
        profileId: 'p1',
        startedAt: start,
        endedAt: end,
        description: null,
        createdAt: start,
        updatedAt: start,
        deletedAt: deletedAt,
      );

  // Wednesday. The week starts on Monday, 2026-10-26.
  final now = DateTime(2026, 10, 28, 12);

  List<CalendarCell> cells(
    List<DayNutrition> nutrition,
    CalendarMode mode, {
    List<TrackingGap> gaps = const [],
    DateTime? asOf,
  }) {
    return calendarCells(
      nutrition: nutrition,
      gaps: gaps,
      mode: mode,
      now: asOf ?? now,
    );
  }

  final finishedWeek = [
    for (final (i, kcal) in [2510, 2400, 2200, 3400, 2500, 2500, 2200].indexed)
      item(DateTime(2026, 10, 19 + i), kcal.toDouble()),
  ];

  group('calendarCells', () {
    test('no records means no cells', () {
      expect(cells([], CalendarMode.weeks), isEmpty);
    });

    test('a month without records still has a cell', () {
      final result = cells([
        item(DateTime(2026, 8, 10), 2000),
        item(DateTime(2026, 10, 10), 2000),
      ], CalendarMode.months);

      expect(result.map((c) => c.start.month), [8, 9, 10]);
      expect(result[1].kcal, 0);
    });

    test('month cells have one day per day of the month', () {
      final result = cells([
        item(DateTime(2026, 2, 10), 2000),
      ], CalendarMode.months);

      expect(result.first.days, hasLength(28));
    });

    test('a finished week sums all its days', () {
      final week = cells(finishedWeek, CalendarMode.weeks).first;

      expect(week.start, DateTime(2026, 10, 19));
      expect(week.days, hasLength(7));
      expect(week.kcal, 17710);
      expect(week.kcalLabel, '17.7K');
    });

    test('the week in progress has past days, today and future days', () {
      final week = cells([
        item(DateTime(2026, 10, 19), 2000),
        item(DateTime(2026, 10, 26), 3000),
        item(DateTime(2026, 10, 28), 1250),
      ], CalendarMode.weeks).last;

      expect(week.kcal, 4250);
      expect(week.days[1].status, DayStatus.empty);
      expect(week.days[2].isToday, isTrue);
      expect(week.days.skip(3).every((d) => d.isFuture), isTrue);
    });

    test('days before the first record have no status', () {
      final week = cells([
        item(DateTime(2026, 10, 28), 1250),
      ], CalendarMode.weeks).single;

      expect(week.days.first.status, isNull);
      expect(week.days.first.isFuture, isFalse);
    });

    test('a week holding a clock change still has 7 days', () {
      final week = cells([
        item(DateTime(2026, 10, 19), 2000),
      ], CalendarMode.weeks, asOf: DateTime(2026, 10, 27)).first;

      expect(week.days.map((d) => d.day.day), [19, 20, 21, 22, 23, 24, 25]);
    });

    test('rows of the same local day are merged', () {
      final result = cells([
        item(DateTime(2026, 10, 27), 500),
        item(DateTime(2026, 10, 27, 3), 700),
      ], CalendarMode.days);

      expect(result.first.kcal, 1200);
    });
  });

  group('average', () {
    test('a week with a gap averages only its counted days', () {
      final nutrition = [
        for (var day = 19; day <= 23; day++)
          item(DateTime(2026, 10, day), 1867),
        item(DateTime(2026, 10, 24), 400),
      ];
      final week = cells(nutrition, CalendarMode.weeks, gaps: [
        gap(DateTime(2026, 10, 24, 18), DateTime(2026, 10, 26)),
      ]).first;

      expect(week.averageKcal, 1867);
      expect(week.countedDays, 5);
      expect(week.kcal, 9735);
      expect(week.kcalLabel, '≥ 9.7K');
    });

    test('today is in the sum but not in the average', () {
      final week = cells([
        item(DateTime(2026, 10, 26), 2000),
        item(DateTime(2026, 10, 27), 2000),
        item(DateTime(2026, 10, 28), 5000),
      ], CalendarMode.weeks).last;

      expect(week.kcal, 9000);
      expect(week.averageKcal, 2000);
      expect(week.countedDays, 2);
    });

    test('a period where no day counts has no average', () {
      final day = cells([
        item(DateTime(2026, 10, 28), 500),
      ], CalendarMode.days).single;

      expect(day.averageKcal, isNull);
    });
  });

  group('labels', () {
    test('an unknown day shows a dash', () {
      final result = cells([
        item(DateTime(2026, 10, 26), 2000),
      ], CalendarMode.days, gaps: [
        gap(DateTime(2026, 10, 27), DateTime(2026, 10, 28)),
      ]);

      expect(result[1].kcalLabel, '—');
    });

    test('an empty day shows 0', () {
      final result = cells([
        item(DateTime(2026, 10, 26), 2000),
      ], CalendarMode.days);

      expect(result[1].kcalLabel, '0');
    });

    test('a deleted gap has no effect', () {
      final result = cells([
        item(DateTime(2026, 10, 26), 2000),
      ], CalendarMode.days, gaps: [
        gap(DateTime(2026, 10, 26), DateTime(2026, 10, 27), deletedAt: now),
      ]);

      expect(result.first.kcalLabel, '2000');
    });

    test('macros from only some records are a lower bound', () {
      final day = cells([
        item(DateTime(2026, 10, 28), 500,
            protein: 96, records: 2, withMacros: 1),
      ], CalendarMode.days).single;

      expect(day.macroLabel(day.protein), '≥ 96');
    });

    test('macros from every record are exact', () {
      final day = cells([
        item(DateTime(2026, 10, 28), 500,
            protein: 96, records: 2, withMacros: 2),
      ], CalendarMode.days).single;

      expect(day.macroLabel(day.protein), '96');
    });

    test('no macro data shows a dash', () {
      final day = cells([
        item(DateTime(2026, 10, 28), 500),
      ], CalendarMode.days).single;

      expect(day.macroLabel(day.protein), '—');
    });
  });

  group('formatAmount', () {
    test('shortens a large value in weeks and months', () {
      expect(formatAmount(45320, CalendarMode.weeks), '45.3K');
      expect(formatAmount(45320, CalendarMode.months), '45.3K');
    });

    test('drops .0 from whole thousands', () {
      expect(formatAmount(45000, CalendarMode.months), '45K');
    });

    test('rounds below a thousand to a whole number', () {
      expect(formatAmount(785.4, CalendarMode.weeks), '785');
    });

    test('day mode is always a whole number', () {
      expect(formatAmount(1873.46, CalendarMode.days), '1873');
    });

    test('a negative sum keeps its sign', () {
      expect(formatAmount(-1200, CalendarMode.weeks), '-1.2K');
    });
  });

  group('calendarBar', () {
    CalendarDay day(
      DayStatus? status, {
      double kcal = 0,
      bool isToday = false,
      bool isFuture = false,
    }) =>
        CalendarDay(
          day: now,
          status: status,
          kcal: kcal,
          isToday: isToday,
          isFuture: isFuture,
        );

    test('a tracked day is scaled to twice the goal', () {
      final bar = calendarBar(day(DayStatus.tracked, kcal: 1000), 2000);

      expect(bar.kind, CalendarBarKind.normal);
      expect(bar.height, 0.25);
    });

    test('a day at the goal reaches half height', () {
      expect(calendarBar(day(DayStatus.tracked, kcal: 2000), 2000).height, 0.5);
    });

    test('a day above twice the goal is clipped and marked', () {
      final bar = calendarBar(day(DayStatus.tracked, kcal: 5000), 2000);

      expect(bar.kind, CalendarBarKind.over);
      expect(bar.height, 1);
    });

    test('today is its own kind', () {
      final bar = calendarBar(
          day(DayStatus.tracked, kcal: 1000, isToday: true), 2000);

      expect(bar.kind, CalendarBarKind.today);
    });

    test('a past empty day is a slot, today with no records is not', () {
      expect(calendarBar(day(DayStatus.empty), 2000).kind,
          CalendarBarKind.emptySlot);
      expect(calendarBar(day(DayStatus.empty, isToday: true), 2000).kind,
          CalendarBarKind.today);
    });

    test('a partial day is muted at its kcal', () {
      final bar = calendarBar(day(DayStatus.partial, kcal: 1000), 2000);

      expect(bar.kind, CalendarBarKind.muted);
      expect(bar.height, 0.25);
    });

    test('an unknown day is muted at full height', () {
      final bar = calendarBar(day(DayStatus.unknown), 2000);

      expect(bar.kind, CalendarBarKind.muted);
      expect(bar.height, 1);
    });

    test('a future day and a day before history differ', () {
      expect(calendarBar(day(null, isFuture: true), 2000).kind,
          CalendarBarKind.future);
      expect(calendarBar(day(null), 2000).kind, CalendarBarKind.blank);
    });

    test('a negative day has no height', () {
      expect(calendarBar(day(DayStatus.tracked, kcal: -300), 2000).height, 0);
    });
  });

  test('gapBounds cuts the current period at now', () {
    final week = cells([
      item(DateTime(2026, 10, 26), 2000),
    ], CalendarMode.weeks).single;

    expect(week.gapBounds(now), (DateTime(2026, 10, 26), now));
  });
}
