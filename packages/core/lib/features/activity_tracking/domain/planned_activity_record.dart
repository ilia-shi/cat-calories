import './activity_record.dart';
import 'package:cat_calories_core/features/planning/domain/plan_item.dart';

final class PlannedActivityRecord implements PlanItem {
  ActivityRecord activityRecord;
  DateTime _plannedAt;

  PlannedActivityRecord(this.activityRecord, this._plannedAt);

  @override
  DateTime? completedAt() {
    return this.activityRecord.completedAt;
  }

  @override
  String identifier() {
    return this.activityRecord.id.value;
  }

  @override
  DateTime plannedAt() {
    return this._plannedAt;
  }

  @override
  void setCompletedAt(DateTime completedAt) {
    this.activityRecord.completedAt = completedAt;
  }

  @override
  void setUncompleted() {
    this.activityRecord.completedAt = null;
  }

  @override
  Status status() {
    if (null == this.activityRecord.completedAt) {
      return Status.planned;
    }

    return Status.completed;
  }

  @override
  PlanItem copy(DateTime createdAt) {
    return new PlannedActivityRecord(
      this.activityRecord.copyWith(
            ActivityRecordId.next(),
            createdAt,
            null,
          ),
      this._plannedAt,
    );
  }
}
