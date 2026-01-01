import 'dart:math';

final class RollingTrackerConfig {
  final double targetDailyCalories;
  final double minMealSize;
  final double maxMealSize;
  final double minHoursBetweenMeals;
  final CompensationConfig compensation;

  const RollingTrackerConfig({
    this.targetDailyCalories = 2000,
    this.minMealSize = 100,
    this.maxMealSize = 1000,
    this.minHoursBetweenMeals = 2.0,
    this.compensation = const CompensationConfig(),
  });

  RollingTrackerConfig copyWith({
    double? targetDailyCalories,
    double? minMealSize,
    double? maxMealSize,
    double? minHoursBetweenMeals,
    CompensationConfig? compensation,
  }) {
    return RollingTrackerConfig(
      targetDailyCalories: targetDailyCalories ?? this.targetDailyCalories,
      minMealSize: minMealSize ?? this.minMealSize,
      maxMealSize: maxMealSize ?? this.maxMealSize,
      minHoursBetweenMeals: minHoursBetweenMeals ?? this.minHoursBetweenMeals,
      compensation: compensation ?? this.compensation,
    );
  }
}

/// Configuration for compensation behavior
final class CompensationConfig {
  /// How aggressively to compensate (0-1)
  final double strength;

  /// Decay factor for time-weighting (0-1)
  final double decayFactor;

  /// How far back to look for compensation (hours)
  final int windowHours;

  const CompensationConfig({
    this.strength = 0.2,
    this.decayFactor = 0.85,
    this.windowHours = 96,
  });
}

/// A single calorie entry
class CalorieEntry {
  final DateTime createdAt;
  final double value;
  final String? description;

  const CalorieEntry({
    required this.createdAt,
    required this.value,
    this.description,
  });
}

/// Compensation information
class CompensationInfo {
  final bool isActive;
  final double amount;
  final String reason;
  final double rawDeviation;

  const CompensationInfo({
    required this.isActive,
    required this.amount,
    required this.reason,
    required this.rawDeviation,
  });
}

/// Complete meal recommendation
class MealRecommendation {
  final double consumed24h;
  final double remaining24h;
  final double target24h;
  final double baseTarget24h;
  final double recommendedMin;
  final double recommendedMax;
  final DateTime? waitUntil;
  final String reasoning;
  final double? hoursSinceLastMeal;
  final DateTime? lastMealTime;
  final double percentUsed;
  final CompensationInfo compensation;

  const MealRecommendation({
    required this.consumed24h,
    required this.remaining24h,
    required this.target24h,
    required this.baseTarget24h,
    required this.recommendedMin,
    required this.recommendedMax,
    this.waitUntil,
    required this.reasoning,
    this.hoursSinceLastMeal,
    this.lastMealTime,
    required this.percentUsed,
    required this.compensation,
  });

  bool get canEatNow => remaining24h >= 50 && (waitUntil == null || waitUntil!.isBefore(DateTime.now()));
}

/// Budget forecast point
class BudgetForecast {
  final DateTime time;
  final double availableBudget;

  const BudgetForecast({
    required this.time,
    required this.availableBudget,
  });
}

/// Entry that will expire from the 24h window
class ExpiringEntry {
  final CalorieEntry entry;
  final DateTime expiresAt;

  const ExpiringEntry({
    required this.entry,
    required this.expiresAt,
  });
}

/// Period breakdown for weighted deviation calculation
class PeriodBreakdown {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double hoursAgo;
  final double consumed;
  final double expected;
  final double deviation;
  final double weight;
  final double weightedDeviation;

  const PeriodBreakdown({
    required this.periodStart,
    required this.periodEnd,
    required this.hoursAgo,
    required this.consumed,
    required this.expected,
    required this.deviation,
    required this.weight,
    required this.weightedDeviation,
  });
}

/// Weighted deviation result
class WeightedDeviationResult {
  final double weightedDeviation;
  final double totalWeight;
  final List<PeriodBreakdown> periodBreakdown;

