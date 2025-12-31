import 'dart:math' as math;
import 'models.dart';

class ConsumptionRateResult {
  final double rate;
  final bool isExcessive;

  const ConsumptionRateResult({
    required this.rate,
    required this.isExcessive,
  });
}

class CalorieStabilizer {
  final StabilizerSettings settings;
  final List<CalorieEntry> _entries = [];

  CalorieStabilizer({
    StabilizerSettings? settings,
  }) : settings = settings ?? const StabilizerSettings();

  /// List of all entries (read-only)
  List<CalorieEntry> get entries => List.unmodifiable(_entries);

  /// Add a calorie consumption entry
  void addEntry(CalorieEntry entry) {
    _entries.add(entry);
    _entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Add multiple entries
  void addEntries(Iterable<CalorieEntry> entries) {
    _entries.addAll(entries);
    _entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Remove an entry
  bool removeEntry(CalorieEntry entry) {
    return _entries.remove(entry);
  }

  /// Clear all entries
  void clearEntries() {
    _entries.clear();
  }

  /// Calculates the weight of an entry based on its age
  ///
  /// Uses exponential decay: weight = 0.5^(daysAgo / halfLife)
  double calculateDecayWeight(DateTime entryTime, DateTime now) {
    final hoursDiff = now.difference(entryTime).inMinutes / 60.0;
    final daysAgo = hoursDiff / 24.0;

    // Completely ignore data older than compensationDecayDays
    if (daysAgo > settings.compensationDecayDays) {
      return 0;
    }

    // For future entries (shouldn't happen, but just in case)
    if (daysAgo < 0) {
      return 0;
    }

    // Exponential decay
    final halfLife = settings.historyDecayHalfLife;
    return math.pow(0.5, daysAgo / halfLife).toDouble();
  }

  /// Gets calories for a specific period
  double getCaloriesInRange(DateTime start, DateTime end) {
    return _entries
        .where((e) =>
    !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end))
        .fold(0.0, (sum, e) => sum + e.calories);
  }

  /// Gets entries for a specific period
  List<CalorieEntry> getEntriesInRange(DateTime start, DateTime end) {
    return _entries
        .where((e) =>
    !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end))
        .toList();
  }

  /// Calculates calorie "debt" — weighted sum of excesses
  ///
  /// Analyzes sliding windows for the last [compensationDecayDays] days
  double calculateCalorieDebt(DateTime now) {
    final targetDaily = settings.targetDailyCalories;
    final decayDays = settings.compensationDecayDays;
    final windowHours = settings.windowHours;

    double totalWeightedExcess = 0;

    // Analyze each day in the decay period
    for (int dayOffset = 1; dayOffset <= decayDays; dayOffset++) {
      // Window end — start of current day minus (dayOffset - 1) days
      final windowEnd = now.subtract(Duration(hours: (dayOffset - 1) * 24));
      final windowStart =
      windowEnd.subtract(Duration(hours: windowHours.toInt()));

      final windowCalories = getCaloriesInRange(windowStart, windowEnd);
      final excess = math.max(0.0, windowCalories - targetDaily);

      if (excess > 0) {
        // Weight is based on the middle of the window
        final windowMid = windowStart.add(
          Duration(hours: (windowHours / 2).toInt()),
        );
        final weight = calculateDecayWeight(windowMid, now);
        totalWeightedExcess += excess * weight;
      }
    }

    return totalWeightedExcess;
  }

  /// Calculates adjusted target for the current period
  double calculateAdjustedTarget(DateTime now) {
    final targetDaily = settings.targetDailyCalories;
    final compensationRate = settings.compensationRate;
    final maxCompensation = settings.maxCompensationPerDay;
    final minDaily = settings.minDailyCalories;
    final maxDaily = settings.maxDailyCalories;

    final debt = calculateCalorieDebt(now);

    // How much needs to be compensated today
    final compensation = math.min(debt * compensationRate, maxCompensation);

    // Apply compensation with protective limits
    final adjusted = (targetDaily - compensation).clamp(minDaily, maxDaily);

    return adjusted.roundToDouble();
  }

  /// Calculates compensation (target reduction)
  double calculateCompensation(DateTime now) {
    final debt = calculateCalorieDebt(now);
    final maxCompensation = settings.maxCompensationPerDay;
    return math.min(debt * settings.compensationRate, maxCompensation);
  }

