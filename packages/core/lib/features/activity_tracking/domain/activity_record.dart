import 'package:uuid/uuid.dart';
import 'exercise.dart';
import 'set_record.dart';

extension type ActivityRecordId(String value) {
  static ActivityRecordId next() {
    return ActivityRecordId(Uuid().v4());
  }
}

final class ActivityRecord {
  ActivityRecordId id;
  DateTime createdAt;
  DateTime? completedAt = null;
  String userId;
  ExerciseId? exerciseId = null;
  String? description = null;
  List<SetRecord> sets = [];

  ActivityRecord({
    required this.id,
    required this.createdAt,
    required this.userId,
  });

  ActivityRecord copyWith(
    ActivityRecordId id,
    DateTime? createdAt,
    DateTime? completedAt,
  ) {
    var record = ActivityRecord(
      id: id,
      createdAt: createdAt ?? this.createdAt,
      userId: this.userId,
    );

    record.completedAt = completedAt;
    record.exerciseId = exerciseId;
    record.description = description;
    record.sets = sets;

    return record;
  }

  factory ActivityRecord.fromExercise(
    Exercise exercise,
    String userId,
  ) {
    return ActivityRecord(
      id: ActivityRecordId.next(),
      createdAt: DateTime.now(),
      userId: userId,
    );
  }
}
