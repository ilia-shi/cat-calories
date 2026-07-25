import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_totals.dart';
import 'package:test/test.dart';

void main() {
  CalorieRecord record({
    double value = 100,
    double? protein,
    double? fat,
    double? carbs,
    double? weight,
    double? costValue,
    String? costCurrency,
  }) =>
      CalorieRecord(
        id: 'r-$value',
        value: value,
        description: 'x',
        sortOrder: 0,
        eatenAt: null,
        createdAt: DateTime(2026, 7, 2),
        profileId: 'p1',
        wakingPeriodId: null,
        proteinGrams: protein,
        fatGrams: fat,
        carbGrams: carbs,
        weightGrams: weight,
        costValue: costValue,
        costCurrency: costCurrency,
      );

  test('sums kcal, macros and weight across records', () {
    final totals = MealTotals.of([
      record(value: 395, protein: 42, fat: 25, weight: 300),
      record(value: 288, carbs: 60, weight: 150),
    ]);

    expect(totals.kcal, 683);
    expect(totals.protein, 42);
    expect(totals.fat, 25);
    expect(totals.carbs, 60);
    expect(totals.weightGrams, 450);
    expect(totals.hasMacros, isTrue);
    expect(totals.hasWeight, isTrue);
  });

  test('reports no macros when not a single record carries one', () {
    final totals = MealTotals.of([record(value: 200), record(value: 50)]);

    expect(totals.kcal, 250);
    expect(totals.hasMacros, isFalse);
    expect(totals.hasWeight, isFalse);
    expect(totals.costs, isEmpty);
  });

  test('keeps cost sums apart per currency', () {
    final totals = MealTotals.of([
      record(costValue: 1.2, costCurrency: 'EUR'),
      record(costValue: 0.3, costCurrency: 'EUR'),
      record(costValue: 5, costCurrency: 'PLN'),
      record(costValue: 2),
    ]);

    expect(totals.costs['EUR'], closeTo(1.5, 1e-9));
    expect(totals.costs['PLN'], 5);
    expect(totals.costs[MealTotals.unknownCurrency], 2);
  });

  test('an empty meal totals to zero', () {
    final totals = MealTotals.of([]);

    expect(totals.kcal, 0);
    expect(totals.hasMacros, isFalse);
    expect(totals.costs, isEmpty);
  });
}
