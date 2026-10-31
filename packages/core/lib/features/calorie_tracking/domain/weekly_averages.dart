import 'package:cat_calories_core/features/calorie_tracking/domain/average_daily_kcal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_status.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';

final class WeekAverage {
  /// Midnight of the week's Monday.
  final DateTime weekStart;

  /// Null when no day of the week counts, which is not the same as 0 kcal.
  final double? kcalPerDay;

  const WeekAverage({required this.weekStart, required this.kcalPerDay});
}

/// Midnight of the Monday of [moment]'s week.
DateTime weekOf(DateTime moment) {
  // Built from calendar fields, not by subtracting a Duration, so a DST switch
  // inside the week cannot shift the result off midnight.
  return DateTime(moment.year, moment.month, moment.day - (moment.weekday - 1));
}

/// Average kcal per day of the Monday-to-Sunday weeks ending with the week of
/// [now], oldest first. An average over counted days stays comparable between
/// finished weeks, the week in progress and weeks with gaps, which a weekly
/// total is not. Today is left out because it is unfinished.
List<WeekAverage> weeklyAverages(
  List<DayResult> days, {
  required List<TrackingGap> gaps,
  required DateTime? firstRecordDay,
  required DateTime now,
  int weeks = 8,
}) {
  final current = weekOf(now);
  final starts = [
    for (var i = weeks - 1; i >= 0; i--)
      DateTime(current.year, current.month, current.day - 7 * i),
  ];
  final byWeek = {for (final start in starts) start: <DayStat>[]};

  final stats = dayStats(
    days: days,
    gaps: gaps,
    firstRecordDay: firstRecordDay,
    from: starts.first,
    to: dayOf(now),
  );
  for (final stat in stats) {
    byWeek[weekOf(stat.day)]?.add(stat);
  }

  return [
    for (final start in starts)
      WeekAverage(
        weekStart: start,
        kcalPerDay: averageOfCountedDays(byWeek[start]!),
      ),
  ];
}
