import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/home/home_bloc.dart';
import '../../../blocs/home/home_event.dart';
import '../../../blocs/home/home_state.dart';
import '../../../tracking/calorie_tracker.dart';
import '../widgets/budget_display_widget.dart';
import '../widgets/density_scale_widget.dart';
import '../widgets/forecast_widget.dart';
import '../widgets/indicators_widget.dart';
import '../widgets/meal_recommendation_widget.dart';
import '../widgets/recent_entries_widget.dart';
import '../widgets/time_control_widget.dart';


final class TrackingTab extends StatefulWidget {
  const TrackingTab({Key? key}) : super(key: key);

  @override
  State<TrackingTab> createState() => _TrackingTabState();
}

class _TrackingTabState extends State<TrackingTab> {

  late DateTime _baseTime;
  double _hoursOffset = 0;

  // Tracker instance
  late RollingCalorieTracker _tracker;

  List<CalorieEntry> _entries = [];

  // FIXED: Timer for periodic refresh
  Timer? _refreshTimer;

  // FIXED: Track the current day to detect day changes
  late int _lastKnownDay;

  @override
  void initState() {
    super.initState();
    _baseTime = DateTime.now();
    _lastKnownDay = DateTime.now().day;
    _tracker = RollingCalorieTracker(
      config: const RollingTrackerConfig(
        targetDailyCalories: 2000,
        minMealSize: 100,
        maxMealSize: 1000,
        minHoursBetweenMeals: 2.0,
        compensation: CompensationConfig(
          strength: 0.2,
          decayFactor: 0.85,
          windowHours: 96,
        ),
      ),
    );

    // FIXED: Set up periodic refresh timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        final now = DateTime.now();

        // Check if the day has changed
        if (now.day != _lastKnownDay) {
          _lastKnownDay = now.day;
          // Day changed - trigger bloc refresh to get fresh data
          BlocProvider.of<HomeBloc>(context)
              .add(CalorieItemListFetchingInProgressEvent());
        }

        // Always refresh UI to update time display when offset is 0
        if (_hoursOffset == 0) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    // FIXED: Cancel timer on dispose
    _refreshTimer?.cancel();
    super.dispose();
  }

  // FIXED: Use DateTime.now() when offset is 0 for accurate current time
  DateTime get _currentTime {
    if (_hoursOffset == 0) {
      return DateTime.now();
    }
    return _baseTime.add(Duration(
      minutes: (_hoursOffset * 60).round(),
    ));
  }

  void _handleTimeOffsetChanged(double offset) {
    setState(() {
      _hoursOffset = offset;
      // When user starts using time simulation, reset the base time
      if (offset != 0) {
        _baseTime = DateTime.now();
      }
    });
  }

  void _handleRemoveEntry(CalorieEntry entry) {
    setState(() {
      _entries.removeWhere((e) =>
      e.createdAt == entry.createdAt && e.value == entry.value);
    });
  }

  List<CalorieEntry> _convertFromBloc(HomeFetched state) {
    return state.rollingWindowCalorieItems
        .where((item) => item.isEaten())
        .map((item) => CalorieEntry(
      createdAt: item.eatenAt ?? item.createdAt,
      value: item.value,
      description: item.description,
    ))
        .toList();
  }

  /// Calculate indicators data from the bloc state
  IndicatorData _calculateIndicatorData(HomeFetched state, List<CalorieEntry> entries) {
    final now = _currentTime;
    final dailyGoal = state.activeProfile.caloriesLimitGoal;

    // 1. Calories for last 24 hours (rolling window)
    final caloriesLast24Hours = _tracker.consumedInLast24h(entries, now);

    // 2. Calories for today (calendar day)
    // FIXED: When using time simulation, calculate "today" based on the simulated time
    final double caloriesToday;
    if (_hoursOffset == 0) {
      caloriesToday = state.todayCalorieItems
          .where((item) => item.isEaten())
          .fold(0.0, (sum, item) => sum + item.value);
    } else {
      final simulatedDayStart = DateTime(now.year, now.month, now.day);
      final simulatedDayEnd = simulatedDayStart.add(const Duration(days: 1));
      caloriesToday = entries
          .where((e) => e.createdAt.isAfter(simulatedDayStart) &&
          e.createdAt.isBefore(simulatedDayEnd))
          .fold(0.0, (sum, e) => sum + e.value);
    }

    final caloriesYesterday = _calculateYesterdayCalories(state, entries, now);
    final averageLast7Days = _calculateAverageLast7Days(state, entries, now);
    final caloriesCurrentPeriod = state.periodCalorieItems
        .where((item) => item.isEaten())
        .fold(0.0, (sum, item) => sum + item.value);

    // Period goal
    final periodGoal = state.currentWakingPeriod?.caloriesLimitGoal ?? dailyGoal;
    final hasPeriod = state.currentWakingPeriod != null;

    // Calculate macro data for today
    final macrosToday = MacroData.fromCalorieItems(
      state.todayCalorieItems,
      // You can add goals here if your profile has them
      // proteinGoal: state.activeProfile.proteinGoal,
      // fatGoal: state.activeProfile.fatGoal,
      // carbGoal: state.activeProfile.carbGoal,
    );

    // Calculate macro data for 24h rolling window
    final macros24h = MacroData.fromCalorieItems(
      state.rollingWindowCalorieItems,
    );

    return IndicatorData(
      averageLast7Days: averageLast7Days,
      caloriesLast24Hours: caloriesLast24Hours,
      caloriesToday: caloriesToday,
      caloriesYesterday: caloriesYesterday,
      caloriesCurrentPeriod: caloriesCurrentPeriod,
      todayCalorieItems: state.todayCalorieItems,
      dailyGoal: dailyGoal,
      periodGoal: periodGoal,
      hasPeriod: hasPeriod,
      now: _baseTime,
      macrosToday: macrosToday,
      macros24h: macros24h,
    );
  }

