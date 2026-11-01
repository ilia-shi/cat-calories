import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_cell_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_data_builder.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_metric_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:cat_calories_core/features/metrics/domain/metric_cells.dart';
import 'package:flutter/material.dart';

/// One period as the calendar widgets draw it, whatever the content is.
sealed class CalendarItem {
  const CalendarItem();

  DateTime get start;
  CalendarMode get mode;
  String get value;
  List<CalendarBar> get bars;
  bool get showGoalLine;

  /// Food macros to show under the bars.
  CalendarCell? get macros;

  void openDetails(BuildContext context);
}

final class FoodCalendarItem extends CalendarItem {
  final CalendarCell cell;
  final CalendarData data;

  const FoodCalendarItem(this.cell, this.data);

  @override
  DateTime get start => cell.start;

  @override
  CalendarMode get mode => cell.mode;

  @override
  String get value => cell.kcalLabel;

  @override
  List<CalendarBar> get bars => cell.bars(data.goal);

  @override
  bool get showGoalLine => true;

  @override
  CalendarCell get macros => cell;

  @override
  void openDetails(BuildContext context) {
    CalendarCellSheet.show(context, cell, data);
  }
}

final class MetricCalendarItem extends CalendarItem {
  final MetricCell cell;
  final CalendarData data;

  const MetricCalendarItem(this.cell, this.data);

  @override
  DateTime get start => cell.start;

  @override
  CalendarMode get mode => cell.mode;

  @override
  String get value => cell.label;

  @override
  List<CalendarBar> get bars => cell.bars;

  @override
  bool get showGoalLine => false;

  @override
  CalendarCell? get macros => null;

  @override
  void openDetails(BuildContext context) {
    CalendarMetricSheet.show(context, cell, data);
  }
}

/// Oldest first.
List<CalendarItem> calendarItems(
  CalendarData data,
  CalendarMode mode,
  DayMetric? metric,
) {
  if (metric == null) {
    return [for (final cell in data.cells(mode)) FoodCalendarItem(cell, data)];
  }

  return [
    for (final cell in data.metricCellsOf(metric, mode))
      MetricCalendarItem(cell, data),
  ];
}