  const WeightedDeviationResult({
    required this.weightedDeviation,
    required this.totalWeight,
    required this.periodBreakdown,
  });
}

/// Compensated target result
class CompensatedTarget {
  final double adjustedTarget;
  final double compensationAmount;
  final String compensationReason;
  final double rawDeviation;
  final bool isCompensating;

  const CompensatedTarget({
    required this.adjustedTarget,
    required this.compensationAmount,
    required this.compensationReason,
    required this.rawDeviation,
    required this.isCompensating,
  });
}

/// Main Rolling Calorie Tracker
class RollingCalorieTracker {
  final RollingTrackerConfig config;

  const RollingCalorieTracker({
    this.config = const RollingTrackerConfig(),
  });

  /// Get calories consumed in the last 24 hours
  double consumedInLast24h(List<CalorieEntry> entries, DateTime asOf) {
    final windowStart = asOf.subtract(const Duration(hours: 24));

    return entries
        .where((e) => e.createdAt.isAfter(windowStart) && !e.createdAt.isAfter(asOf))
        .fold(0.0, (sum, e) => sum + e.value);
  }

  /// Get remaining budget in the rolling 24h window
  double remainingBudget(List<CalorieEntry> entries, DateTime asOf, double target24h) {
    final consumed = consumedInLast24h(entries, asOf);
    return max(0, min(target24h, target24h - consumed));
  }

