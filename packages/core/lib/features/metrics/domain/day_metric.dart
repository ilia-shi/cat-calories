/// How days of a metric add up to a longer period.
enum MetricAggregation { sum, average }

/// A number recorded once per day. The stored [key] is text, so a metric this
/// app version does not know survives in the database instead of breaking it.
enum DayMetric {
  steps('steps', 'Steps', 'steps', MetricAggregation.sum, 20000),
  sleepMinutes('sleep_minutes', 'Sleep', 'h', MetricAggregation.average, 720),
  burnedKcal('burned_kcal', 'Burned', 'kcal', MetricAggregation.sum, 5000);

  final String key;
  final String title;

  /// The unit the user types in. Sleep is typed in hours and stored in minutes.
  final String inputUnit;

  final MetricAggregation aggregation;

  /// The stored value drawn at full bar height. Fixed, so bars of any two
  /// calendar cells compare directly.
  final double barFull;

  const DayMetric(
    this.key,
    this.title,
    this.inputUnit,
    this.aggregation,
    this.barFull,
  );

  static DayMetric? fromKey(String key) {
    for (final metric in values) {
      if (metric.key == key) {
        return metric;
      }
    }

    return null;
  }

  /// The value to store for [typed], always a whole number.
  double fromInput(double typed) {
    return switch (this) {
      DayMetric.sleepMinutes => (typed * 60).roundToDouble(),
      _ => typed.roundToDouble(),
    };
  }

  /// [stored] as the user would type it. Two decimals of an hour are enough for
  /// [fromInput] to bring back the same whole minute.
  String toInput(double stored) {
    if (this != DayMetric.sleepMinutes) {
      return stored.toStringAsFixed(0);
    }

    return (stored / 60)
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String format(double stored) {
    return switch (this) {
      DayMetric.steps => stored.toStringAsFixed(0),
      DayMetric.burnedKcal => '${stored.toStringAsFixed(0)} kcal',
      DayMetric.sleepMinutes => _formatMinutes(stored.round()),
    };
  }

  /// Sleep for a calendar cell, which is too narrow for [format].
  static String compactSleep(double stored) {
    final total = stored.round();
    final hours = total ~/ 60;
    final minutes = total % 60;
    if (hours == 0) {
      return '${minutes}m';
    }

    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  String _formatMinutes(int total) {
    final hours = total ~/ 60;
    final minutes = total % 60;
    if (hours == 0) {
      return '$minutes min';
    }

    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }
}
