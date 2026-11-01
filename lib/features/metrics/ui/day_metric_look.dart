import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:flutter/material.dart';

extension DayMetricLook on DayMetric {
  IconData get icon => switch (this) {
        DayMetric.steps => Icons.directions_walk,
        DayMetric.sleepMinutes => Icons.bedtime_outlined,
        DayMetric.burnedKcal => Icons.local_fire_department_outlined,
      };

  Color get color => switch (this) {
        DayMetric.steps => Colors.teal,
        DayMetric.sleepMinutes => Colors.indigo,
        DayMetric.burnedKcal => Colors.deepOrange,
      };

  String? get hint => switch (this) {
        DayMetric.steps => null,
        DayMetric.sleepMinutes => 'For the night that ended on this day',
        DayMetric.burnedKcal =>
          'Only compared between days, never subtracted from food',
      };
}
