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

  /// Список всех записей (только для чтения)
  List<CalorieEntry> get entries => List.unmodifiable(_entries);

  /// Добавить запись о потреблении калорий
  void addEntry(CalorieEntry entry) {
    _entries.add(entry);
    _entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Добавить несколько записей
  void addEntries(Iterable<CalorieEntry> entries) {
    _entries.addAll(entries);
    _entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Удалить запись
  bool removeEntry(CalorieEntry entry) {
    return _entries.remove(entry);
  }

  /// Очистить все записи
  void clearEntries() {
    _entries.clear();
  }

  /// Рассчитывает вес записи на основе её давности
  ///
  /// Использует экспоненциальное затухание: weight = 0.5^(daysAgo / halfLife)
  double calculateDecayWeight(DateTime entryTime, DateTime now) {
    final hoursDiff = now.difference(entryTime).inMinutes / 60.0;
    final daysAgo = hoursDiff / 24.0;

    // Полностью игнорируем данные старше compensationDecayDays
    if (daysAgo > settings.compensationDecayDays) {
      return 0;
    }

    // Для будущих записей (не должно происходить, но на всякий случай)
    if (daysAgo < 0) {
      return 0;
    }

    // Экспоненциальное затухание
    final halfLife = settings.historyDecayHalfLife;
    return math.pow(0.5, daysAgo / halfLife).toDouble();
  }

  /// Получает калории за определённый период
  double getCaloriesInRange(DateTime start, DateTime end) {
    return _entries
        .where((e) =>
    !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end))
        .fold(0.0, (sum, e) => sum + e.calories);
  }

  /// Получает записи за определённый период
  List<CalorieEntry> getEntriesInRange(DateTime start, DateTime end) {
    return _entries
        .where((e) =>
    !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end))
        .toList();
  }

  /// Рассчитывает "долг" калорий — взвешенную сумму превышений
  ///
  /// Анализирует скользящие окна за последние [compensationDecayDays] дней
  double calculateCalorieDebt(DateTime now) {
    final targetDaily = settings.targetDailyCalories;
    final decayDays = settings.compensationDecayDays;
    final windowHours = settings.windowHours;

    double totalWeightedExcess = 0;

    // Анализируем каждый день в периоде затухания
    for (int dayOffset = 1; dayOffset <= decayDays; dayOffset++) {
      // Конец окна — начало текущего дня минус (dayOffset - 1) дней
      final windowEnd = now.subtract(Duration(hours: (dayOffset - 1) * 24));
      final windowStart =
      windowEnd.subtract(Duration(hours: windowHours.toInt()));

      final windowCalories = getCaloriesInRange(windowStart, windowEnd);
      final excess = math.max(0.0, windowCalories - targetDaily);

      if (excess > 0) {
        // Вес основан на середине окна
        final windowMid = windowStart.add(
          Duration(hours: (windowHours / 2).toInt()),
        );
        final weight = calculateDecayWeight(windowMid, now);
        totalWeightedExcess += excess * weight;
      }
    }

    return totalWeightedExcess;
  }

  /// Рассчитывает скорректированную цель на текущий период
  double calculateAdjustedTarget(DateTime now) {
    final targetDaily = settings.targetDailyCalories;
    final compensationRate = settings.compensationRate;
    final maxCompensation = settings.maxCompensationPerDay;
    final minDaily = settings.minDailyCalories;
    final maxDaily = settings.maxDailyCalories;

    final debt = calculateCalorieDebt(now);

    // Сколько нужно компенсировать сегодня
    final compensation = math.min(debt * compensationRate, maxCompensation);

    // Применяем компенсацию с защитными ограничениями
    final adjusted = (targetDaily - compensation).clamp(minDaily, maxDaily);

    return adjusted.roundToDouble();
  }

  /// Рассчитывает компенсацию (снижение нормы)
  double calculateCompensation(DateTime now) {
    final debt = calculateCalorieDebt(now);
    final maxCompensation = settings.maxCompensationPerDay;
    return math.min(debt * settings.compensationRate, maxCompensation);
  }

  /// Проверяет скорость потребления (ккал/час) за последний час
  ConsumptionRateResult checkConsumptionRate(DateTime now) {
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final recentCalories = getCaloriesInRange(oneHourAgo, now);

    return ConsumptionRateResult(
      rate: recentCalories,
      isExcessive: recentCalories > settings.maxCaloriesPerHour,
    );
  }

  /// Находит последний приём пищи до указанного времени
  CalorieEntry? getLastMeal(DateTime now) {
    final beforeNow = _entries
        .where((e) => !e.timestamp.isAfter(now))
        .toList();

    if (beforeNow.isEmpty) return null;

    return beforeNow.last;
  }

  /// Подсчитывает количество приёмов пищи в окне
  ///
  /// Группирует близкие записи (в пределах [mealGroupingMinutes]) как один приём
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

  /// Оценивает количество часов с последнего приёма пищи
  double getHoursSinceLastMeal(DateTime now) {
    final lastMeal = getLastMeal(now);
    if (lastMeal == null) {
      return settings.maxFastingHours; // Если нет данных — считаем что давно не ели
    }

    return now.difference(lastMeal.timestamp).inMinutes / 60.0;
  }

  /// Оценивает количество оставшихся приёмов пищи на день
  int estimateRemainingMeals(DateTime now) {
    final hoursLeft = _estimateActiveHoursLeft(now);
    final mealsAlready = getMealsInWindow(now);
    final idealMeals = settings.idealMealsPerDay;

    // Примерно 1 приём пищи каждые 4 часа активности
    final potentialMeals = (hoursLeft / 4).floor();
    return math.max(1, math.min(potentialMeals, idealMeals - mealsAlready));
  }

  /// Оценивает оставшиеся часы активности
  double _estimateActiveHoursLeft(DateTime now) {
    // Анализируем паттерн активности пользователя за последние дни
    final recentDays = 7;
    final avgActiveHours = _analyzeActivityPattern(now, recentDays);

    // Сколько часов уже прошло с первого приёма пищи сегодня
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

  /// Анализирует паттерн активности пользователя
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
      return 14; // Значение по умолчанию — 14 часов активности
    }

    // Среднее значение
    return activePeriods.reduce((a, b) => a + b) / activePeriods.length;
  }

  /// Рассчитывает рекомендацию для следующего приёма пищи
  MealSuggestion suggestNextMeal(DateTime now) {
    final minInterval = settings.minMealInterval;
    final maxFasting = settings.maxFastingHours;
    final variance = settings.mealSizeVariance;
    final windowHours = settings.windowHours;

    final adjustedTarget = calculateAdjustedTarget(now);

    // Сколько уже съедено за текущее "окно"
    final windowStart = now.subtract(Duration(hours: windowHours.toInt()));
    final consumed = getCaloriesInRange(windowStart, now);
    final remaining = math.max(0.0, adjustedTarget - consumed);

    // Сколько часов прошло с последней еды
    final hoursSinceLastMeal = getHoursSinceLastMeal(now);

    // Проверяем скорость потребления
    final consumptionCheck = checkConsumptionRate(now);

    DateTime suggestedTime;
    String reason;

    if (consumptionCheck.isExcessive) {
      // Слишком быстрое потребление — увеличиваем паузу
      final excess = consumptionCheck.rate - settings.maxCaloriesPerHour;
      final extraPause = (excess / 200).ceil(); // +1 час за каждые 200 ккал
      final pauseHours = math.min(minInterval + extraPause, maxFasting);

      suggestedTime = now.add(Duration(hours: pauseHours.toInt()));
      reason =
      'Рекомендуется пауза ${pauseHours.toStringAsFixed(1)} ч после большого приёма пищи';
    } else if (hoursSinceLastMeal < minInterval) {
      // Слишком рано для следующего приёма
      final waitHours = minInterval - hoursSinceLastMeal;
      suggestedTime = now.add(Duration(minutes: (waitHours * 60).toInt()));
      reason = 'Минимальный интервал между приёмами пищи';
    } else if (hoursSinceLastMeal >= maxFasting) {
      // Пора есть!
      suggestedTime = now;
      reason =
      'Прошло ${hoursSinceLastMeal.toStringAsFixed(1)} ч — пора поесть';
    } else {
      // Нормальный режим — распределяем равномерно
      final mealsInWindow = getMealsInWindow(now);
      final remainingMealsTarget =
      math.max(1, settings.idealMealsPerDay - mealsInWindow);

      // Оптимальный интервал до следующего приёма
      final activeHoursLeft = _estimateActiveHoursLeft(now);
      final optimalInterval = activeHoursLeft / remainingMealsTarget;
      final nextInterval = math.max(0.0, optimalInterval);

      suggestedTime = now.add(Duration(minutes: (nextInterval * 60).toInt()));
      reason = 'Оптимальное распределение калорий';
    }

    // Рассчитываем размер порции
    final remainingMeals = estimateRemainingMeals(now);
    final avgMealSize = remaining / remainingMeals;

    // Применяем ограничения и вариативность
    final minCalories = math.max(100.0, avgMealSize * (1 - variance));
    final maxCalories = math.min(
      settings.maxCaloriesPerMeal,
      avgMealSize * (1 + variance),
    );
    final suggestedCalories = avgMealSize.clamp(minCalories, maxCalories);

    return MealSuggestion(
      suggestedTime: suggestedTime,
      suggestedCalories: suggestedCalories.roundToDouble(),
      minCalories: minCalories.roundToDouble(),
      maxCalories: maxCalories.roundToDouble(),
      reason: reason,
    );
  }

  /// Генерирует предупреждения
  List<Warning> generateWarnings(DateTime now) {
    final warnings = <Warning>[];
    final windowHours = settings.windowHours;

    // Проверка скорости потребления
    final consumptionCheck = checkConsumptionRate(now);
    if (consumptionCheck.isExcessive) {
      warnings.add(Warning(
        type: WarningType.rapidConsumption,
        message:
        'Высокая скорость потребления: ${consumptionCheck.rate.toStringAsFixed(0)} ккал/час. '
            'Рекомендуется сделать паузу.',
        severity: WarningSeverity.warning,
      ));
    }

    // Проверка долга калорий
    final debt = calculateCalorieDebt(now);
    if (debt > 500) {
      final severity =
      debt > 1000 ? WarningSeverity.warning : WarningSeverity.info;
      final adjustedTarget = calculateAdjustedTarget(now);
      warnings.add(Warning(
        type: WarningType.debt,
        message:
        'Накопленное превышение: ${debt.toStringAsFixed(0)} ккал. '
            'Цель снижена до ${adjustedTarget.toStringAsFixed(0)} ккал.',
        severity: severity,
      ));
    }

    // Проверка голодания
    final hoursSinceLastMeal = getHoursSinceLastMeal(now);
    final maxFasting = settings.maxFastingHours;

    if (hoursSinceLastMeal > maxFasting) {
      final severity = hoursSinceLastMeal > maxFasting * 1.5
          ? WarningSeverity.critical
          : WarningSeverity.warning;
      warnings.add(Warning(
        type: WarningType.fasting,
        message:
        'Прошло ${hoursSinceLastMeal.toStringAsFixed(1)} часов с последнего приёма пищи. '
            'Пора поесть!',
        severity: severity,
      ));
    }

    // Проверка превышения нормы за текущее окно
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
        'Превышение нормы на ${excess.toStringAsFixed(0)} ккал за последние '
            '${windowHours.toStringAsFixed(0)} часов.',
        severity: severity,
      ));
    }

    // Проверка слишком низкого потребления
    if (consumed > 0 && consumed < settings.minDailyCalories * 0.5) {
      final hoursInWindow = math.min(
        hoursSinceLastMeal,
        windowHours,
      );
      // Предупреждаем только если прошло достаточно времени
      if (hoursInWindow > 12) {
        warnings.add(Warning(
          type: WarningType.belowMinimum,
          message:
          'Потреблено всего ${consumed.toStringAsFixed(0)} ккал. '
              'Не забывайте есть регулярно.',
          severity: WarningSeverity.info,
        ));
      }
    }

    return warnings;
  }

  /// Главный метод — получить полную рекомендацию
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

  /// Симулирует добавление калорий и возвращает результат
  ///
  /// Полезно для предварительного просмотра эффекта от приёма пищи
  DailyRecommendation simulateEntry(
      double calories, {
        DateTime? timestamp,
        DateTime? evaluationTime,
      }) {
    final entryTime = timestamp ?? DateTime.now();
    final evalTime = evaluationTime ?? entryTime;

    // Создаём временную копию
    final tempEntries = List<CalorieEntry>.from(_entries);
    tempEntries.add(CalorieEntry(timestamp: entryTime, calories: calories));

    // Временно заменяем записи
    final backup = List<CalorieEntry>.from(_entries);
    _entries
      ..clear()
      ..addAll(tempEntries);

    try {
      return getRecommendation(evalTime);
    } finally {
      // Восстанавливаем оригинальные записи
      _entries
        ..clear()
        ..addAll(backup);
    }
  }

  /// Получить статистику за период
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

    // Группируем по дням для статистики
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

    // Подсчёт приёмов пищи (группировка)
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