import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/models/day_result.dart';
import 'package:cat_calories/models/product_model.dart';
import 'package:cat_calories/models/product_category_model.dart';
import 'package:cat_calories/models/profile_model.dart';
import 'package:cat_calories/models/waking_period_model.dart';
import 'package:cat_calories/models/calorie_recommendation_model.dart';
import 'package:cat_calories/models/equalization_settings_model.dart';

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
  final List<CalorieItemModel> periodCalorieItems;
  final List<CalorieItemModel> todayCalorieItems;

  /// Calorie items from the last 48 hours for rolling window calculations.
  /// This enables the RollingCalorieTracker to work across irregular schedules
  /// without being tied to calendar day boundaries.
  final List<CalorieItemModel> rollingWindowCalorieItems;

  final List<DayResultModel> days30;
  final List<DayResultModel> days2;
  final List<ProfileModel> profiles;
  final List<WakingPeriodModel> wakingPeriods;
  final ProfileModel activeProfile;
  final DateTime startDate;
  final DateTime endDate;
  final WakingPeriodModel? currentWakingPeriod;
  final double preparedCaloriesValue;
  final List<ProductModel> products;
  final List<ProductCategoryModel> productCategories;
  final CalorieRecommendationModel? recommendation;
  final EqualizationSettingsModel equalizationSettings;

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

    periodCalorieItems.forEach((CalorieItemModel calorieItem) {
      if (calorieItem.isEaten()) {
        totalCalories += calorieItem.value;
      }
    });

    totalCalories += preparedCaloriesValue;

    return totalCalories;
  }

  double getTodayCaloriesEatenSum() {
    double totalCalories = 0;

    todayCalorieItems.forEach((CalorieItemModel calorieItem) {
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
    List<DayResultModel> days = [];
    double totalCalories = 0;

    this.days30.forEach((DayResultModel dayResult) {
      if (getDayStart().millisecondsSinceEpoch >
          dayResult.createdAtDay.millisecondsSinceEpoch) {
        days.add(dayResult);
        totalCalories += dayResult.valueSum;
      }
    });

    return DaysStat(days, totalCalories);
  }

  DaysStat get2DaysUntilToday() {
    List<DayResultModel> days = [];
    double totalCalories = 0;

    this.days2.forEach((DayResultModel dayResult) {
      if (getDayStart().millisecondsSinceEpoch >
          dayResult.createdAtDay.millisecondsSinceEpoch) {
        days.add(dayResult);
        totalCalories += dayResult.valueSum;
      }
    });

    return DaysStat(days, totalCalories);
  }

  /// Get products grouped by category
  Map<ProductCategoryModel?, List<ProductModel>> getProductsByCategory() {
    final Map<ProductCategoryModel?, List<ProductModel>> grouped = {};

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
  ProductCategoryModel? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return productCategories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Get recently used products
  List<ProductModel> getRecentlyUsedProducts({int limit = 5}) {
    final sortedProducts = products
        .where((p) => p.lastUsedAt != null)
        .toList()
      ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
    return sortedProducts.take(limit).toList();
  }

  /// Get most used products
  List<ProductModel> getMostUsedProducts({int limit = 5}) {
    final sortedProducts = products.where((p) => p.usesCount > 0).toList()
      ..sort((a, b) => b.usesCount.compareTo(a.usesCount));
    return sortedProducts.take(limit).toList();
  }
}

class DaysStat {
  final List<DayResultModel> days;
  final double totalCalories;

  DaysStat(
      this.days,
      this.totalCalories,
      );

  double getAvg() {
    return totalCalories / days.length;
  }
}