  /// Checks consumption rate (kcal/hour) for the last hour
  ConsumptionRateResult checkConsumptionRate(DateTime now) {
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final recentCalories = getCaloriesInRange(oneHourAgo, now);

    return ConsumptionRateResult(
      rate: recentCalories,
      isExcessive: recentCalories > settings.maxCaloriesPerHour,
    );
  }

  /// Finds the last meal before the specified time
  CalorieEntry? getLastMeal(DateTime now) {
    final beforeNow = _entries
        .where((e) => !e.timestamp.isAfter(now))
        .toList();

    if (beforeNow.isEmpty) return null;

    return beforeNow.last;
  }

  /// Counts the number of meals in the window
  ///
  /// Groups close entries (within [mealGroupingMinutes]) as one meal
  int getMealsInWindow(DateTime now) {
    final windowStart =
    now.subtract(Duration(hours: settings.windowHours.toInt()));

    final mealsInWindow = getEntriesInRange(windowStart, now);
    if (mealsInWindow.isEmpty) return 0;

    int mealCount = 0;
    DateTime? lastMealTime;
    final groupingDuration =
    Duration(minutes: settings.mealGroupingMinutes);

    for (final entry in mealsInWindow) {
      if (lastMealTime == null ||
          entry.timestamp.difference(lastMealTime) > groupingDuration) {
        mealCount++;
        lastMealTime = entry.timestamp;
      }
    }

    return mealCount;
  }

  /// Estimates hours since last meal
  double getHoursSinceLastMeal(DateTime now) {
    final lastMeal = getLastMeal(now);
    if (lastMeal == null) {
      return settings.maxFastingHours; // If no data — assume it's been a long time since eating
    }

    return now.difference(lastMeal.timestamp).inMinutes / 60.0;
  }

  /// Estimates remaining meals for the day
  int estimateRemainingMeals(DateTime now) {
    final hoursLeft = _estimateActiveHoursLeft(now);
    final mealsAlready = getMealsInWindow(now);
    final idealMeals = settings.idealMealsPerDay;

    // Approximately 1 meal every 4 hours of activity
    final potentialMeals = (hoursLeft / 4).floor();
    return math.max(1, math.min(potentialMeals, idealMeals - mealsAlready));
  }

  /// Estimates remaining active hours
  double _estimateActiveHoursLeft(DateTime now) {
    // Analyze user activity pattern for recent days
    final recentDays = 7;
    final avgActiveHours = _analyzeActivityPattern(now, recentDays);

    // How many hours have passed since the first meal today
    final windowStart =
    now.subtract(Duration(hours: settings.windowHours.toInt()));
    final todayEntries = getEntriesInRange(windowStart, now);

    if (todayEntries.isEmpty) {
      return avgActiveHours;
    }

    final firstMealToday = todayEntries.first.timestamp;
    final hoursSinceFirst = now.difference(firstMealToday).inMinutes / 60.0;

    return math.max(2, avgActiveHours - hoursSinceFirst);
  }

  /// Analyzes user activity pattern
  double _analyzeActivityPattern(DateTime now, int days) {
    final List<double> activePeriods = [];

    for (int i = 1; i <= days; i++) {
      final dayEnd = now.subtract(Duration(days: i - 1));
      final dayStart = dayEnd.subtract(const Duration(hours: 24));
      final dayEntries = getEntriesInRange(dayStart, dayEnd);

      if (dayEntries.length >= 2) {
        final first = dayEntries.first.timestamp;
        final last = dayEntries.last.timestamp;
        final activeHours = last.difference(first).inMinutes / 60.0;
        if (activeHours > 0) {
          activePeriods.add(activeHours);
        }
      }
    }

    if (activePeriods.isEmpty) {
      return 14; // Default value — 14 hours of activity
    }

    // Average value
    return activePeriods.reduce((a, b) => a + b) / activePeriods.length;
  }

