import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';

final class MealSyncAdapter extends SyncAdapter<Meal> {
  @override
  String get entityType => 'meal';

  @override
  Map<String, dynamic> toSyncPayload(Meal entry) => entry.toJson();

  @override
  Meal fromSyncPayload(Map<String, dynamic> json) => Meal.fromJson(json);

  String extractIdentifier(Meal entity) {
    if (null == entity.id) {
      throw Exception('No entity ID');
    }

    return entity.id ?? '';
  }

  @override
  String extractScope(Meal entity) {
    return entity.profileId;
  }

  @override
  DateTime extractUpdatedAt(Meal entity) {
    return entity.updatedAt;
  }
}
