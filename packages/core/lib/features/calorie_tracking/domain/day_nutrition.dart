/// One day's eaten totals with macros. Kept apart from `DayResult`, which feeds
/// the recommendation and the export, neither of which needs macros.
final class DayNutrition {
  final DateTime day;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final int recordCount;

  /// Records with at least one macro. Fewer than [recordCount] means the macro
  /// sums are lower bounds: a missing macro is unknown, not 0 g.
  final int recordsWithMacros;

  const DayNutrition({
    required this.day,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.recordCount,
    required this.recordsWithMacros,
  });

  factory DayNutrition.fromJson(Map<String, dynamic> json) => DayNutrition(
        day: DateTime.fromMillisecondsSinceEpoch(
            (json['record_day'] as int) * 100000),
        kcal: (json['value_sum'] as num?)?.toDouble() ?? 0,
        protein: (json['protein_sum'] as num?)?.toDouble() ?? 0,
        fat: (json['fat_sum'] as num?)?.toDouble() ?? 0,
        carbs: (json['carb_sum'] as num?)?.toDouble() ?? 0,
        recordCount: json['record_count'] as int,
        recordsWithMacros: json['macro_count'] as int,
      );

  DayNutrition plus(DayNutrition other) => DayNutrition(
        day: day,
        kcal: kcal + other.kcal,
        protein: protein + other.protein,
        fat: fat + other.fat,
        carbs: carbs + other.carbs,
        recordCount: recordCount + other.recordCount,
        recordsWithMacros: recordsWithMacros + other.recordsWithMacros,
      );
}
