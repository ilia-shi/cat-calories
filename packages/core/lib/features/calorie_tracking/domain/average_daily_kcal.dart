import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_status.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';

/// Average kcal per counted day, or null when no day counts.
double? averageOfCountedDays(Iterable<DayStat> stats) {
  final counted = stats.where((stat) => stat.status.isCounted).toList();
  if (counted.isEmpty) {
    return null;
  }

  return counted.fold<double>(0, (sum, stat) => sum + stat.kcal) /
      counted.length;
}

/// Average kcal per day over the [windowDays] calendar days before [now]'s day.
/// Today is left out because it is unfinished; see [DayStatus.isCounted] for
/// which days count. [days] must reach back past the window.
double averageDailyKcal(
  List<DayResult> days, {
  required List<TrackingGap> gaps,
  required DateTime? firstRecordDay,
  required DateTime now,
  int windowDays = 7,
}) {
  final today = dayOf(now);
  final stats = dayStats(
    days: days,
    gaps: gaps,
    firstRecordDay: firstRecordDay,
    // Built from calendar fields, not by subtracting a Duration, so a DST
    // switch inside the window cannot shift the boundary off midnight.
    from: DateTime(today.year, today.month, today.day - windowDays),
    to: today,
  );

  return averageOfCountedDays(stats) ?? 0;
}
