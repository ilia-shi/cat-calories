// lib/models/calorie_recommendation_model.dart

class CalorieRecommendationModel {
  /// Recommended calories for today
  final double recommendedToday;

  /// Base goal without adjustments
  final double baseGoal;

  /// Total adjustment applied (can be negative)
  final double adjustment;

  /// Calories already consumed today
  final double consumedToday;

  /// Remaining calories for today
  final double remainingToday;

  /// Accumulated surplus/deficit being compensated
  final double accumulatedDeviation;

  /// Forecast for upcoming days
  final List<DayForecast> forecast;

  /// Intra-day pacing recommendation
  final PacingRecommendation? pacing;

  /// Daily breakdown showing compensation calculation
  final List<DayCompensation> compensationBreakdown;

  CalorieRecommendationModel({
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
  /// When you can eat next
  final DateTime? nextEatTime;

  /// Suggested calories for next meal
  final double suggestedNextMealCalories;

  /// Remaining hours in eating window
  final double remainingHours;

  /// Suggested number of remaining meals
  final int suggestedRemainingMeals;

  /// Calories per remaining hour
  final double caloriesPerRemainingHour;

  /// Message to display
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