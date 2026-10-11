import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';

final class WeekTotal {
  /// Midnight of the week's Monday.
  final DateTime weekStart;
  final double kcal;

  const WeekTotal({required this.weekStart, required this.kcal});
}

/// Midnight of the Monday of [moment]'s week.
DateTime weekOf(DateTime moment) {
  // Built from calendar fields, not by subtracting a Duration, so a DST
  // switch inside the week cannot shift the result off midnight.
  return DateTime(moment.year, moment.month, moment.day - (moment.weekday - 1));
}

/// Calories per Monday-to-Sunday week for the [weeks] weeks ending with the
/// week of [now], oldest first. The current week is included while still in
/// progress, and a week with no days in [days] is reported as 0.
List<WeekTotal> weeklyTotals(
  List<DayResult> days, {
  required DateTime now,
  int weeks = 8,
}) {
  final current = weekOf(now);
  final starts = [
    for (var i = weeks - 1; i >= 0; i--)
      DateTime(current.year, current.month, current.day - 7 * i),
  ];
  final sums = {for (final start in starts) start: 0.0};

  for (final day in days) {
    final start = weekOf(dayOf(day.day));
    final sum = sums[start];
    if (sum != null) {
      sums[start] = sum + day.valueSum;
    }
  }

  return [
    for (final start in starts) WeekTotal(weekStart: start, kcal: sums[start]!),
  ];
}
