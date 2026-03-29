class CalorieRecommendation {
  final double recommendedToday;
  final double baseGoal;
  final double adjustment;
  final double consumedToday;
  final double remainingToday;
  final double accumulatedDeviation;
  final List<DayForecast> forecast;
  final PacingRecommendation? pacing;
  final List<DayCompensation> compensationBreakdown;

  CalorieRecommendation({
    required this.recommendedToday,
    required this.baseGoal,
    required this.adjustment,
    required this.consumedToday,
    required this.remainingToday,
    required this.accumulatedDeviation,
    required this.forecast,
    required this.compensationBreakdown,
    this.pacing,
  });

  bool get isOverConsumed => consumedToday > recommendedToday;
  double get consumptionPercent => (consumedToday / recommendedToday) * 100;
}

class DayForecast {
  final DateTime date;
  final double recommendedCalories;
  final double adjustment;

  DayForecast({
    required this.date,
    required this.recommendedCalories,
    required this.adjustment,
  });
}

class DayCompensation {
  final DateTime date;
  final double consumed;
  final double target;
  final double deviation;
  final double weight;
  final double weightedDeviation;

  DayCompensation({
    required this.date,
    required this.consumed,
    required this.target,
    required this.deviation,
    required this.weight,
    required this.weightedDeviation,
  });
}

class PacingRecommendation {
  final DateTime? nextEatTime;
  final double suggestedNextMealCalories;
  final double remainingHours;
  final int suggestedRemainingMeals;
  final double caloriesPerRemainingHour;
  final String message;

  PacingRecommendation({
    this.nextEatTime,
    required this.suggestedNextMealCalories,
    required this.remainingHours,
    required this.suggestedRemainingMeals,
    required this.caloriesPerRemainingHour,
    required this.message,
  });
}