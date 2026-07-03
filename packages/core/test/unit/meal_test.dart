import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/sync/meal_sync_adapter.dart';
import 'package:test/test.dart';

void main() {
  Meal meal() => Meal(
        id: 'm1',
        profileId: 'p1',
        title: 'Chicken curry',
        notes: 'less oil than last time',
        createdAt: DateTime(2026, 7, 1, 18),
        updatedAt: DateTime(2026, 7, 2, 12),
        eatenAt: DateTime(2026, 7, 2, 13),
        cookingMinutes: 30,
        tasteRating: 4,
        satietyRating: 5,
        totalCookedWeightGrams: 850,
      );

  test('Meal survives JSON round-trip with all fields', () {
    final restored = Meal.fromJson(meal().toJson());

    expect(restored.id, 'm1');
    expect(restored.profileId, 'p1');
    expect(restored.title, 'Chicken curry');
    expect(restored.notes, 'less oil than last time');
    expect(restored.createdAt, DateTime(2026, 7, 1, 18));
    expect(restored.updatedAt, DateTime(2026, 7, 2, 12));
    expect(restored.eatenAt, DateTime(2026, 7, 2, 13));
    expect(restored.cookingMinutes, 30);
    expect(restored.tasteRating, 4);
    expect(restored.satietyRating, 5);
    expect(restored.totalCookedWeightGrams, 850);
    expect(restored.isEaten(), isTrue);
  });

  test('nullable fields default to null; planned meal is not eaten', () {
    final planned = Meal(
      id: 'm2',
      profileId: 'p1',
      title: 'Overnight oats',
      createdAt: DateTime(2026, 7, 1),
    );
    final restored = Meal.fromJson(planned.toJson());

    expect(restored.notes, isNull);
    expect(restored.eatenAt, isNull);
    expect(restored.cookingMinutes, isNull);
    expect(restored.tasteRating, isNull);
    expect(restored.satietyRating, isNull);
    expect(restored.totalCookedWeightGrams, isNull);
    expect(restored.isEaten(), isFalse);
    expect(restored.updatedAt, restored.createdAt);
  });

  test('CalorieRecord meal_id survives JSON round-trip', () {
    final record = CalorieRecord(
      id: 'r1',
      value: 100,
      description: 'x',
      sortOrder: 0,
      eatenAt: null,
      createdAt: DateTime(2026, 7, 1),
      profileId: 'p1',
      wakingPeriodId: null,
      mealId: 'm1',
    );

    expect(CalorieRecord.fromJson(record.toJson()).mealId, 'm1');

    record.mealId = null;
    expect(CalorieRecord.fromJson(record.toJson()).mealId, isNull);
  });

  test('sync adapter round-trips and exposes meal entity type/scope', () {
    final adapter = MealSyncAdapter();
    expect(adapter.entityType, 'meal');
    expect(adapter.extractScope(meal()), 'p1');
    expect(adapter.extractUpdatedAt(meal()), DateTime(2026, 7, 2, 12));

    final restored = adapter.fromSyncPayload(adapter.toSyncPayload(meal()));
    expect(restored.title, 'Chicken curry');
    expect(restored.satietyRating, 5);
  });
}
