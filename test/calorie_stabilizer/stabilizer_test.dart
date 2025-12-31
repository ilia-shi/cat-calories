import 'package:cat_calories/calorie_stabilizer/calorie_stabilizer.dart';
import 'package:cat_calories/calorie_stabilizer/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalorieStabilizer - Basic Operations', () {
    late CalorieStabilizer stabilizer;

    setUp(() {
      stabilizer = CalorieStabilizer();
    });

    test('starts with empty entries', () {
      expect(stabilizer.entries, isEmpty);
    });

    test('adds single entry', () {
      final entry = CalorieEntry(
        timestamp: DateTime.now(),
        calories: 500,
      );
      stabilizer.addEntry(entry);

      expect(stabilizer.entries.length, equals(1));
      expect(stabilizer.entries.first, equals(entry));
    });

    test('adds multiple entries and sorts by timestamp', () {
      final now = DateTime.now();
      final entry1 = CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 1)),
        calories: 300,
      );
      final entry2 = CalorieEntry(
        timestamp: now,
        calories: 500,
      );
      final entry3 = CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 2)),
        calories: 200,
      );

      stabilizer.addEntries([entry1, entry2, entry3]);

      expect(stabilizer.entries.length, equals(3));
      expect(stabilizer.entries[0].calories, equals(200)); // oldest first
      expect(stabilizer.entries[2].calories, equals(500)); // newest last
    });

    test('removes entry', () {
      final entry = CalorieEntry(
        timestamp: DateTime.now(),
        calories: 500,
      );
      stabilizer.addEntry(entry);
      expect(stabilizer.entries.length, equals(1));

      final removed = stabilizer.removeEntry(entry);
      expect(removed, isTrue);
      expect(stabilizer.entries, isEmpty);
    });

    test('clears all entries', () {
      stabilizer.addEntries([
        CalorieEntry(timestamp: DateTime.now(), calories: 300),
        CalorieEntry(timestamp: DateTime.now(), calories: 500),
      ]);
      expect(stabilizer.entries.length, equals(2));

      stabilizer.clearEntries();
      expect(stabilizer.entries, isEmpty);
    });
  });

  group('CalorieStabilizer - Calories in Range', () {
    late CalorieStabilizer stabilizer;
    late DateTime baseTime;

    setUp(() {
      stabilizer = CalorieStabilizer();
      baseTime = DateTime(2025, 6, 3, 0, 0); // 3 июня 00:00
    });

    test('calculates calories in range correctly', () {
      // Добавляем записи за 1 июня
      final june1 = DateTime(2025, 6, 1);
      stabilizer.addEntries([
        CalorieEntry(timestamp: june1.add(const Duration(hours: 9)), calories: 500),
        CalorieEntry(timestamp: june1.add(const Duration(hours: 14)), calories: 500),
        CalorieEntry(timestamp: june1.add(const Duration(hours: 19)), calories: 400),
      ]);

      final dayStart = DateTime(2025, 6, 1, 0, 0);
      final dayEnd = DateTime(2025, 6, 1, 23, 59);

      expect(stabilizer.getCaloriesInRange(dayStart, dayEnd), equals(1400));
    });

    test('returns zero for empty range', () {
      expect(
        stabilizer.getCaloriesInRange(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 2),
        ),
        equals(0),
      );
    });

    test('includes boundary timestamps', () {
      final time = DateTime(2025, 6, 1, 12, 0);
      stabilizer.addEntry(CalorieEntry(timestamp: time, calories: 500));

      expect(stabilizer.getCaloriesInRange(time, time), equals(500));
    });


  });

  group('CalorieStabilizer - Decay Weight', () {
    late CalorieStabilizer stabilizer;

    setUp(() {
      stabilizer = CalorieStabilizer(
        settings: const StabilizerSettings(
          historyDecayHalfLife: 3,
          compensationDecayDays: 7,
        ),
      );
    });



    test('current time has weight 1.0', () {
      final now = DateTime.now();
      expect(stabilizer.calculateDecayWeight(now, now), equals(1.0));
    });

    test('weight decreases with time', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      final weightYesterday = stabilizer.calculateDecayWeight(yesterday, now);
      final weightTwoDays = stabilizer.calculateDecayWeight(twoDaysAgo, now);

      expect(weightYesterday, lessThan(1.0));
      expect(weightTwoDays, lessThan(weightYesterday));
    });

    test('weight at half-life is approximately 0.5', () {
      final now = DateTime.now();
      final halfLife = now.subtract(const Duration(days: 3));

      final weight = stabilizer.calculateDecayWeight(halfLife, now);
      expect(weight, closeTo(0.5, 0.01));
    });

    test('weight beyond decay period is 0', () {
      final now = DateTime.now();
      final tooOld = now.subtract(const Duration(days: 10));

      expect(stabilizer.calculateDecayWeight(tooOld, now), equals(0));
    });

    test('future timestamps have weight 0', () {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 1));

      expect(stabilizer.calculateDecayWeight(future, now), equals(0));
    });
  });

  group('CalorieStabilizer - Calorie Debt', () {
    late CalorieStabilizer stabilizer;
    late DateTime now;

    setUp(() {
      stabilizer = CalorieStabilizer(
        settings: const StabilizerSettings(
          targetDailyCalories: 2000,
          historyDecayHalfLife: 3,
          compensationDecayDays: 7,
        ),
      );
      now = DateTime(2025, 6, 3, 0, 0);
    });

    test('no debt with no entries', () {
      expect(stabilizer.calculateCalorieDebt(now), equals(0));
    });

    test('no debt when within target', () {
      final yesterday = DateTime(2025, 6, 2, 12, 0);
      stabilizer.addEntry(CalorieEntry(timestamp: yesterday, calories: 1500));

      expect(stabilizer.calculateCalorieDebt(now), equals(0));
    });

    test('calculates debt for excess calories', () {
      // День с превышением на 500 ккал
      final yesterday = DateTime(2025, 6, 2, 12, 0);
      stabilizer.addEntry(CalorieEntry(timestamp: yesterday, calories: 2500));

      final debt = stabilizer.calculateCalorieDebt(now);
      expect(debt, greaterThan(0));
      // Долг должен быть меньше 500 из-за затухания
      expect(debt, lessThan(500));
    });

    test('debt decreases over time due to decay', () {
      final twoDaysAgo = DateTime(2025, 6, 1, 12, 0);
      stabilizer.addEntry(CalorieEntry(timestamp: twoDaysAgo, calories: 3000));

      final debtNow = stabilizer.calculateCalorieDebt(now);

      // Проверяем через день
      final debtTomorrow = stabilizer.calculateCalorieDebt(
        now.add(const Duration(days: 1)),
      );

      expect(debtTomorrow, lessThan(debtNow));
    });
  });

  group('CalorieStabilizer - Adjusted Target', () {
    late CalorieStabilizer stabilizer;
    late DateTime now;

    setUp(() {
      stabilizer = CalorieStabilizer(
        settings: const StabilizerSettings(
          targetDailyCalories: 2000,
          compensationRate: 0.5,
          maxCompensationPerDay: 300,
          minDailyCalories: 1200,
          maxDailyCalories: 3000,
        ),
      );
      now = DateTime(2025, 6, 3, 0, 0);
    });

    test('target equals base when no debt', () {
      expect(stabilizer.calculateAdjustedTarget(now), equals(2000));
    });

    test('target reduced with debt', () {
      final yesterday = DateTime(2025, 6, 2, 12, 0);
      stabilizer.addEntry(CalorieEntry(timestamp: yesterday, calories: 2800));

      final adjusted = stabilizer.calculateAdjustedTarget(now);
      expect(adjusted, lessThan(2000));
    });

    test('target not below minimum', () {
      // Огромное превышение
      final yesterday = DateTime(2025, 6, 2, 12, 0);
      stabilizer.addEntry(CalorieEntry(timestamp: yesterday, calories: 10000));

      final adjusted = stabilizer.calculateAdjustedTarget(now);
      expect(adjusted, greaterThanOrEqualTo(1200));
    });

    test('compensation limited by maxCompensationPerDay', () {
      final yesterday = DateTime(2025, 6, 2, 12, 0);
      stabilizer.addEntry(CalorieEntry(timestamp: yesterday, calories: 5000));

      final adjusted = stabilizer.calculateAdjustedTarget(now);
      // Максимальное снижение = 300, значит минимум 1700
      expect(adjusted, greaterThanOrEqualTo(1700));
    });
  });

  group('CalorieStabilizer - Consumption Rate', () {
    late CalorieStabilizer stabilizer;
    late DateTime now;

    setUp(() {
      stabilizer = CalorieStabilizer(
        settings: const StabilizerSettings(maxCaloriesPerHour: 800),
      );
      now = DateTime(2025, 6, 3, 12, 0);
    });

    test('rate is 0 with no recent entries', () {
      final result = stabilizer.checkConsumptionRate(now);
      expect(result.rate, equals(0));
      expect(result.isExcessive, isFalse);
    });

    test('calculates rate for entries within last hour', () {
      stabilizer.addEntries([
        CalorieEntry(
          timestamp: now.subtract(const Duration(minutes: 30)),
          calories: 300,
        ),
        CalorieEntry(
          timestamp: now.subtract(const Duration(minutes: 10)),
          calories: 200,
        ),
      ]);

      final result = stabilizer.checkConsumptionRate(now);
      expect(result.rate, equals(500));
      expect(result.isExcessive, isFalse);
    });

    test('detects excessive consumption', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(minutes: 15)),
        calories: 1000,
      ));

      final result = stabilizer.checkConsumptionRate(now);
      expect(result.rate, equals(1000));
      expect(result.isExcessive, isTrue);
    });

    test('ignores entries older than 1 hour', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 2)),
        calories: 1000,
      ));

      final result = stabilizer.checkConsumptionRate(now);
      expect(result.rate, equals(0));
    });
  });

  group('CalorieStabilizer - Last Meal', () {
    late CalorieStabilizer stabilizer;
    late DateTime now;

    setUp(() {
      stabilizer = CalorieStabilizer();
      now = DateTime(2025, 6, 3, 12, 0);
    });

    test('returns null with no entries', () {
      expect(stabilizer.getLastMeal(now), isNull);
    });

    test('returns most recent entry', () {
      final older = CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 2)),
        calories: 300,
      );
      final recent = CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 1)),
        calories: 500,
      );

      stabilizer.addEntries([older, recent]);

      expect(stabilizer.getLastMeal(now), equals(recent));
    });

    test('ignores future entries', () {
      final past = CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 1)),
        calories: 300,
      );
      final future = CalorieEntry(
        timestamp: now.add(const Duration(hours: 1)),
        calories: 500,
      );

      stabilizer.addEntries([past, future]);

      expect(stabilizer.getLastMeal(now), equals(past));
    });
  });

  group('CalorieStabilizer - Meals in Window', () {
    late CalorieStabilizer stabilizer;
    late DateTime now;

    setUp(() {
      stabilizer = CalorieStabilizer(
        settings: const StabilizerSettings(
          windowHours: 24,
          mealGroupingMinutes: 30,
        ),
      );
      now = DateTime(2025, 6, 3, 12, 0);
    });

    test('returns 0 with no entries', () {
      expect(stabilizer.getMealsInWindow(now), equals(0));
    });

    test('counts single entry as one meal', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 2)),
        calories: 500,
      ));

      expect(stabilizer.getMealsInWindow(now), equals(1));
    });

    test('groups entries within 30 minutes as one meal', () {
      stabilizer.addEntries([
        CalorieEntry(
          timestamp: now.subtract(const Duration(hours: 2)),
          calories: 300,
        ),
        CalorieEntry(
          timestamp: now.subtract(const Duration(hours: 2)).add(const Duration(minutes: 10)),
          calories: 100,
        ),
        CalorieEntry(
          timestamp: now.subtract(const Duration(hours: 2)).add(const Duration(minutes: 20)),
          calories: 100,
        ),
      ]);

      expect(stabilizer.getMealsInWindow(now), equals(1));
    });

    test('counts separate meals correctly', () {
      // Завтрак
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 6)),
        calories: 500,
      ));
      // Обед
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 3)),
        calories: 700,
      ));
      // Ужин
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 1)),
        calories: 600,
      ));

      expect(stabilizer.getMealsInWindow(now), equals(3));
    });
  });

  group('CalorieStabilizer - Hours Since Last Meal', () {
    late CalorieStabilizer stabilizer;
    late DateTime now;

    setUp(() {
      stabilizer = CalorieStabilizer(
        settings: const StabilizerSettings(maxFastingHours: 8),
      );
      now = DateTime(2025, 6, 3, 12, 0);
    });

    test('returns maxFastingHours with no entries', () {
      expect(stabilizer.getHoursSinceLastMeal(now), equals(8));
    });

    test('calculates hours correctly', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 3)),
        calories: 500,
      ));

      expect(stabilizer.getHoursSinceLastMeal(now), closeTo(3.0, 0.01));
    });

    test('handles minutes correctly', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 2, minutes: 30)),
        calories: 500,
      ));

      expect(stabilizer.getHoursSinceLastMeal(now), closeTo(2.5, 0.01));
    });
  });

  group('CalorieStabilizer - Meal Suggestion', () {
    late CalorieStabilizer stabilizer;
    late DateTime now;

    setUp(() {
      stabilizer = CalorieStabilizer(
        settings: const StabilizerSettings(
          targetDailyCalories: 2000,
          minMealInterval: 2,
          maxFastingHours: 8,
          idealMealsPerDay: 4,
          maxCaloriesPerHour: 800,
        ),
      );
      now = DateTime(2025, 6, 3, 12, 0);
    });

    test('suggests meal now when fasting too long', () {
      // Нет записей = считается что давно не ели
      final suggestion = stabilizer.suggestNextMeal(now);

      expect(
        suggestion.suggestedTime.isBefore(now.add(const Duration(minutes: 1))),
        isTrue,
      );
      expect(suggestion.reason, contains('ч'));
    });

    test('suggests waiting after recent meal', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 1)),
        calories: 500,
      ));

      final suggestion = stabilizer.suggestNextMeal(now);

      expect(suggestion.suggestedTime.isAfter(now), isTrue);
      expect(suggestion.reason, contains('интервал'));
    });

    test('suggests pause after excessive consumption', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(minutes: 30)),
        calories: 1000,
      ));

      final suggestion = stabilizer.suggestNextMeal(now);

      expect(suggestion.suggestedTime.isAfter(now), isTrue);
      expect(suggestion.reason, contains('пауза'));
    });

    test('suggests appropriate calories', () {
      // Без записей, норма = 2000, ~4 приёма = ~500 каждый
      final suggestion = stabilizer.suggestNextMeal(now);

      expect(suggestion.suggestedCalories, greaterThan(0));
      expect(suggestion.minCalories, lessThanOrEqualTo(suggestion.suggestedCalories));
      expect(suggestion.maxCalories, greaterThanOrEqualTo(suggestion.suggestedCalories));
    });
  });

  group('CalorieStabilizer - Warnings', () {
    late CalorieStabilizer stabilizer;
    late DateTime now;

    setUp(() {
      stabilizer = CalorieStabilizer(
        settings: const StabilizerSettings(
          targetDailyCalories: 2000,
          maxCaloriesPerHour: 800,
          maxFastingHours: 8,
        ),
      );
      now = DateTime(2025, 6, 3, 12, 0);
    });

    test('no warnings in normal conditions', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 3)),
        calories: 500,
      ));

      final warnings = stabilizer.generateWarnings(now);
      expect(warnings, isEmpty);
    });

    test('warns about rapid consumption', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(minutes: 15)),
        calories: 1000,
      ));

      final warnings = stabilizer.generateWarnings(now);
      expect(
        warnings.any((w) => w.type == WarningType.rapidConsumption),
        isTrue,
      );
    });

    test('warns about fasting', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 10)),
        calories: 500,
      ));

      final warnings = stabilizer.generateWarnings(now);
      expect(
        warnings.any((w) => w.type == WarningType.fasting),
        isTrue,
      );
    });

    test('warns about calorie debt', () {
      final yesterday = now.subtract(const Duration(days: 1));
      stabilizer.addEntry(CalorieEntry(
        timestamp: yesterday,
        calories: 3500, // Превышение на 1500
      ));

      final warnings = stabilizer.generateWarnings(now);
      expect(
        warnings.any((w) => w.type == WarningType.debt),
        isTrue,
      );
    });

    test('warns about overeating', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 6)),
        calories: 2500,
      ));

      final warnings = stabilizer.generateWarnings(now);
      expect(
        warnings.any((w) => w.type == WarningType.overeating),
        isTrue,
      );
    });

    test('critical severity for long fasting', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 14)),
        calories: 500,
      ));

      final warnings = stabilizer.generateWarnings(now);
      final fastingWarning = warnings.firstWhere(
            (w) => w.type == WarningType.fasting,
      );
      expect(fastingWarning.severity, equals(WarningSeverity.critical));
    });
  });

  group('CalorieStabilizer - Full Recommendation', () {
    late CalorieStabilizer stabilizer;
    late DateTime now;

    setUp(() {
      stabilizer = CalorieStabilizer(
        settings: const StabilizerSettings(
          targetDailyCalories: 2000,
          windowHours: 24,
          compensationRate: 0.5,
          maxCompensationPerDay: 300,
        ),
      );
      now = DateTime(2025, 6, 3, 0, 0);
    });

    test('provides complete recommendation', () {
      final recommendation = stabilizer.getRecommendation(now);

      expect(recommendation.adjustedTarget, greaterThan(0));
      expect(recommendation.consumed, greaterThanOrEqualTo(0));
      expect(recommendation.remaining, greaterThanOrEqualTo(0));
      expect(recommendation.nextMeal, isNotNull);
      expect(recommendation.baseTarget, equals(2000));
    });

    test('recommendation reflects consumed calories', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 3)),
        calories: 800,
      ));

      final recommendation = stabilizer.getRecommendation(now);

      expect(recommendation.consumed, equals(800));
      expect(recommendation.remaining, equals(recommendation.adjustedTarget - 800));
    });

    // test('recommendation with example data (June 1-2)', () {
    //   // Данные из примера
    //   final june1 = DateTime(2025, 6, 1);
    //   final june2 = DateTime(2025, 6, 2);
    //
    //   // 1 июня - 2300 ккал
    //   stabilizer.addEntries([
    //     CalorieEntry(timestamp: june1.add(const Duration(hours: 9)), calories: 500),
    //     CalorieEntry(timestamp: june1.add(const Duration(hours: 9, minutes: 10)), calories: 100),
    //     CalorieEntry(timestamp: june1.add(const Duration(hours: 9, minutes: 11)), calories: 200),
    //     CalorieEntry(timestamp: june1.add(const Duration(hours: 14)), calories: 500),
    //     CalorieEntry(timestamp: june1.add(const Duration(hours: 14, minutes: 10)), calories: 100),
    //     CalorieEntry(timestamp: june1.add(const Duration(hours: 14, minutes: 11)), calories: 200),
    //     CalorieEntry(timestamp: june1.add(const Duration(hours: 19)), calories: 400),
    //     CalorieEntry(timestamp: june1.add(const Duration(hours: 19, minutes: 10)), calories: 100),
    //     CalorieEntry(timestamp: june1.add(const Duration(hours: 19, minutes: 11)), calories: 200),
    //   ]);
    //
    //   // 2 июня - 2500 ккал
    //   stabilizer.addEntries([
    //     CalorieEntry(timestamp: june2.add(const Duration(hours: 9)), calories: 500),
    //     CalorieEntry(timestamp: june2.add(const Duration(hours: 9, minutes: 10)), calories: 100),
    //     CalorieEntry(timestamp: june2.add(const Duration(hours: 9, minutes: 11)), calories: 200),
    //     CalorieEntry(timestamp: june2.add(const Duration(hours: 14)), calories: 500),
    //     CalorieEntry(timestamp: june2.add(const Duration(hours: 14, minutes: 10)), calories: 100),
    //     CalorieEntry(timestamp: june2.add(const Duration(hours: 14, minutes: 11)), calories: 200),
    //     CalorieEntry(timestamp: june2.add(const Duration(hours: 19)), calories: 400),
    //     CalorieEntry(timestamp: june2.add(const Duration(hours: 19, minutes: 10)), calories: 100),
    //     CalorieEntry(timestamp: june2.add(const Duration(hours: 23, minutes: 11)), calories: 400),
    //   ]);
    //
    //   final recommendation = stabilizer.getRecommendation(now);
    //
    //   // Должен быть долг
    //   expect(recommendation.calorieDebt, greaterThan(0));
    //   // Цель должна быть снижена
    //   expect(recommendation.adjustedTarget, lessThan(2000));
    //   // Но не ниже минимума
    //   expect(recommendation.adjustedTarget, greaterThanOrEqualTo(1200));
    //   // Должно быть предупреждение о долге
    //   expect(
    //     recommendation.warnings.any((w) => w.type == WarningType.debt),
    //     isTrue,
    //   );
    //
    //   print(recommendation);
    // });
  });

  group('CalorieStabilizer - Simulation', () {
    late CalorieStabilizer stabilizer;
    late DateTime now;

    setUp(() {
      stabilizer = CalorieStabilizer();
      now = DateTime(2025, 6, 3, 12, 0);
    });

    test('simulate does not modify actual entries', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 2)),
        calories: 500,
      ));

      final before = stabilizer.entries.length;
      stabilizer.simulateEntry(300, timestamp: now);
      final after = stabilizer.entries.length;

      expect(after, equals(before));
    });

    test('simulate shows effect of new entry', () {
      stabilizer.addEntry(CalorieEntry(
        timestamp: now.subtract(const Duration(hours: 2)),
        calories: 500,
      ));

      final beforeSim = stabilizer.getRecommendation(now);
      final simulated = stabilizer.simulateEntry(300, timestamp: now);

      expect(simulated.consumed, equals(beforeSim.consumed + 300));
      expect(simulated.remaining, lessThan(beforeSim.remaining));
    });
  });

  group('CalorieStabilizer - Statistics', () {
    late CalorieStabilizer stabilizer;

    setUp(() {
      stabilizer = CalorieStabilizer();
    });

    test('returns zeros for empty period', () {
      final stats = stabilizer.getStatistics(
        DateTime(2025, 6, 1),
        DateTime(2025, 6, 7),
      );

      expect(stats['totalCalories'], equals(0));
      expect(stats['avgDailyCalories'], equals(0));
      expect(stats['totalMeals'], equals(0));
    });

    test('calculates statistics correctly', () {
      final day1 = DateTime(2025, 6, 1, 12, 0);
      final day2 = DateTime(2025, 6, 2, 12, 0);
      final day3 = DateTime(2025, 6, 3, 12, 0);

      stabilizer.addEntries([
        CalorieEntry(timestamp: day1, calories: 2000),
        CalorieEntry(timestamp: day2, calories: 2200),
        CalorieEntry(timestamp: day3, calories: 1800),
      ]);

      final stats = stabilizer.getStatistics(
        DateTime(2025, 6, 1),
        DateTime(2025, 6, 4),
      );

      expect(stats['totalCalories'], equals(6000));
      expect(stats['avgDailyCalories'], equals(2000)); // 6000 / 3 days
      expect(stats['totalMeals'], equals(3));
      expect(stats['daysTracked'], equals(3));
      expect(stats['maxDayCalories'], equals(2200));
      expect(stats['minDayCalories'], equals(1800));
    });
  });

  group('CalorieStabilizer - Edge Cases', () {
    late CalorieStabilizer stabilizer;

    setUp(() {
      stabilizer = CalorieStabilizer();
    });

    test('handles very old entries correctly', () {
      final veryOld = DateTime(2020, 1, 1);
      stabilizer.addEntry(CalorieEntry(timestamp: veryOld, calories: 5000));

      final now = DateTime.now();
      final recommendation = stabilizer.getRecommendation(now);

      // Очень старые данные не должны влиять
      expect(recommendation.calorieDebt, equals(0));
      expect(recommendation.adjustedTarget, equals(2000));
    });

    test('handles midnight edge case', () {
      final midnight = DateTime(2025, 6, 3, 0, 0);
      final beforeMidnight = DateTime(2025, 6, 2, 23, 59);
      final afterMidnight = DateTime(2025, 6, 3, 0, 1);

      stabilizer.addEntries([
        CalorieEntry(timestamp: beforeMidnight, calories: 500),
        CalorieEntry(timestamp: afterMidnight, calories: 300),
      ]);

      // Скользящее окно должно включать оба приёма
      final totalInWindow = stabilizer.getCaloriesInRange(
        midnight.subtract(const Duration(hours: 24)),
        midnight,
      );
      expect(totalInWindow, equals(500));
    });

    test('handles irregular sleep schedule', () {
      // Пользователь не спал 25 часов
      final longDay = DateTime(2025, 6, 1, 6, 0);

      stabilizer.addEntries([
        CalorieEntry(timestamp: longDay, calories: 500), // Утро
        CalorieEntry(timestamp: longDay.add(const Duration(hours: 6)), calories: 600),
        CalorieEntry(timestamp: longDay.add(const Duration(hours: 12)), calories: 700),
        CalorieEntry(timestamp: longDay.add(const Duration(hours: 18)), calories: 600),
        CalorieEntry(timestamp: longDay.add(const Duration(hours: 24)), calories: 400), // Следующее утро
      ]);

      // Скользящее окно последних 24 часов
      final checkTime = longDay.add(const Duration(hours: 25));
      final consumed = stabilizer.getCaloriesInRange(
        checkTime.subtract(const Duration(hours: 24)),
        checkTime,
      );

      // Должно включать приёмы пищи за последние 24 часа
      expect(consumed, greaterThan(0));
    });

    test('handles zero calorie entries', () {
      final now = DateTime.now();
      stabilizer.addEntry(CalorieEntry(timestamp: now, calories: 0));

      final recommendation = stabilizer.getRecommendation(now);
      expect(recommendation.consumed, equals(0));
    });

    // test('handles very large calorie values', () {
    //   final now = DateTime.now();
    //   stabilizer.addEntry(CalorieEntry(
    //     timestamp: now.subtract(const Duration(hours: 1)),
    //     calories: 10000,
    //   ));
    //
    //   final recommendation = stabilizer.getRecommendation(now);
    //
    //   expect(recommendation.warnings, isNotEmpty);
    //   expect(
    //     recommendation.warnings.any((w) => w.type == WarningType.rapidConsumption),
    //     isTrue,
    //   );
    // });
  });

  group('Integration Tests', () {
    // test('full day scenario', () {
    //   final stabilizer = CalorieStabilizer(
    //     settings: const StabilizerSettings(
    //       targetDailyCalories: 2000,
    //       idealMealsPerDay: 4,
    //       minMealInterval: 2,
    //     ),
    //   );
    //
    //   final dayStart = DateTime(2025, 6, 3, 7, 0);
    //
    //   // Завтрак
    //   stabilizer.addEntry(CalorieEntry(
    //     timestamp: dayStart,
    //     calories: 500,
    //   ));
    //
    //   var rec = stabilizer.getRecommendation(dayStart.add(const Duration(minutes: 30)));
    //   expect(rec.consumed, equals(500));
    //   expect(rec.remaining, lessThan(2000));
    //   // Следующий приём не сразу
    //   expect(rec.nextMeal.suggestedTime.isAfter(dayStart.add(const Duration(hours: 1))), isTrue);
    //
    //   // Перекус
    //   stabilizer.addEntry(CalorieEntry(
    //     timestamp: dayStart.add(const Duration(hours: 3)),
    //     calories: 200,
    //   ));
    //
    //   // Обед
    //   stabilizer.addEntry(CalorieEntry(
    //     timestamp: dayStart.add(const Duration(hours: 5)),
    //     calories: 700,
    //   ));
    //
    //   // Полдник
    //   stabilizer.addEntry(CalorieEntry(
    //     timestamp: dayStart.add(const Duration(hours: 8)),
    //     calories: 200,
    //   ));
    //
    //   // Ужин
    //   stabilizer.addEntry(CalorieEntry(
    //     timestamp: dayStart.add(const Duration(hours: 11)),
    //     calories: 500,
    //   ));
    //
    //   final endOfDay = dayStart.add(const Duration(hours: 14));
    //   rec = stabilizer.getRecommendation(endOfDay);
    //
    //   expect(rec.consumed, equals(2100));
    //   expect(rec.remaining, equals(0)); // Небольшое превышение
    //   expect(
    //     rec.warnings.any((w) => w.type == WarningType.overeating),
    //     isTrue,
    //   );
    // });

    // test('compensation works over multiple days', () {
    //   final stabilizer = CalorieStabilizer(
    //     settings: const StabilizerSettings(
    //       targetDailyCalories: 2000,
    //       compensationRate: 0.5,
    //       maxCompensationPerDay: 300,
    //     ),
    //   );
    //
    //   // День 1 - нормальный
    //   final day1 = DateTime(2025, 6, 1, 12, 0);
    //   stabilizer.addEntry(CalorieEntry(timestamp: day1, calories: 2000));
    //
    //   // День 2 - превышение
    //   final day2 = DateTime(2025, 6, 2, 12, 0);
    //   stabilizer.addEntry(CalorieEntry(timestamp: day2, calories: 2600));
    //
    //   // День 3 - проверяем компенсацию
    //   final day3 = DateTime(2025, 6, 3, 8, 0);
    //   final rec = stabilizer.getRecommendation(day3);
    //
    //   // Цель должна быть снижена из-за превышения вчера
    //   expect(rec.adjustedTarget, lessThan(2000));
    //   expect(rec.calorieDebt, greaterThan(0));
    //   expect(rec.compensation, greaterThan(0));
    //
    //   print('Day 3 recommendation: $rec');
    // });
  });
}