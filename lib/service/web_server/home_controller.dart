import 'dart:io';

import 'package:cat_calories/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories/features/waking_periods/domain/waking_period_repository_interface.dart';
import 'package:cat_calories/service/profile_resolver.dart';
import 'package:cat_calories/service/web_server/controller.dart';
import 'package:cat_calories/service/web_server/router.dart';
import 'package:get_it/get_it.dart';

class HomeController extends Controller {
  final _locator = GetIt.instance;

  @override
  void register(Router router) {
    router.get('/api/home', _index);
  }

  Future<void> _index(HttpRequest request, Map<String, String> params) async {
    final repo = _locator.get<CalorieRecordRepositoryInterface>();
    final profile = await ProfileResolver().resolve();
    final now = DateTime.now();

    final items = await repo.fetchAllByProfile(profile, orderBy: 'created_at DESC');
    final eatenItems = items.where((item) => item.isEaten()).toList();

    // 24h rolling
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    final rolling24h = eatenItems
        .where((item) => (item.eatenAt ?? item.createdAt).isAfter(twentyFourHoursAgo))
        .fold(0.0, (sum, item) => sum + item.value);

    // Today (calendar day)
    final todayStart = DateTime(now.year, now.month, now.day);
    final today = eatenItems.where((item) {
      final t = item.eatenAt ?? item.createdAt;
      return !t.isBefore(todayStart) && t.isBefore(todayStart.add(const Duration(days: 1)));
    }).fold(0.0, (sum, item) => sum + item.value);

    // Yesterday
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterday = eatenItems.where((item) {
      final t = item.eatenAt ?? item.createdAt;
      return !t.isBefore(yesterdayStart) && t.isBefore(todayStart);
    }).fold(0.0, (sum, item) => sum + item.value);

    // 7-day average (last 7 completed days, excluding today)
    final days = await repo.fetchDaysByProfile(profile, 30);
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
    final relevantDays = days.where((day) {
      return day.createdAtDay.isAfter(sevenDaysAgo) &&
          day.createdAtDay.isBefore(todayStart);
    }).toList();

    final avg7Days = relevantDays.isEmpty
        ? 0.0
        : relevantDays.fold(0.0, (sum, day) => sum + day.valueSum) / relevantDays.length;

    // Period (current waking period)
    final wakingPeriodRepo = _locator.get<WakingPeriodRepositoryInterface>();
    final currentPeriod = await wakingPeriodRepo.findActual(profile);
    double periodCalories = 0;
    double? periodGoal;
    if (currentPeriod != null) {
      final periodItems = await repo.fetchByWakingPeriodAndProfile(currentPeriod, profile);
      periodCalories = periodItems
          .where((item) => item.isEaten())
          .fold(0.0, (sum, item) => sum + item.value);
      periodGoal = currentPeriod.caloriesLimitGoal;
    }

    // Recent meals (last 24h)
    final recentMeals = eatenItems
        .where((item) => (item.eatenAt ?? item.createdAt).isAfter(twentyFourHoursAgo))
        .map((item) => <String, dynamic>{
      'id': item.id,
      'value': item.value,
      'description': item.description,
      'eaten_at': (item.eatenAt ?? item.createdAt).toIso8601String(),
    }).toList();

    respondJson(request, HttpStatus.ok, {
      'profile': {
        'name': profile.name,
        'calories_limit_goal': profile.caloriesLimitGoal,
      },
      'rolling_24h': rolling24h,
      'today': today,
      'yesterday': yesterday,
      'avg_7_days': avg7Days,
      'period': currentPeriod != null
          ? {'calories': periodCalories, 'goal': periodGoal}
          : null,
      'recent_meals': recentMeals,
    });
  }
}