  /// Calculate yesterday's calories from days30 data or rolling window
  double _calculateYesterdayCalories(HomeFetched state, List<CalorieEntry> entries, DateTime now) {
    final yesterdayStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final yesterdayEnd = DateTime(now.year, now.month, now.day);

    // Try to get from days30 data first (when not in simulation mode)
    if (_hoursOffset == 0) {
      for (final dayResult in state.days30) {
        final dayDate = dayResult.createdAtDay;
        if (dayDate.year == yesterdayStart.year &&
            dayDate.month == yesterdayStart.month &&
            dayDate.day == yesterdayStart.day) {
          return dayResult.valueSum;
        }
      }
    }

    // Fallback or simulation mode: calculate from entries
    double yesterdayTotal = 0.0;
    for (final entry in entries) {
      if (entry.createdAt.isAfter(yesterdayStart) && entry.createdAt.isBefore(yesterdayEnd)) {
        yesterdayTotal += entry.value;
      }
    }
    return yesterdayTotal;
  }

  /// Calculate average daily calories for last 7 days, excluding last 24 hours
  double _calculateAverageLast7Days(HomeFetched state, List<CalorieEntry> entries, DateTime now) {
    // Use days30 data for historical average (excluding today)
    final todayStart = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));

    final relevantDays = state.days30.where((day) {
      final dayDate = day.createdAtDay;
      return dayDate.isAfter(sevenDaysAgo) &&
          dayDate.isBefore(todayStart);
    }).toList();

    if (relevantDays.isEmpty) {
      // Fallback: use tracker's average method
      return _tracker.getAverageDaily(entries, now, days: 7);
    }

    final totalCalories = relevantDays.fold(0.0, (sum, day) => sum + day.valueSum);
    return totalCalories / relevantDays.length;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        if (state is HomeFetchingInProgress) {
          return const Center(child: CircularProgressIndicator());
        }

        List<CalorieEntry> entries;
        RollingTrackerConfig config;

        if (state is HomeFetched) {
          entries = _convertFromBloc(state);
          config = RollingTrackerConfig(
            targetDailyCalories: state.activeProfile.caloriesLimitGoal,
            minMealSize: 100,
            maxMealSize: 1000,
            minHoursBetweenMeals: 2.0,
          );
          _tracker = RollingCalorieTracker(config: config);
        } else {
          entries = _entries;
          config = _tracker.config;
        }

        final recommendation = _tracker.getRecommendation(entries, _currentTime);
        final forecast = _tracker.getForecast(entries, _currentTime, hours: 12);
        final recentEntries = _tracker.entriesInLast24h(entries, _currentTime);

        final indicatorData = state is HomeFetched
            ? _calculateIndicatorData(state, entries)
            : IndicatorData(
          averageLast7Days: 0,
          caloriesLast24Hours:
          _tracker.consumedInLast24h(entries, _currentTime),
          caloriesToday: 0,
          caloriesYesterday: 0,
          caloriesCurrentPeriod: 0,
          dailyGoal: config.targetDailyCalories,
          todayCalorieItems: [],
          now: _baseTime,
        );

        return RefreshIndicator(
          onRefresh: () async {
            // FIXED: Reset base time and trigger bloc refresh on pull-to-refresh
            setState(() {
              _baseTime = DateTime.now();
              _lastKnownDay = DateTime.now().day;
            });
            BlocProvider.of<HomeBloc>(context)
                .add(CalorieItemListFetchingInProgressEvent());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                IndicatorsWidget(
                  data: indicatorData,
                ),

                const SizedBox(height: 16),

                DensityScaleWidget(
                  entries: entries,
                  currentTime: _currentTime,
                ),

                const SizedBox(height: 16),

                TimeControlWidget(
                  baseTime: _baseTime,
                  hoursOffset: _hoursOffset,
                  onOffsetChanged: _handleTimeOffsetChanged,
                  minOffset: -96,
                  maxOffset: 96,
                ),

                const SizedBox(height: 16),

                // Budget Display
                BudgetDisplayWidget(
                  recommendation: recommendation,
                ),

                const SizedBox(height: 16),

                const SizedBox(height: 16),

                // Meal Recommendation
                MealRecommendationWidget(
                  recommendation: recommendation,
                  currentTime: _currentTime,
                ),

                const SizedBox(height: 16),

                // Forecast
                ForecastWidget(
                  forecast: forecast,
                  targetCalories: config.targetDailyCalories,
                  currentTime: _currentTime,
                ),

                const SizedBox(height: 16),

                // Recent Entries
                RecentEntriesWidget(
                  entries: recentEntries,
                  currentTime: _currentTime,
                  onRemove: _handleRemoveEntry,
                  maxEntries: 10,
                ),

                // Bottom spacing
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}