import 'package:cat_calories_core/features/activity_tracking/domain/tracking_metric.dart';
import 'package:uuid/uuid.dart';

extension type ExerciseId(String value) {
  static ExerciseId next() {
    return ExerciseId(Uuid().v4());
  }
}

final class Exercise {
  ExerciseId id;
  DateTime createdAt;
  String name;
  String? description = null;
  List<TrackingMetric> trackingMetrics = [];
  ExerciseId? parentExerciseId = null;
  String? weightUnit = null;
  bool isUnilateral = false;

  Exercise(
    this.id,
    this.createdAt,
    this.name,
  );
}