  /// Get entries within the last 24 hours, sorted newest first
  List<CalorieEntry> entriesInLast24h(List<CalorieEntry> entries, DateTime asOf) {
    final windowStart = asOf.subtract(const Duration(hours: 24));

    final filtered = entries
        .where((e) => e.createdAt.isAfter(windowStart) && !e.createdAt.isAfter(asOf))
        .toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  /// Get the last meal time
  DateTime? lastMealTime(List<CalorieEntry> entries, DateTime asOf) {
    final recent = entries.where((e) => !e.createdAt.isAfter(asOf)).toList();
    if (recent.isEmpty) return null;

    return recent.reduce((latest, e) =>
    e.createdAt.isAfter(latest.createdAt) ? e : latest
    ).createdAt;
  }

  /// Get hours since last meal
  double? hoursSinceLastMeal(List<CalorieEntry> entries, DateTime asOf) {
    final last = lastMealTime(entries, asOf);
    if (last == null) return null;

    return asOf.difference(last).inMinutes / 60.0;
  }

  /// Calculate time-weighted consumption deviation for compensation
  WeightedDeviationResult calculateWeightedDeviation(
      List<CalorieEntry> entries,
      DateTime asOf,
      ) {
    final windowHours = config.compensation.windowHours;
    final decayFactor = config.compensation.decayFactor;
    final targetPerHour = config.targetDailyCalories / 24;

    const periodHours = 6;
    final numPeriods = (windowHours / periodHours).ceil();

    final periodBreakdown = <PeriodBreakdown>[];
    double totalWeightedDeviation = 0;
    double totalWeight = 0;

    for (int i = 0; i < numPeriods; i++) {
      final periodEndHoursAgo = i * periodHours;
      final periodStartHoursAgo = min((i + 1) * periodHours, windowHours);

      if (periodEndHoursAgo >= windowHours) continue;

      final periodEnd = asOf.subtract(Duration(hours: periodEndHoursAgo));
      final periodStart = asOf.subtract(Duration(hours: periodStartHoursAgo));
      final actualPeriodHours = periodStartHoursAgo - periodEndHoursAgo;

      final periodConsumed = entries
          .where((e) => e.createdAt.isAfter(periodStart) && !e.createdAt.isAfter(periodEnd))
          .fold(0.0, (sum, e) => sum + e.value);

      final expectedConsumption = targetPerHour * actualPeriodHours;
      final deviation = periodConsumed - expectedConsumption;
      final weight = pow(decayFactor, i).toDouble();
      final weightedDev = deviation * weight;

      totalWeightedDeviation += weightedDev;
      totalWeight += weight;

      periodBreakdown.add(PeriodBreakdown(
        periodStart: periodStart,
        periodEnd: periodEnd,
        hoursAgo: periodEndHoursAgo.toDouble(),
        consumed: periodConsumed,
        expected: expectedConsumption,
        deviation: deviation,
        weight: weight,
        weightedDeviation: weightedDev,
      ));
    }

    return WeightedDeviationResult(
      weightedDeviation: totalWeightedDeviation,
      totalWeight: totalWeight,
      periodBreakdown: periodBreakdown,
    );
  }

  /// Calculate the compensated daily target based on recent consumption patterns
  CompensatedTarget getCompensatedTarget(List<CalorieEntry> entries, DateTime asOf) {
    final strength = config.compensation.strength;
    final baseTarget = config.targetDailyCalories;

    final result = calculateWeightedDeviation(entries, asOf);

    final normalizedDeviation =
    result.totalWeight > 0 ? result.weightedDeviation / result.totalWeight : 0.0;

    final rawDeviation = result.periodBreakdown.fold(0.0, (sum, p) => sum + p.deviation);

    final compensationAmount = -(normalizedDeviation * strength);

    final maxReduction = baseTarget * 0.3;
    final maxIncrease = baseTarget * 0.15;
    final clampedCompensation = max(-maxReduction, min(maxIncrease, compensationAmount));

    var adjustedTarget = (baseTarget + clampedCompensation).round().toDouble();

    final minTarget = (baseTarget * 0.6).round().toDouble();
    final maxTarget = (baseTarget * 1.2).round().toDouble();
    final finalTarget = max(minTarget, min(maxTarget, adjustedTarget));

    String compensationReason;
    final isCompensating = clampedCompensation.abs() > 10;

    if (!isCompensating) {
      compensationReason = "On track with your targets.";
    } else if (clampedCompensation < 0) {
      final overBy = (-clampedCompensation).round();
      compensationReason = "Compensating for recent over-consumption. Target reduced by $overBy kcal.";
    } else {
      final underBy = clampedCompensation.round();
      compensationReason = "Room to catch up from under-consumption. Target increased by $underBy kcal.";
    }

    return CompensatedTarget(
      adjustedTarget: finalTarget,
      compensationAmount: clampedCompensation.round().toDouble(),
      compensationReason: compensationReason,
      rawDeviation: rawDeviation.round().toDouble(),
      isCompensating: isCompensating,
    );
  }

  /// Calculate recommended meal size
  _MealSizeResult _calculateMealSize(
      double remainingBudget,
      double consumedKCal,
      double target24hKCal,
      ) {
    if (remainingBudget <= 50) {
      return _MealSizeResult(
        minKCal: 0,
        maxKCal: 0,
        reasoning: "You've reached your 24h target. Calories will free up as time passes.",
      );
    }

    if (remainingBudget < config.minMealSize) {
      return _MealSizeResult(
        minKCal: 0,
        maxKCal: remainingBudget,
        reasoning: "Limited budget remaining (${remainingBudget.round()} kcal). Small snack only if needed.",
      );
    }

    final avgMealSize = (config.minMealSize + config.maxMealSize) / 2;
    final estimatedMealsRemaining = max(1.0, min(4.0, remainingBudget / avgMealSize));
    final idealSize = remainingBudget / estimatedMealsRemaining;

    final minKCal = max(config.minMealSize, min(remainingBudget, idealSize * 0.7));
    final maxKCal = max(minKCal, min(config.maxMealSize, min(remainingBudget, idealSize * 1.3)));

    final percentUsed = (consumedKCal / target24hKCal * 100).round();
    final reasoning = "$percentUsed% of 24h budget used. ${remainingBudget.round()} kcal available for ~${estimatedMealsRemaining.round()} more meal(s).";

    return _MealSizeResult(
      minKCal: minKCal,
      maxKCal: maxKCal,
      reasoning: reasoning,
    );
  }

  /// Get complete meal recommendation
  MealRecommendation getRecommendation(List<CalorieEntry> entries, DateTime now) {
    final compensated = getCompensatedTarget(entries, now);

    final consumed = consumedInLast24h(entries, now);
    final remaining = remainingBudget(entries, now, compensated.adjustedTarget);
    final hoursSinceLast = hoursSinceLastMeal(entries, now);
    final lastTime = lastMealTime(entries, now);

    DateTime? waitUntil;
    if (hoursSinceLast != null && hoursSinceLast < config.minHoursBetweenMeals && lastTime != null) {
      waitUntil = lastTime.add(Duration(
        minutes: (config.minHoursBetweenMeals * 60).round(),
      ));
    }

    final mealSize = _calculateMealSize(remaining, consumed, compensated.adjustedTarget);

    final percentUsed = compensated.adjustedTarget > 0
        ? (consumed / compensated.adjustedTarget) * 100
        : 0.0;

    return MealRecommendation(
      consumed24h: consumed,
      remaining24h: remaining,
      target24h: compensated.adjustedTarget,
      baseTarget24h: config.targetDailyCalories,
      recommendedMin: mealSize.minKCal,
      recommendedMax: mealSize.maxKCal,
      waitUntil: waitUntil,
      reasoning: mealSize.reasoning,
      hoursSinceLastMeal: hoursSinceLast,
      lastMealTime: lastTime,
      percentUsed: percentUsed,
      compensation: CompensationInfo(
        isActive: compensated.isCompensating,
        amount: compensated.compensationAmount,
        reason: compensated.compensationReason,
        rawDeviation: compensated.rawDeviation,
      ),
    );
  }

  /// Project when budget will free up
  List<BudgetForecast> getForecast(
      List<CalorieEntry> entries,
      DateTime now, {
        int hours = 12,
      }) {
    final compensated = getCompensatedTarget(entries, now);
    final forecasts = <BudgetForecast>[];

    for (int h = 0; h <= hours; h += 2) {
      final futureTime = now.add(Duration(hours: h));
      final futureRemaining = remainingBudget(entries, futureTime, compensated.adjustedTarget);
      forecasts.add(BudgetForecast(time: futureTime, availableBudget: futureRemaining));
    }

    return forecasts;
  }

  /// Get entries that will expire in the next N hours
  List<ExpiringEntry> getUpcomingExpirations(
      List<CalorieEntry> entries,
      DateTime now, {
        int withinHours = 6,
      }) {
    final windowStart = now.subtract(const Duration(hours: 24));
    final windowEnd = now.subtract(Duration(hours: 24 - withinHours));

    final expiring = entries
        .where((e) => e.createdAt.isAfter(windowStart) && e.createdAt.isBefore(windowEnd))
        .map((entry) => ExpiringEntry(
      entry: entry,
      expiresAt: entry.createdAt.add(const Duration(hours: 24)),
    ))
        .toList();

    expiring.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    return expiring;
  }

  /// Get long-term average daily consumption
  double getAverageDaily(List<CalorieEntry> entries, DateTime asOf, {int days = 7}) {
    final startDate = asOf.subtract(Duration(days: days));

    final relevantEntries = entries
        .where((e) => e.createdAt.isAfter(startDate) && e.createdAt.isBefore(asOf))
        .toList();

    if (relevantEntries.isEmpty) return 0;

    final total = relevantEntries.fold(0.0, (sum, e) => sum + e.value);
    return total / days;
  }
}

class _MealSizeResult {
  final double minKCal;
  final double maxKCal;
  final String reasoning;

  const _MealSizeResult({
    required this.minKCal,
    required this.maxKCal,
    required this.reasoning,
  });
}