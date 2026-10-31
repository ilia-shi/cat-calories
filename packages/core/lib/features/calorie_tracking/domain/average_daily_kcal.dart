import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';

/// Average kcal per day over the [windowDays] calendar days before [now]'s day.
/// Today is left out because it is unfinished, and a day missing from [days]
/// counts as 0 kcal.
///
/// The earliest past day in [days] is taken as the start of the history, so
/// callers must pass enough rows to reach back past the window: a new user with
/// 3 days of history is averaged over 3 days, not [windowDays].
double averageDailyKcal(
  List<DayResult> days, {
  required DateTime now,
  int windowDays = 7,
}) {
  final today = dayOf(now);
  final pastDays = [
    for (final result in days)
      if (dayOf(result.day).isBefore(today)) result,
  ];

  if (pastDays.isEmpty) {
    return 0;
  }

  final earliest = pastDays
      .map((result) => dayOf(result.day))
      .reduce((a, b) => a.isBefore(b) ? a : b);
  // Built from calendar fields, not by subtracting a Duration, so a DST switch
  // inside the window cannot shift the boundary off midnight.
  final windowStart = DateTime(today.year, today.month, today.day - windowDays);
  final start = earliest.isAfter(windowStart) ? earliest : windowStart;

  final sum = pastDays
      .where((result) => !dayOf(result.day).isBefore(start))
      .fold<double>(0, (total, result) => total + result.valueSum);

  return sum / _calendarDaysBetween(start, today);
}

/// Compared in UTC because a local day containing a DST switch is 23 or 25
/// hours long, which `Duration.inDays` would miscount.
int _calendarDaysBetween(DateTime from, DateTime to) {
  final utcFrom = DateTime.utc(from.year, from.month, from.day);
  final utcTo = DateTime.utc(to.year, to.month, to.day);

  return utcTo.difference(utcFrom).inDays;
}
