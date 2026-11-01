import 'package:cat_calories_core/features/calorie_tracking/domain/average_daily_kcal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_nutrition.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_status.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';

enum CalendarMode { days, weeks, months }

final class CalendarDay {
  final DateTime day;

  /// Null for a day outside the logged history: before the first record, or
  /// one that has not come yet ([isFuture]).
  final DayStatus? status;
  final double kcal;
  final bool isToday;
  final bool isFuture;

  const CalendarDay({
    required this.day,
    required this.status,
    required this.kcal,
    required this.isToday,
    required this.isFuture,
  });
}

final class CalendarCell {
  final DateTime start;

  /// Exclusive.
  final DateTime end;
  final CalendarMode mode;
  final List<CalendarDay> days;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final bool hasGap;
  final int recordCount;
  final int recordsWithMacros;

  /// Follows `7-Day Avg`, so it leaves out today, `partial` and `unknown` days
  /// although [kcal] covers all of them. Null when no day counts.
  final double? averageKcal;
  final int countedDays;

  const CalendarCell({
    required this.start,
    required this.end,
    required this.mode,
    required this.days,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.hasGap,
    required this.recordCount,
    required this.recordsWithMacros,
    required this.averageKcal,
    required this.countedDays,
  });

  String get kcalLabel {
    if (mode == CalendarMode.days &&
        days.single.status == DayStatus.unknown) {
      return '—';
    }

    return '${hasGap ? '≥ ' : ''}${formatAmount(kcal, mode)}';
  }

  String macroLabel(double grams) {
    if (recordsWithMacros == 0) {
      return '—';
    }

    return '${recordsWithMacros < recordCount ? '≥ ' : ''}'
        '${formatAmount(grams, mode)}';
  }

  List<CalendarBar> bars(double goal) {
    return [for (final day in days) calendarBar(day, goal)];
  }

  /// The cell's period as a gap's bounds: a gap cannot end in the future.
  (DateTime, DateTime) gapBounds(DateTime now) {
    return (start, end.isAfter(now) ? now : end);
  }
}

/// No decimals, except that weeks and months shorten thousands: 45320 is 45.3K.
String formatAmount(double value, CalendarMode mode) {
  if (mode == CalendarMode.days || value.abs() < 1000) {
    return '${value.round()}';
  }

  final thousands = (value / 1000).toStringAsFixed(1);

  return '${thousands.endsWith('.0') ? thousands.substring(0, thousands.length - 2) : thousands}K';
}

enum CalendarBarKind { blank, future, emptySlot, normal, today, muted, over }

final class CalendarBar {
  final CalendarBarKind kind;

  /// Share of the full height, from 0 to 1.
  final double height;

  const CalendarBar(this.kind, this.height);
}

/// The goal sits at half height in every cell, so bars of any two cells compare
/// directly. A scale taken from the largest day would let one 6000 kcal day
/// flatten the whole history.
CalendarBar calendarBar(CalendarDay day, double goal) {
  if (day.isFuture) {
    return const CalendarBar(CalendarBarKind.future, 0);
  }

  final status = day.status;
  if (status == null) {
    return const CalendarBar(CalendarBarKind.blank, 0);
  }
  if (status == DayStatus.unknown) {
    return const CalendarBar(CalendarBarKind.muted, 1);
  }

  final full = goal * 2;
  final height = full > 0 ? (day.kcal / full).clamp(0.0, 1.0) : 0.0;

  if (full > 0 && day.kcal > full) {
    return CalendarBar(CalendarBarKind.over, height);
  }
  if (day.isToday) {
    return CalendarBar(CalendarBarKind.today, height);
  }

  return switch (status) {
    DayStatus.partial => CalendarBar(CalendarBarKind.muted, height),
    DayStatus.empty => const CalendarBar(CalendarBarKind.emptySlot, 0),
    _ => CalendarBar(CalendarBarKind.normal, height),
  };
}

DateTime periodStart(DateTime day, CalendarMode mode) {
  return switch (mode) {
    CalendarMode.days => dayOf(day),
    CalendarMode.weeks => weekOf(day),
    CalendarMode.months => DateTime(day.year, day.month),
  };
}

DateTime nextPeriod(DateTime start, CalendarMode mode) {
  return switch (mode) {
    CalendarMode.days => nextDay(start),
    CalendarMode.weeks => DateTime(start.year, start.month, start.day + 7),
    CalendarMode.months => DateTime(start.year, start.month + 1),
  };
}

/// One cell per period from the earliest record's period up to the one holding
/// [now], oldest first, including periods without records.
List<CalendarCell> calendarCells({
  required List<DayNutrition> nutrition,
  required List<TrackingGap> gaps,
  required CalendarMode mode,
  required DateTime now,
}) {
  if (nutrition.isEmpty) {
    return const [];
  }

  final byDay = <DateTime, DayNutrition>{};
  for (final item in nutrition) {
    final key = dayOf(item.day);
    byDay[key] = byDay[key]?.plus(item) ?? item;
  }

  final today = dayOf(now);
  final first = byDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  final stats = {
    for (final stat in dayStats(
      days: [
        for (final entry in byDay.entries)
          DayResult(
            valueSum: entry.value.kcal,
            positiveValueSum: 0,
            negativeValueSum: 0,
            day: entry.key,
          ),
      ],
      gaps: gaps,
      firstRecordDay: first,
      from: first,
      to: nextDay(today),
    ))
      stat.day: stat,
  };

  final cells = <CalendarCell>[];
  for (var start = periodStart(first, mode);
      !start.isAfter(today);
      start = nextPeriod(start, mode)) {
    final end = nextPeriod(start, mode);
    final days = <CalendarDay>[];
    final finished = <DayStat>[];
    var kcal = 0.0, protein = 0.0, fat = 0.0, carbs = 0.0;
    var recordCount = 0, recordsWithMacros = 0;

    for (var day = start; day.isBefore(end); day = nextDay(day)) {
      final stat = stats[day];
      final item = byDay[day];

      days.add(CalendarDay(
        day: day,
        status: stat?.status,
        kcal: item?.kcal ?? 0,
        isToday: day == today,
        isFuture: day.isAfter(today),
      ));
      if (stat != null && day.isBefore(today)) {
        finished.add(stat);
      }
      if (item != null) {
        kcal += item.kcal;
        protein += item.protein;
        fat += item.fat;
        carbs += item.carbs;
        recordCount += item.recordCount;
        recordsWithMacros += item.recordsWithMacros;
      }
    }

    cells.add(CalendarCell(
      start: start,
      end: end,
      mode: mode,
      days: days,
      kcal: kcal,
      protein: protein,
      fat: fat,
      carbs: carbs,
      hasGap: gapOverlaps(gaps, start, end),
      recordCount: recordCount,
      recordsWithMacros: recordsWithMacros,
      averageKcal: averageOfCountedDays(finished),
      countedDays: finished.where((stat) => stat.status.isCounted).length,
    ));
  }

  return cells;
}
