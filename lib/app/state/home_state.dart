import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/products/domain/product_category.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_recommendation.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/equalization_settings.dart';

import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';

abstract class AbstractHomeState {}

class HomeFetchingInProgress extends AbstractHomeState {}

/// Error state for database and other errors
class HomeError extends AbstractHomeState {
  final String message;
  final String? technicalDetails;
  final dynamic originalError;
  final StackTrace? stackTrace;

  /// If true, the error is recoverable and user can retry
  final bool canRetry;

  /// Previous state to restore after error is dismissed (optional)
  final HomeFetched? previousState;

  HomeError({
    required this.message,
    this.technicalDetails,
    this.originalError,
    this.stackTrace,
    this.canRetry = true,
    this.previousState,
  });

  @override
  String toString() => 'HomeError: $message';
}

class HomeFetched extends AbstractHomeState {
  final DateTime nowDateTime;
  final List<CalorieRecord> periodCalorieItems;
  final List<CalorieRecord> todayCalorieItems;

  /// Calorie items from the last 48 hours for rolling window calculations.
  /// This enables the RollingCalorieTracker to work across irregular schedules
  /// without being tied to calendar day boundaries.
  final List<CalorieRecord> rollingWindowCalorieItems;

  final List<DayResult> days30;
  final List<DayResult> days2;
  final List<Profile> profiles;
  final List<WakingPeriod> wakingPeriods;
  final Profile activeProfile;
  final DateTime startDate;
  final DateTime endDate;
  final WakingPeriod? currentWakingPeriod;
  final double preparedCaloriesValue;
  final List<Product> products;
  final List<ProductCategory> productCategories;
  final CalorieRecommendation? recommendation;
  final EqualizationSettings equalizationSettings;

  HomeFetched({
    required this.nowDateTime,
    required this.periodCalorieItems,
    required this.todayCalorieItems,
    required this.rollingWindowCalorieItems,
    required this.days30,
    required this.days2,
    required this.profiles,
    required this.wakingPeriods,
    required this.activeProfile,
    required this.startDate,
    required this.endDate,
    required this.currentWakingPeriod,
    required this.preparedCaloriesValue,
    required this.products,
    required this.productCategories,
    required this.recommendation,
    required this.equalizationSettings,
  });

  double getPeriodCaloriesEatenSum() {
    double totalCalories = 0;

    periodCalorieItems.forEach((CalorieRecord calorieItem) {
      if (calorieItem.isEaten()) {
        totalCalories += calorieItem.value;
      }
    });

    totalCalories += preparedCaloriesValue;

    return totalCalories;
  }

  double getTodayCaloriesEatenSum() {
    double totalCalories = 0;

    todayCalorieItems.forEach((CalorieRecord calorieItem) {
      if (calorieItem.isEaten()) {
        totalCalories += calorieItem.value;
      }
    });

    totalCalories += preparedCaloriesValue;

    return totalCalories;
  }

  /// Get calories consumed in the rolling 24-hour window ending at the given time.
  double getRolling24hCalories({DateTime? asOf}) {
    final endTime = asOf ?? DateTime.now();
    final startTime = endTime.subtract(const Duration(hours: 24));

    double total = 0;
    for (final item in rollingWindowCalorieItems) {
      if (item.isEaten()) {
        final eatenAt = item.eatenAt ?? item.createdAt;
        if (eatenAt.isAfter(startTime) && !eatenAt.isAfter(endTime)) {
          total += item.value;
        }
      }
    }
    return total;
  }

  /// Get remaining budget in the rolling 24-hour window.
  double getRolling24hRemaining({DateTime? asOf}) {
    final consumed = getRolling24hCalories(asOf: asOf);
    return (activeProfile.caloriesLimitGoal - consumed)
        .clamp(0.0, activeProfile.caloriesLimitGoal);
  }

  DateTime getDayStart() {
    return DateTime(
        nowDateTime.year, nowDateTime.month, nowDateTime.day, 0, 0, 0);
  }

  DaysStat get30DaysUntilToday() {
    List<DayResult> days = [];
    double totalCalories = 0;

    this.days30.forEach((DayResult dayResult) {
      if (getDayStart().millisecondsSinceEpoch >
          dayResult.createdAtDay.millisecondsSinceEpoch) {
        days.add(dayResult);
        totalCalories += dayResult.valueSum;
      }
    });

    return DaysStat(days, totalCalories);
  }

  DaysStat get2DaysUntilToday() {
    List<DayResult> days = [];
    double totalCalories = 0;

    this.days2.forEach((DayResult dayResult) {
      if (getDayStart().millisecondsSinceEpoch >
          dayResult.createdAtDay.millisecondsSinceEpoch) {
        days.add(dayResult);
        totalCalories += dayResult.valueSum;
      }
    });

    return DaysStat(days, totalCalories);
  }

  /// Get products grouped by category
  Map<ProductCategory?, List<Product>> getProductsByCategory() {
    final Map<ProductCategory?, List<Product>> grouped = {};

    // Initialize with null key for uncategorized
    grouped[null] = [];

    // Initialize category keys
    for (final category in productCategories) {
      grouped[category] = [];
    }

    // Group products
    for (final product in products) {
      if (product.categoryId == null) {
        grouped[null]!.add(product);
      } else {
        final category = productCategories.firstWhere(
              (c) => c.id == product.categoryId,
          orElse: () => productCategories.first,
        );
        grouped[category]?.add(product);
      }
    }

    return grouped;
  }

  /// Get category by UUID
  ProductCategory? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return productCategories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Get recently used products
  List<Product> getRecentlyUsedProducts({int limit = 5}) {
    final sortedProducts = products
        .where((p) => p.lastUsedAt != null)
        .toList()
      ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
    return sortedProducts.take(limit).toList();
  }

  /// Get most used products
  List<Product> getMostUsedProducts({int limit = 5}) {
    final sortedProducts = products.where((p) => p.usesCount > 0).toList()
      ..sort((a, b) => b.usesCount.compareTo(a.usesCount));
    return sortedProducts.take(limit).toList();
  }
}

class DaysStat {
  final List<DayResult> days;
  final double totalCalories;

  DaysStat(
      this.days,
      this.totalCalories,
      );

  double getAvg() {
    return totalCalories / days.length;
  }
}