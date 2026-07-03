import 'package:cat_calories_core/features/products/domain/product.dart';

import './calorie_record.dart';
import './meal.dart';

/// "Save meal as product" (leftovers flow): once the user knows the total
/// cooked weight, the dish becomes an ordinary per-100g product — eating
/// leftovers tomorrow is a single record by weight.
final class CookedMealProduct {
  /// Returns null when [cookedWeightGrams] is not positive or the meal has
  /// no ingredients to derive nutrition from.
  static Product? build({
    required Meal meal,
    required List<CalorieRecord> records,
    required double cookedWeightGrams,
    required DateTime now,
  }) {
    if (cookedWeightGrams <= 0 || records.isEmpty) {
      return null;
    }

    final totalKcal = records.fold<double>(0, (sum, r) => sum + r.value);
    double protein = 0, fat = 0, carbs = 0;
    bool hasMacros = false;
    final costs = <String, double>{};
    bool costMissing = false;
    for (final record in records) {
      if (record.proteinGrams != null ||
          record.fatGrams != null ||
          record.carbGrams != null) {
        hasMacros = true;
        protein += record.proteinGrams ?? 0;
        fat += record.fatGrams ?? 0;
        carbs += record.carbGrams ?? 0;
      }
      if (record.costValue == null) {
        costMissing = true;
      } else {
        final currency = record.costCurrency ?? '?';
        costs[currency] = (costs[currency] ?? 0) + record.costValue!;
      }
    }

    double per100(double total) => total / cookedWeightGrams * 100;

    // A package price only makes sense as a complete single-currency sum —
    // partial or mixed-currency totals would understate the dish's cost.
    final hasPrice = !costMissing && costs.length == 1;

    return Product(
      id: null,
      title: meal.title,
      description: meal.notes,
      usesCount: 0,
      createdAt: now,
      updatedAt: now,
      profileId: meal.profileId,
      barcode: null,
      sortOrder: 0,
      caloriesPer100g: per100(totalKcal),
      proteinsPer100g: hasMacros ? per100(protein) : null,
      fatsPer100g: hasMacros ? per100(fat) : null,
      carbsPer100g: hasMacros ? per100(carbs) : null,
      packageWeightGrams: cookedWeightGrams,
      pricePerPackage: hasPrice ? costs.values.single : null,
      priceCurrency: hasPrice ? costs.keys.single : null,
      priceUpdatedAt: hasPrice ? now : null,
    );
  }
}
