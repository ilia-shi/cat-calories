import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';

/// The summed figures of a group of records — a meal's ingredients, or any
/// other set a screen totals up.
final class MealTotals {
  /// Cost bucket for records that carry a price but no currency code, kept
  /// apart so an unknown currency never merges into a known one.
  static const String unknownCurrency = '?';

  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final double weightGrams;

  /// Cost summed per currency code.
  final Map<String, double> costs;

  /// False when not a single record carried a macro — what tells the UI to hide
  /// the macro display instead of showing three zeroes.
  final bool hasMacros;

  const MealTotals({
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.weightGrams,
    required this.costs,
    required this.hasMacros,
  });

  factory MealTotals.of(Iterable<CalorieRecord> records) {
    double kcal = 0, protein = 0, fat = 0, carbs = 0, weightGrams = 0;
    bool hasMacros = false;
    final costs = <String, double>{};

    for (final record in records) {
      kcal += record.value;
      weightGrams += record.weightGrams ?? 0;
      if (record.proteinGrams != null ||
          record.fatGrams != null ||
          record.carbGrams != null) {
        hasMacros = true;
        protein += record.proteinGrams ?? 0;
        fat += record.fatGrams ?? 0;
        carbs += record.carbGrams ?? 0;
      }
      if (record.costValue != null) {
        final currency = record.costCurrency ?? unknownCurrency;
        costs[currency] = (costs[currency] ?? 0) + record.costValue!;
      }
    }

    return MealTotals(
      kcal: kcal,
      protein: protein,
      fat: fat,
      carbs: carbs,
      weightGrams: weightGrams,
      costs: costs,
      hasMacros: hasMacros,
    );
  }

  bool get hasWeight => weightGrams > 0;
}