  /// Calculates recommendation for the next meal
  MealSuggestion suggestNextMeal(DateTime now) {
    final minInterval = settings.minMealInterval;
    final maxFasting = settings.maxFastingHours;
    final variance = settings.mealSizeVariance;
    final windowHours = settings.windowHours;

    final adjustedTarget = calculateAdjustedTarget(now);

    // How much already eaten in the current "window"
    final windowStart = now.subtract(Duration(hours: windowHours.toInt()));
    final consumed = getCaloriesInRange(windowStart, now);
    final remaining = math.max(0.0, adjustedTarget - consumed);

    // How many hours since last meal
    final hoursSinceLastMeal = getHoursSinceLastMeal(now);

    // Check consumption rate
    final consumptionCheck = checkConsumptionRate(now);

    DateTime suggestedTime;
    String reason;

    if (consumptionCheck.isExcessive) {
      // Too fast consumption — increasing pause
      final excess = consumptionCheck.rate - settings.maxCaloriesPerHour;
      final extraPause = (excess / 200).ceil(); // +1 hour for every 200 kcal
      final pauseHours = math.min(minInterval + extraPause, maxFasting);

      suggestedTime = now.add(Duration(hours: pauseHours.toInt()));
      reason =
      'Recommended pause of ${pauseHours.toStringAsFixed(1)} h after a large meal';
    } else if (hoursSinceLastMeal < minInterval) {
      // Too early for the next meal
      final waitHours = minInterval - hoursSinceLastMeal;
      suggestedTime = now.add(Duration(minutes: (waitHours * 60).toInt()));
      reason = 'Minimum interval between meals';
    } else if (hoursSinceLastMeal >= maxFasting) {
      // Time to eat!
      suggestedTime = now;
      reason = '${hoursSinceLastMeal.toStringAsFixed(1)} h passed — time to eat';
    } else {
      final mealsInWindow = getMealsInWindow(now);
      final remainingMealsTarget =
      math.max(1, settings.idealMealsPerDay - mealsInWindow);

      final activeHoursLeft = _estimateActiveHoursLeft(now);
      final optimalInterval = activeHoursLeft / remainingMealsTarget;
      final nextInterval = math.max(0.0, optimalInterval);

      suggestedTime = now.add(Duration(minutes: (nextInterval * 60).toInt()));
      reason = 'Optimal calorie distribution';
    }

    // Calculate portion size
    final remainingMeals = estimateRemainingMeals(now);
    final avgMealSize = remaining / remainingMeals;

    final rawMinCalories = math.max(100.0, avgMealSize * (1 - variance));
    final rawMaxCalories = math.min(
      settings.maxCaloriesPerMeal,
      avgMealSize * (1 + variance),
    );

    final minCalories = math.min(rawMinCalories, rawMaxCalories);
    final maxCalories = math.max(rawMinCalories, rawMaxCalories);

    final safeMealSize = avgMealSize > 0 ? avgMealSize : 100.0;
    final suggestedCalories = safeMealSize.clamp(minCalories, maxCalories);

    return MealSuggestion(
      suggestedTime: suggestedTime,
      suggestedCalories: suggestedCalories.roundToDouble(),
      minCalories: minCalories.roundToDouble(),
      maxCalories: maxCalories.roundToDouble(),
      reason: reason,
    );
  }

  /// Generates warnings
  List<Warning> generateWarnings(DateTime now) {
    final warnings = <Warning>[];
    final windowHours = settings.windowHours;

    // Check consumption rate
    final consumptionCheck = checkConsumptionRate(now);
    if (consumptionCheck.isExcessive) {
      warnings.add(Warning(
        type: WarningType.rapidConsumption,
        message:
        'High consumption rate: ${consumptionCheck.rate.toStringAsFixed(0)} kcal/hour. '
            'A pause is recommended.',
        severity: WarningSeverity.warning,
      ));
    }

    // Check calorie debt
    final debt = calculateCalorieDebt(now);
    if (debt > 500) {
      final severity =
      debt > 1000 ? WarningSeverity.warning : WarningSeverity.info;
      final adjustedTarget = calculateAdjustedTarget(now);
      warnings.add(Warning(
        type: WarningType.debt,
        message:
        'Accumulated excess: ${debt.toStringAsFixed(0)} kcal. '
            'Target reduced to ${adjustedTarget.toStringAsFixed(0)} kcal.',
        severity: severity,
      ));
    }

    // Check fasting
    final hoursSinceLastMeal = getHoursSinceLastMeal(now);
    final maxFasting = settings.maxFastingHours;

    if (hoursSinceLastMeal > maxFasting) {
      final severity = hoursSinceLastMeal > maxFasting * 1.5
          ? WarningSeverity.critical
          : WarningSeverity.warning;
      warnings.add(Warning(
        type: WarningType.fasting,
        message:
        '${hoursSinceLastMeal.toStringAsFixed(1)} hours since last meal. '
            'Time to eat!',
        severity: severity,
      ));
    }

    // Check target excess for current window
    final windowStart = now.subtract(Duration(hours: windowHours.toInt()));
    final consumed = getCaloriesInRange(windowStart, now);
    final adjustedTarget = calculateAdjustedTarget(now);

    if (consumed > adjustedTarget) {
      final excess = consumed - adjustedTarget;
      final severity =
      excess > 500 ? WarningSeverity.warning : WarningSeverity.info;
      warnings.add(Warning(
        type: WarningType.overeating,
        message:
        'Exceeded target by ${excess.toStringAsFixed(0)} kcal in the last '
            '${windowHours.toStringAsFixed(0)} hours.',
        severity: severity,
      ));
    }

    // Check too low consumption
    if (consumed > 0 && consumed < settings.minDailyCalories * 0.5) {
      final hoursInWindow = math.min(
        hoursSinceLastMeal,
        windowHours,
      );
      // Warn only if enough time has passed
      if (hoursInWindow > 12) {
        warnings.add(Warning(
          type: WarningType.belowMinimum,
          message:
          'Only ${consumed.toStringAsFixed(0)} kcal consumed. '
              'Don\'t forget to eat regularly.',
          severity: WarningSeverity.info,
        ));
      }
    }

    return warnings;
  }

