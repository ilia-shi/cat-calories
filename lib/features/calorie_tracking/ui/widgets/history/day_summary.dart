/// Per-day aggregation used to render a [DateGroupCard] header: eaten total,
/// positive/negative splits, item count and macro totals. A view-model built
/// while grouping records — not a persisted domain type.
class DaySummary {
  double totalEaten = 0;
  double positiveSum = 0;
  double negativeSum = 0;
  int itemCount = 0;

  /// What is planned for the day but not eaten yet. Kept apart from
  /// [totalEaten] so a plan never inflates a day's consumed calories.
  double plannedKcal = 0;
  int plannedItemCount = 0;

  /// A day with a plan and nothing eaten yet shows the planned figure as its
  /// headline; a day with both shows the eaten total and the plan beside it.
  bool get showsPlannedTotal => totalEaten == 0 && plannedKcal > 0;

  // Macro totals
  double totalProtein = 0;
  double totalFat = 0;
  double totalCarbs = 0;

  // Track if we have data for each macro
  bool hasProteinData = false;
  bool hasFatData = false;
  bool hasCarbData = false;

  bool get hasMacroData => hasProteinData || hasFatData || hasCarbData;
}
