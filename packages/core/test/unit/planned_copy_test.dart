import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/planned_calorie_record.dart';
import 'package:cat_calories_core/features/planning/domain/plan_item.dart';
import 'package:test/test.dart';

void main() {
  CalorieRecord eatenRecord() => CalorieRecord(
        id: 'r1',
        value: 395,
        description: 'chicken thigh',
        sortOrder: 7,
        eatenAt: DateTime(2026, 7, 2, 13),
        createdAt: DateTime(2026, 7, 2, 12),
        profileId: 'p1',
        wakingPeriodId: 'wp1',
        weightGrams: 250,
        proteinGrams: 42,
        fatGrams: 25,
        carbGrams: 0,
        productId: 'prod-1',
        mealId: 'meal-1',
        costValue: 1.2,
        costCurrency: 'EUR',
        costIsManual: true,
      );

  group('CalorieRecord.copyForPlanning', () {
    test('keeps nutrition/product/cost, resets identity and planning state',
        () {
      final createdAt = DateTime(2026, 7, 3, 9);
      final copy = eatenRecord().copyForPlanning(createdAt);

      expect(copy.id, isNull);
      expect(copy.eatenAt, isNull);
      expect(copy.isEaten(), isFalse);
      expect(copy.createdAt, createdAt);
      expect(copy.updatedAt, createdAt);
      expect(copy.sortOrder, 0);
      expect(copy.wakingPeriodId, isNull);
      expect(copy.mealId, isNull);

      expect(copy.value, 395);
      expect(copy.description, 'chicken thigh');
      expect(copy.weightGrams, 250);
      expect(copy.proteinGrams, 42);
      expect(copy.productId, 'prod-1');
      expect(copy.profileId, 'p1');
      expect(copy.costValue, 1.2);
      expect(copy.costCurrency, 'EUR');
      expect(copy.costIsManual, isFalse);
    });

    test('does not mutate the source record', () {
      final source = eatenRecord();
      source.copyForPlanning(DateTime(2026, 7, 3));

      expect(source.id, 'r1');
      expect(source.eatenAt, DateTime(2026, 7, 2, 13));
      expect(source.mealId, 'meal-1');
      expect(source.costIsManual, isTrue);
    });
  });

  group('PlannedCalorieRecord.copy', () {
    test('returns a planned item anchored at the new date', () {
      final planned =
          PlannedCalorieRecord(eatenRecord(), DateTime(2026, 7, 2, 12));
      final createdAt = DateTime(2026, 7, 3, 9);

      final copy = planned.copy(createdAt) as PlannedCalorieRecord;

      expect(copy.status(), Status.planned);
      expect(copy.plannedAt(), createdAt);
      expect(copy.completedAt(), isNull);
      expect(copy.calorieRecord.id, isNull);
      expect(copy.calorieRecord.value, 395);
    });
  });
}
