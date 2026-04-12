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
  List<TrackingMetric> metrics = [];

  // E.g. for ellipsoid that counts steps in a fitness tracker
  ExerciseId? parentExerciseId = null;
  String? unit = null;
  bool isUnilateral = false;

  Exercise(
    this.id,
    this.createdAt,
    this.name,
  );
}

// TODO:
