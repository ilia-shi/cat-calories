import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/models/day_result.dart';
import 'package:cat_calories/models/product_model.dart';
import 'package:cat_calories/models/profile_model.dart';
import 'package:cat_calories/models/waking_period_model.dart';
import 'package:cat_calories/models/calorie_recommendation_model.dart';
import 'package:cat_calories/models/equalization_settings_model.dart';

abstract class AbstractHomeState {}

class HomeFetchingInProgress extends AbstractHomeState {}

class HomeFetched extends AbstractHomeState {
  final DateTime nowDateTime;
  final List<CalorieItemModel> periodCalorieItems;
  final List<CalorieItemModel> todayCalorieItems;
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
  final CalorieRecommendationModel? recommendation;
  final EqualizationSettingsModel equalizationSettings;

  HomeFetched({
    required this.nowDateTime,
    required this.periodCalorieItems,
    required this.todayCalorieItems,
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

  DateTime getDayStart() {
    return DateTime(nowDateTime.year, nowDateTime.month, nowDateTime.day, 0, 0, 0);
  }

  DaysStat get30DaysUntilToday() {
    List<DayResultModel> days = [];
    double totalCalories = 0;

    this.days30.forEach((DayResultModel dayResult) {
      if (getDayStart().millisecondsSinceEpoch > dayResult.createdAtDay.millisecondsSinceEpoch) {
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
      if (getDayStart().millisecondsSinceEpoch > dayResult.createdAtDay.millisecondsSinceEpoch) {
        days.add(dayResult);
        totalCalories += dayResult.valueSum;
      }
    });

    return DaysStat(days, totalCalories);
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
