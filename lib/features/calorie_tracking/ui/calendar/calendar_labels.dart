import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:intl/intl.dart';

String shortPeriodLabel(DateTime start, CalendarMode mode) {
  return switch (mode) {
    CalendarMode.days => DateFormat('EEE d').format(start),
    CalendarMode.weeks => DateFormat('d MMM').format(start),
    CalendarMode.months => DateFormat('MMM y').format(start),
  };
}

String fullPeriodLabel(DateTime start, DateTime end, CalendarMode mode) {
  final last = DateTime(end.year, end.month, end.day - 1);

  return switch (mode) {
    CalendarMode.days => DateFormat('EEEE, MMM d, y').format(start),
    CalendarMode.weeks =>
      '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, y').format(last)}',
    CalendarMode.months => DateFormat('MMMM y').format(start),
  };
}

String calendarContentLabel(DayMetric? metric) => metric?.title ?? 'Food';

String calendarModeLabel(CalendarMode mode) {
  return switch (mode) {
    CalendarMode.days => 'Days',
    CalendarMode.weeks => 'Weeks',
    CalendarMode.months => 'Months',
  };
}
