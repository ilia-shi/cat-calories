import './calorie_record.dart';
import 'package:cat_calories_core/features/planning/domain/plan_item.dart';

final class PlannedCalorieRecord implements PlanItem {
  CalorieRecord calorieRecord;
  DateTime _plannedAt;

  PlannedCalorieRecord(
    this.calorieRecord,
    this._plannedAt,
  );

  @override
  void setCompletedAt(DateTime competedAt) {
    this.calorieRecord.eatenAt = competedAt;
  }

  @override
  DateTime plannedAt() {
    return this._plannedAt;
  }

  @override
  DateTime? completedAt() {
    return this.calorieRecord.eatenAt;
  }

  @override
  void setUncompleted() {
    this.calorieRecord.eatenAt = null;
  }

  String identifier() {
    if (null == calorieRecord.id) {
      throw Exception('No calorie record ID');
    }

    return calorieRecord.id ?? '';
  }

  @override
  Status status() {
    if (this.calorieRecord.isEaten()) {
      return Status.completed;
    }

    return Status.planned;
  }

  @override
  PlanItem copy(DateTime createdAt) {
    // TODO: implement copy
    throw UnimplementedError();
  }
}
