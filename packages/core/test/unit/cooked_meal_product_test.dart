import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/cooked_meal_product.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 7, 3, 18);

  Meal meal({String? notes}) => Meal(
        id: 'm1',
        profileId: 'p1',
        title: 'Chicken curry',
        notes: notes,
        createdAt: DateTime(2026, 7, 2),
      );

  CalorieRecord record({
    double value = 100,
    double? protein,
    double? fat,
    double? carbs,
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
        costValue: costValue,
        costCurrency: costCurrency,
      );

  test('derives per-100g nutrition and package price from the cooked dish',
      () {
    final product = CookedMealProduct.build(
      meal: meal(notes: 'less oil'),
      records: [
        record(value: 395, protein: 42, fat: 25, costValue: 1.2, costCurrency: 'EUR'),
        record(value: 288, carbs: 60, costValue: 0.3, costCurrency: 'EUR'),
      ],
      cookedWeightGrams: 850,
      now: now,
    )!;

    expect(product.title, 'Chicken curry');
    expect(product.description, 'less oil');
    expect(product.profileId, 'p1');
    expect(product.packageWeightGrams, 850);
    expect(product.caloriesPer100g, closeTo(683 / 850 * 100, 0.001));
    expect(product.proteinsPer100g, closeTo(42 / 850 * 100, 0.001));
    expect(product.carbsPer100g, closeTo(60 / 850 * 100, 0.001));
    expect(product.pricePerPackage, closeTo(1.5, 0.001));
    expect(product.priceCurrency, 'EUR');
    expect(product.priceUpdatedAt, now);
  });

  test('no price when any ingredient lacks cost or currencies are mixed', () {
    final partial = CookedMealProduct.build(
      meal: meal(),
      records: [
        record(value: 100, costValue: 1, costCurrency: 'EUR'),
        record(value: 100),
      ],
      cookedWeightGrams: 500,
      now: now,
    )!;
    expect(partial.pricePerPackage, isNull);
    expect(partial.caloriesPer100g, closeTo(40, 0.001));

    final mixed = CookedMealProduct.build(
      meal: meal(),
      records: [
        record(value: 100, costValue: 1, costCurrency: 'EUR'),
        record(value: 100, costValue: 9, costCurrency: 'GEL'),
      ],
      cookedWeightGrams: 500,
      now: now,
    )!;
    expect(mixed.pricePerPackage, isNull);
  });

  test('no macros in ingredients → per-100g macros stay null', () {
    final product = CookedMealProduct.build(
      meal: meal(),
      records: [record(value: 200)],
      cookedWeightGrams: 400,
      now: now,
    )!;
    expect(product.proteinsPer100g, isNull);
    expect(product.hasNutrition, isTrue);
  });

  test('returns null for non-positive weight or empty meal', () {
    expect(
      CookedMealProduct.build(
          meal: meal(), records: [record()], cookedWeightGrams: 0, now: now),
      isNull,
    );
    expect(
      CookedMealProduct.build(
          meal: meal(), records: [], cookedWeightGrams: 500, now: now),
      isNull,
    );
  });
}
