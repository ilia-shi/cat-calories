/// A number recorded once per day. The stored [key] is text, so a metric this
/// app version does not know survives in the database instead of breaking it.
enum DayMetric {
  steps('steps', 'Steps', 'steps'),
  sleepMinutes('sleep_minutes', 'Sleep', 'h'),
  burnedKcal('burned_kcal', 'Burned', 'kcal');

  final String key;
  final String title;

  /// The unit the user types in. Sleep is typed in hours and stored in minutes.
  final String inputUnit;

  const DayMetric(this.key, this.title, this.inputUnit);

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

  String _formatMinutes(int total) {
    final hours = total ~/ 60;
    final minutes = total % 60;
    if (hours == 0) {
      return '$minutes min';
    }

    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }
}
