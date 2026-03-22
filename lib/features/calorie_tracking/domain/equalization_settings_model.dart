final class EqualizationSettingsModel {
  /// Base daily calorie goal (e.g., 2000 kcal)
  final double baseCalorieGoal;

  /// Number of past days to consider for compensation (default: 7)
  final int lookbackDays;

  /// Number of days to spread compensation over (default: 3)
  final int compensationDays;

  /// Maximum daily adjustment as percentage (0.10 = 10%)
  final double maxDailyAdjustmentPercent;

  /// Decay factor for older days (0.7 = each older day counts 70% of previous)
  final double decayFactor;

  /// Minimum time between meals in minutes (default: 120)
  final int minTimeBetweenMealsMinutes;

  /// Target hours for eating window (e.g., 16 hours awake)
  final int eatingWindowHours;

  const EqualizationSettingsModel({
    this.baseCalorieGoal = 2000.0,
    this.lookbackDays = 7,
    this.compensationDays = 3,
    this.maxDailyAdjustmentPercent = 0.10,
    this.decayFactor = 0.7,
    this.minTimeBetweenMealsMinutes = 120,
    this.eatingWindowHours = 16,
  });

  double get maxDailyAdjustment => baseCalorieGoal * maxDailyAdjustmentPercent;
  double get minRecommendedDaily => baseCalorieGoal - maxDailyAdjustment;
  double get maxRecommendedDaily => baseCalorieGoal + maxDailyAdjustment;
  double get caloriesPerHour => baseCalorieGoal / eatingWindowHours;

  Map<String, dynamic> toJson() => {
    'base_calorie_goal': baseCalorieGoal,
    'lookback_days': lookbackDays,
    'compensation_days': compensationDays,
    'max_daily_adjustment_percent': maxDailyAdjustmentPercent,
    'decay_factor': decayFactor,
    'min_time_between_meals_minutes': minTimeBetweenMealsMinutes,
    'eating_window_hours': eatingWindowHours,
  };

  factory EqualizationSettingsModel.fromJson(Map<String, dynamic> json) {
    return EqualizationSettingsModel(
      baseCalorieGoal: json['base_calorie_goal'] ?? 2000.0,
      lookbackDays: json['lookback_days'] ?? 7,
      compensationDays: json['compensation_days'] ?? 3,
      maxDailyAdjustmentPercent: json['max_daily_adjustment_percent'] ?? 0.10,
      decayFactor: json['decay_factor'] ?? 0.7,
      minTimeBetweenMealsMinutes: json['min_time_between_meals_minutes'] ?? 120,
      eatingWindowHours: json['eating_window_hours'] ?? 16,
    );
  }
}