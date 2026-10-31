import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:intl/intl.dart';

String shortPeriodLabel(CalendarCell cell) {
  return switch (cell.mode) {
    CalendarMode.days => DateFormat('EEE d').format(cell.start),
    CalendarMode.weeks => DateFormat('d MMM').format(cell.start),
    CalendarMode.months => DateFormat('MMM y').format(cell.start),
  };
}

String fullPeriodLabel(CalendarCell cell) {
  final last = DateTime(cell.end.year, cell.end.month, cell.end.day - 1);

  return switch (cell.mode) {
    CalendarMode.days => DateFormat('EEEE, MMM d, y').format(cell.start),
    CalendarMode.weeks =>
      '${DateFormat('MMM d').format(cell.start)} – ${DateFormat('MMM d, y').format(last)}',
    CalendarMode.months => DateFormat('MMMM y').format(cell.start),
  };
}

String calendarModeLabel(CalendarMode mode) {
  return switch (mode) {
    CalendarMode.days => 'Days',
    CalendarMode.weeks => 'Weeks',
    CalendarMode.months => 'Months',
  };
}
