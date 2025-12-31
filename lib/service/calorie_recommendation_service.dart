import 'dart:math';
import 'package:cat_calories/models/calorie_recommendation_model.dart';
import 'package:cat_calories/models/day_result.dart';
import 'package:cat_calories/models/equalization_settings_model.dart';

class CalorieRecommendationService {
  final EqualizationSettingsModel settings;

  CalorieRecommendationService(this.settings);

  /// Calculate recommendation based on historical data
  CalorieRecommendationModel calculate({
    required List<DayResultModel> historicalDays,
    required double consumedToday,
    required DateTime now,
    DateTime? lastMealTime,
    DateTime? wakingTime,
    DateTime? sleepTime,
  }) {
    final today = DateTime(now.year, now.month, now.day);

    // Filter to only past days (not including today)
    final pastDays = historicalDays
        .where((d) => d.createdAtDay.isBefore(today))
        .toList()
      ..sort((a, b) => b.createdAtDay.compareTo(a.createdAtDay));

    // Calculate weighted deviations
    final compensationBreakdown = _calculateCompensationBreakdown(pastDays, today);

    // Sum weighted deviations
    final totalWeightedDeviation = compensationBreakdown.fold<double>(
      0.0,
          (sum, day) => sum + day.weightedDeviation,
    );

    // Calculate adjustment (spread over compensation days)
    double rawAdjustment = -totalWeightedDeviation / settings.compensationDays;

    // Apply cap
    final cappedAdjustment = rawAdjustment.clamp(
      -settings.maxDailyAdjustment,
      settings.maxDailyAdjustment,
    );

    final recommendedToday = settings.baseCalorieGoal + cappedAdjustment;
    final remainingToday = recommendedToday - consumedToday;

    // Generate forecast
    final forecast = _generateForecast(totalWeightedDeviation, consumedToday, today);

    // Calculate pacing
    final pacing = _calculatePacing(
      remainingToday: remainingToday,
      now: now,
      lastMealTime: lastMealTime,
      wakingTime: wakingTime,
      sleepTime: sleepTime,
    );

    return CalorieRecommendationModel(
      recommendedToday: recommendedToday,
      baseGoal: settings.baseCalorieGoal,
      adjustment: cappedAdjustment,
      consumedToday: consumedToday,
      remainingToday: remainingToday,
      accumulatedDeviation: totalWeightedDeviation,
      forecast: forecast,
      compensationBreakdown: compensationBreakdown,
      pacing: pacing,
    );
  }

  List<DayCompensation> _calculateCompensationBreakdown(
      List<DayResultModel> pastDays,
      DateTime today,
      ) {
    final result = <DayCompensation>[];

    for (int i = 0; i < min(pastDays.length, settings.lookbackDays); i++) {
      final day = pastDays[i];
      final daysAgo = today.difference(day.createdAtDay).inDays;

      // Calculate decay weight: decay^(daysAgo - 1)
      // Day 1 ago = weight 1.0, Day 2 ago = weight 0.7, etc.
      final weight = pow(settings.decayFactor, daysAgo - 1).toDouble();

      final deviation = day.valueSum - settings.baseCalorieGoal;
      final weightedDeviation = deviation * weight;

      result.add(DayCompensation(
        date: day.createdAtDay,
        consumed: day.valueSum,
        target: settings.baseCalorieGoal,
        deviation: deviation,
        weight: weight,
        weightedDeviation: weightedDeviation,
      ));
    }

    return result;
  }

  List<DayForecast> _generateForecast(
      double currentDeviation,
      double consumedToday,
      DateTime today,
      ) {
    final forecast = <DayForecast>[];
    double remainingDeviation = currentDeviation;

    // Add today's projected deviation
    final todayProjectedDeviation = consumedToday - settings.baseCalorieGoal;

    for (int i = 1; i <= settings.compensationDays + 2; i++) {
      final date = today.add(Duration(days: i));

      // Simulate the deviation cascade
      double projectedDeviation = remainingDeviation;
      if (i == 1) {
        // Tomorrow also considers today's projected deviation
        projectedDeviation += todayProjectedDeviation * settings.decayFactor;
      }

      double adjustment = -projectedDeviation / settings.compensationDays;
      adjustment = adjustment.clamp(
        -settings.maxDailyAdjustment,
        settings.maxDailyAdjustment,
      );

      forecast.add(DayForecast(
        date: date,
        recommendedCalories: settings.baseCalorieGoal + adjustment,
        adjustment: adjustment,
      ));

      // Apply decay for next iteration
      remainingDeviation *= settings.decayFactor;
    }

    return forecast;
  }

  PacingRecommendation? _calculatePacing({
    required double remainingToday,
    required DateTime now,
    DateTime? lastMealTime,
    DateTime? wakingTime,
    DateTime? sleepTime,
  }) {
    // Default eating window: 8:00 to 22:00
    final defaultWakeTime = DateTime(now.year, now.month, now.day, 8, 0);
    final defaultSleepTime = DateTime(now.year, now.month, now.day, 22, 0);

    final effectiveWakeTime = wakingTime ?? defaultWakeTime;
    final effectiveSleepTime = sleepTime ?? defaultSleepTime;

    // Calculate remaining time in eating window
    final remainingMinutes = effectiveSleepTime.difference(now).inMinutes;
    if (remainingMinutes <= 0) {
      return PacingRecommendation(
        suggestedNextMealCalories: 0,
        remainingHours: 0,
        suggestedRemainingMeals: 0,
        caloriesPerRemainingHour: 0,
        message: 'Eating window has ended for today',
      );
    }

    final remainingHours = remainingMinutes / 60.0;

    // Calculate next eat time based on last meal
    DateTime? nextEatTime;
    if (lastMealTime != null) {
      nextEatTime = lastMealTime.add(
        Duration(minutes: settings.minTimeBetweenMealsMinutes),
      );
      if (nextEatTime.isBefore(now)) {
        nextEatTime = null; // Can eat now
      }
    }

    // Calculate suggested remaining meals
    final suggestedRemainingMeals = max(1, (remainingHours / 2).ceil());

    // Calories per remaining hour
    final caloriesPerRemainingHour = remainingToday > 0
        ? remainingToday / remainingHours
        : 0.0;

    // Suggested next meal calories
    final suggestedNextMealCalories = remainingToday > 0
        ? remainingToday / suggestedRemainingMeals
        : 0.0;

    // Generate message
    String message;
    if (remainingToday <= 0) {
      final overBy = remainingToday.abs();
      message = 'You\'ve reached your goal. Over by ${overBy.toStringAsFixed(0)} kcal. '
          'Consider light activities or wait until tomorrow.';
    } else if (nextEatTime != null) {
      final waitMinutes = nextEatTime.difference(now).inMinutes;
      message = 'Wait ${waitMinutes} min, then eat ~${suggestedNextMealCalories.toStringAsFixed(0)} kcal. '
          '${suggestedRemainingMeals} meals remaining.';
    } else {
      message = 'You can eat now. Suggested: ~${suggestedNextMealCalories.toStringAsFixed(0)} kcal. '
          '${remainingHours.toStringAsFixed(1)}h remaining in eating window.';
    }

    return PacingRecommendation(
      nextEatTime: nextEatTime,
      suggestedNextMealCalories: suggestedNextMealCalories,
      remainingHours: remainingHours,
      suggestedRemainingMeals: suggestedRemainingMeals,
      caloriesPerRemainingHour: caloriesPerRemainingHour,
      message: message,
    );
  }
}