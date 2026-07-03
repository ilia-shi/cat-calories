import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_tracker.dart';
import '../widgets/density_scale_widget.dart';
import 'package:cat_calories/features/calorie_tracking/ui/indicators_widget.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/rate_meals_row.dart';
import '../widgets/recent_entries_widget.dart';

final class TrackingTab extends StatefulWidget {
  const TrackingTab({Key? key}) : super(key: key);

  @override
  State<TrackingTab> createState() => _TrackingTabState();
}

class _TrackingTabState extends State<TrackingTab> {
  late DateTime _baseTime;
  double _hoursOffset = 0;
  late RollingCalorieTracker _tracker;
  List<CalorieEntry> _entries = [];
  Timer? _refreshTimer;
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

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        final now = DateTime.now();
        if (now.day != _lastKnownDay) {
          _lastKnownDay = now.day;
          BlocProvider.of<HomeBloc>(context)
              .add(CalorieItemListFetchingInProgressEvent());
        }

        if (_hoursOffset == 0) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  DateTime get _currentTime {
    if (_hoursOffset == 0) {
      return DateTime.now();
    }

    return _baseTime.add(Duration(
      minutes: (_hoursOffset * 60).round(),
    ));
  }

  void _handleRemoveEntry(CalorieEntry entry) {
    setState(() {
      _entries.removeWhere(
          (e) => e.createdAt == entry.createdAt && e.value == entry.value);
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

  IndicatorData _calculateIndicatorData(
      HomeFetched state, List<CalorieEntry> entries) {
    final now = _currentTime;
    final dailyGoal = state.activeProfile.caloriesLimitGoal;

    final caloriesLast24Hours = _tracker.consumedInLast24h(entries, now);

    final double caloriesToday;
    if (_hoursOffset == 0) {
      caloriesToday = state.todayCalorieItems
          .where((item) => item.isEaten())
          .fold(0.0, (sum, item) => sum + item.value);
    } else {
      final simulatedDayStart = DateTime(now.year, now.month, now.day);
      final simulatedDayEnd = simulatedDayStart.add(const Duration(days: 1));
      caloriesToday = entries
          .where((e) =>
              e.createdAt.isAfter(simulatedDayStart) &&
              e.createdAt.isBefore(simulatedDayEnd))
          .fold(0.0, (sum, e) => sum + e.value);
    }

    final caloriesYesterday = _calculateYesterdayCalories(state, entries, now);
    final averageLast7Days = _calculateAverageLast7Days(state, entries, now);
    final caloriesCurrentPeriod = state.periodCalorieItems
        .where((item) => item.isEaten())
        .fold(0.0, (sum, item) => sum + item.value);

    final periodGoal =
        state.currentWakingPeriod?.caloriesLimitGoal ?? dailyGoal;
    final hasPeriod = state.currentWakingPeriod != null;

    final macrosToday = MacroData.fromCalorieItems(
      state.todayCalorieItems,
    );

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

  double _calculateYesterdayCalories(
      HomeFetched state, List<CalorieEntry> entries, DateTime now) {
    final yesterdayStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final yesterdayEnd = DateTime(now.year, now.month, now.day);

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

    double yesterdayTotal = 0.0;
    for (final entry in entries) {
      if (entry.createdAt.isAfter(yesterdayStart) &&
          entry.createdAt.isBefore(yesterdayEnd)) {
        yesterdayTotal += entry.value;
      }
    }
    return yesterdayTotal;
  }

  double _calculateAverageLast7Days(
      HomeFetched state, List<CalorieEntry> entries, DateTime now) {
    // Use days30 data for historical average (excluding today)
    final todayStart = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));

    final relevantDays = state.days30.where((day) {
      final dayDate = day.createdAtDay;
      return dayDate.isAfter(sevenDaysAgo) && dayDate.isBefore(todayStart);
    }).toList();

    if (relevantDays.isEmpty) {
      return _tracker.getAverageDaily(entries, now, days: 7);
    }

    final totalCalories =
        relevantDays.fold(0.0, (sum, day) => sum + day.valueSum);
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
            setState(() {
              _baseTime = DateTime.now();
              _lastKnownDay = DateTime.now().day;
            });
            BlocProvider.of<HomeBloc>(context)
                .add(CalorieItemListFetchingInProgressEvent());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Column(
              children: [
                IndicatorsWidget(
                  data: indicatorData,
                ),

                const SizedBox(height: 12),

                // Lazy, dismissible; renders nothing when there is nothing
                // to rate, so the 12px gap below only exists via its card.
                const RateMealsRow(),

                DensityScaleWidget(
                  entries: entries,
                  currentTime: _currentTime,
                ),

                const SizedBox(height: 12),

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
