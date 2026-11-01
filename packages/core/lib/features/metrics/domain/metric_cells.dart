import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_status.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';

final class MetricDay {
  final DateTime day;

  /// Null when unknown. A saved 0 is a value.
  final double? value;
  final String? note;
  final bool isToday;
  final bool isFuture;

  const MetricDay({
    required this.day,
    required this.value,
    required this.note,
    required this.isToday,
    required this.isFuture,
  });
}

final class MetricCell {
  final DayMetric metric;
  final DateTime start;

  /// Exclusive.
  final DateTime end;
  final CalendarMode mode;
  final List<MetricDay> days;

  /// By [DayMetric.aggregation] over days with a value. Null when there are none.
  final double? value;

  /// Null when no day counts. For a summed metric it leaves out today, which is
  /// unfinished, although [value] includes it.
  final double? average;
  final int countedDays;

  const MetricCell({
    required this.metric,
    required this.start,
    required this.end,
    required this.mode,
    required this.days,
    required this.value,
    required this.average,
    required this.countedDays,
  });

  String get label {
    final current = value;
    if (current == null) {
      return '—';
    }

    return metric == DayMetric.sleepMinutes
        ? DayMetric.compactSleep(current)
        : formatAmount(current, mode);
  }

  /// The value with its unit, for the details of a cell.
  String get detailLabel {
    final current = value;
    if (current == null) {
      return '—';
    }
    if (mode == CalendarMode.days) {
      return metric.format(current);
    }

    final parts = <String>[];
    final average = this.average;
    if (metric.aggregation == MetricAggregation.sum) {
      parts.add(metric == DayMetric.burnedKcal ? '$label kcal' : label);
      if (average != null) {
        parts.add('${average.round()} per day');
      }
      if (countedDays > 0) {
        parts.add('$countedDays of ${days.length} days');
      }
    } else {
      parts.add('${metric.format(current)} per night');
      parts.add('$countedDays of ${days.length} nights');
    }

    return parts.join(', ');
  }

  List<CalendarBar> get bars => [
        for (final day in days) metricBar(day, metric),
      ];
}

CalendarBar metricBar(MetricDay day, DayMetric metric) {
  if (day.isFuture) {
    return const CalendarBar(CalendarBarKind.future, 0);
  }

  final value = day.value;
  if (value == null) {
    return const CalendarBar(CalendarBarKind.blank, 0);
  }

  final height = (value / metric.barFull).clamp(0.0, 1.0);

  return CalendarBar(
    day.isToday ? CalendarBarKind.today : CalendarBarKind.normal,
    height,
  );
}

Map<DateTime, DayMetricEntry> _byDay(
  List<DayMetricEntry> entries,
  DayMetric metric,
) {
  return {
    for (final entry in entries)
      if (!entry.isDeleted && entry.metricKey == metric.key)
        dayFromMetricKey(entry.day): entry,
  };
}

/// One cell per period from the metric's earliest value up to the period holding
/// [now], oldest first, including periods without values.
List<MetricCell> metricCells({
  required List<DayMetricEntry> entries,
  required DayMetric metric,
  required CalendarMode mode,
  required DateTime now,
}) {
  final byDay = _byDay(entries, metric);
  if (byDay.isEmpty) {
    return const [];
  }

  final today = dayOf(now);
  final first = byDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);

  return [
    for (var start = periodStart(first, mode);
        !start.isAfter(today);
        start = nextPeriod(start, mode))
      _cell(byDay, metric, start, mode, today),
  ];
}

/// The cell of [metric] for the period starting at [start].
MetricCell metricCellFor({
  required List<DayMetricEntry> entries,
  required DayMetric metric,
  required DateTime start,
  required CalendarMode mode,
  required DateTime now,
}) {
  return _cell(_byDay(entries, metric), metric, start, mode, dayOf(now));
}

MetricCell _cell(
  Map<DateTime, DayMetricEntry> byDay,
  DayMetric metric,
  DateTime start,
  CalendarMode mode,
  DateTime today,
) {
  final end = nextPeriod(start, mode);
  final days = <MetricDay>[
    for (var day = start; day.isBefore(end); day = nextDay(day))
      MetricDay(
        day: day,
        value: byDay[day]?.value,
        note: byDay[day]?.note,
        isToday: day == today,
        isFuture: day.isAfter(today),
      ),
  ];

  final known = days.where((day) => day.value != null);
  final isSum = metric.aggregation == MetricAggregation.sum;
  final counted = isSum ? known.where((day) => !day.isToday) : known;

  double? averageOf(Iterable<MetricDay> items) {
    if (items.isEmpty) {
      return null;
    }

    return items.fold<double>(0, (sum, day) => sum + day.value!) /
        items.length;
  }

  final average = averageOf(counted);

  return MetricCell(
    metric: metric,
    start: start,
    end: end,
    mode: mode,
    days: days,
    value: known.isEmpty
        ? null
        : isSum
            ? known.fold<double>(0, (sum, day) => sum + day.value!)
            : average,
    average: average,
    countedDays: counted.length,
  );
}
