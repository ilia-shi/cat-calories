enum TrackingMetric {
  duration, // ellipsoid 20 min
  reps, // squats 20 times
  sets, // squats 2 sets
  weight, // lat pull down 40 kg
  distance, // running 5 km
  count, // steps 9583, anki cards 50
  calories, // ellipsoid 200 kcal (even if "fake")
}

final class MetricValueFactory {
  static MetricValue fromJson(Map<String, dynamic> json) {
    final name = TrackingMetric.values.byName(json['metric'] as String);

    return switch (name) {
      TrackingMetric.count => CountValue.fromJson(json),
      TrackingMetric.reps => RepsValue.fromJson(json),
      TrackingMetric.duration => DurationValue.fromJson(json),
      TrackingMetric.weight => WeightValue.fromJson(json),
      TrackingMetric.distance => DistanceValue.fromJson(json),
      TrackingMetric.calories => CaloriesValue.fromJson(json),
      TrackingMetric.sets =>
        throw ArgumentError('sets has no associated value class'),
    };
  }
}

abstract class MetricValue {
  TrackingMetric get metric;

  Map<String, dynamic> toJson();
}

final class CountValue implements MetricValue {
  @override
  TrackingMetric get metric => TrackingMetric.count;
  int value;

  CountValue(
    this.value,
  );

  factory CountValue.fromJson(Map<String, dynamic> json) =>
      CountValue(json['value'] as int);

  @override
  Map<String, dynamic> toJson() => {
        'metric': metric.name,
        'value': value,
      };
}

final class RepsValue implements MetricValue {
  @override
  TrackingMetric get metric => TrackingMetric.reps;

  int reps;

  RepsValue(
    this.reps,
  );

  factory RepsValue.fromJson(Map<String, dynamic> json) =>
      RepsValue(json['reps'] as int);

  @override
  Map<String, dynamic> toJson() => {
        'metric': metric.name,
        'reps': reps,
      };
}

final class DurationValue implements MetricValue {
  @override
  TrackingMetric get metric => TrackingMetric.duration;

  int seconds;

  DurationValue(
    this.seconds,
  );

  factory DurationValue.fromJson(Map<String, dynamic> json) =>
      DurationValue(json['seconds'] as int);

  @override
  Map<String, dynamic> toJson() => {
        'metric': metric.name,
        'seconds': seconds,
      };
}

final class WeightValue implements MetricValue {
  @override
  TrackingMetric get metric => TrackingMetric.weight;

  double kg;

  WeightValue(
    this.kg,
  );

  factory WeightValue.fromJson(Map<String, dynamic> json) =>
      WeightValue((json['kg'] as num).toDouble());

  @override
  Map<String, dynamic> toJson() => {
        'metric': metric.name,
        'kg': kg,
      };
}

final class DistanceValue implements MetricValue {
  @override
  TrackingMetric get metric => TrackingMetric.distance;

  double meters;

  DistanceValue(
    this.meters,
  );

  factory DistanceValue.fromJson(Map<String, dynamic> json) =>
      DistanceValue((json['meters'] as num).toDouble());

  @override
  Map<String, dynamic> toJson() => {'metric': metric.name, 'meters': meters};
}

final class CaloriesValue implements MetricValue {
  @override
  TrackingMetric get metric => TrackingMetric.calories;

  double kcal;

  CaloriesValue(
    this.kcal,
  );

  factory CaloriesValue.fromJson(Map<String, dynamic> json) =>
      CaloriesValue((json['kcal'] as num).toDouble());

  @override
  Map<String, dynamic> toJson() => {'metric': metric.name, 'kcal': kcal};
}