  /// Main method — get full recommendation
  DailyRecommendation getRecommendation([DateTime? now]) {
    final currentTime = now ?? DateTime.now();
    final windowHours = settings.windowHours;

    final adjustedTarget = calculateAdjustedTarget(currentTime);
    final windowStart =
    currentTime.subtract(Duration(hours: windowHours.toInt()));
    final consumed = getCaloriesInRange(windowStart, currentTime);
    final compensation = calculateCompensation(currentTime);

    return DailyRecommendation(
      adjustedTarget: adjustedTarget,
      consumed: consumed,
      remaining: math.max(0, adjustedTarget - consumed),
      nextMeal: suggestNextMeal(currentTime),
      warnings: generateWarnings(currentTime),
      calorieDebt: calculateCalorieDebt(currentTime),
      baseTarget: settings.targetDailyCalories,
      compensation: compensation,
    );
  }

  /// Simulates adding calories and returns the result
  ///
  /// Useful for previewing the effect of a meal
  DailyRecommendation simulateEntry(
      double calories, {
        DateTime? timestamp,
        DateTime? evaluationTime,
      }) {
    final entryTime = timestamp ?? DateTime.now();
    final evalTime = evaluationTime ?? entryTime;

    // Create a temporary copy
    final tempEntries = List<CalorieEntry>.from(_entries);
    tempEntries.add(CalorieEntry(timestamp: entryTime, calories: calories));

    // Temporarily replace entries
    final backup = List<CalorieEntry>.from(_entries);
    _entries
      ..clear()
      ..addAll(tempEntries);

    try {
      return getRecommendation(evalTime);
    } finally {
      // Restore original entries
      _entries
        ..clear()
        ..addAll(backup);
    }
  }

  /// Get statistics for period
  Map<String, dynamic> getStatistics(DateTime start, DateTime end) {
    final entries = getEntriesInRange(start, end);
    if (entries.isEmpty) {
      return {
        'totalCalories': 0.0,
        'avgDailyCalories': 0.0,
        'totalMeals': 0,
        'avgMealSize': 0.0,
        'maxDayCalories': 0.0,
        'minDayCalories': 0.0,
        'daysTracked': 0,
      };
    }

    final totalCalories = entries.fold(0.0, (sum, e) => sum + e.calories);
    final days = end.difference(start).inDays.clamp(1, 365);

    // Group by days for statistics
    final dayCalories = <String, double>{};
    for (final entry in entries) {
      final dayKey =
          '${entry.timestamp.year}-${entry.timestamp.month}-${entry.timestamp.day}';
      dayCalories[dayKey] = (dayCalories[dayKey] ?? 0) + entry.calories;
    }

    final dailyValues = dayCalories.values.toList();
    final maxDay = dailyValues.isEmpty
        ? 0.0
        : dailyValues.reduce((a, b) => a > b ? a : b);
    final minDay = dailyValues.isEmpty
        ? 0.0
        : dailyValues.reduce((a, b) => a < b ? a : b);

    // Meal count (grouping)
    int totalMeals = 0;
    DateTime? lastMealTime;
    for (final entry in entries) {
      if (lastMealTime == null ||
          entry.timestamp.difference(lastMealTime).inMinutes >
              settings.mealGroupingMinutes) {
        totalMeals++;
        lastMealTime = entry.timestamp;
      }
    }

    return {
      'totalCalories': totalCalories,
      'avgDailyCalories': totalCalories / days,
      'totalMeals': totalMeals,
      'avgMealSize': totalMeals > 0 ? totalCalories / totalMeals : 0.0,
      'maxDayCalories': maxDay,
      'minDayCalories': minDay,
      'daysTracked': dayCalories.length,
    };
  }
}