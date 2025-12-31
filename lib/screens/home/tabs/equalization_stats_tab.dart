import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/calorie_stabilizer/calorie_stabilizer.dart';
import 'package:cat_calories/calorie_stabilizer/models.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

class EqualizationStatsView extends StatefulWidget {
  const EqualizationStatsView({Key? key}) : super(key: key);

  @override
  State<EqualizationStatsView> createState() => _EqualizationStatsViewState();
}

class _EqualizationStatsViewState extends State<EqualizationStatsView> {
  CalorieStabilizer? _stabilizer;
  DailyRecommendation? _recommendation;

  void _initializeStabilizer(HomeFetched state) {
    final profile = state.activeProfile;

    // Create settings based on profile
    final settings = StabilizerSettings(
      targetDailyCalories: profile.caloriesLimitGoal,
      windowHours: profile.wakingTimeSeconds / 3600.0,
      compensationRate: 0.5,
      maxCompensationPerDay: profile.caloriesLimitGoal * 0.15,
      compensationDecayDays: 7,
      minDailyCalories: math.max(1200, profile.caloriesLimitGoal * 0.6),
      maxDailyCalories: profile.caloriesLimitGoal * 1.5,
      maxCaloriesPerHour: profile.caloriesLimitGoal * 0.4,
      maxCaloriesPerMeal: profile.caloriesLimitGoal * 0.5,
      minMealInterval: 2.0,
      maxFastingHours: 8.0,
      idealMealsPerDay: 4,
      mealSizeVariance: 0.3,
      historyDecayHalfLife: 3.0,
      recentHoursWeight: 6.0,
      mealGroupingMinutes: 30,
    );

    _stabilizer = CalorieStabilizer(settings: settings);

    // Add data for recent days from todayCalorieItems and periodCalorieItems
    final allItems = <CalorieItemModel>[
      ...state.todayCalorieItems,
      ...state.periodCalorieItems,
    ];

    // Remove duplicates by id
    final uniqueItems = <int, CalorieItemModel>{};
    for (final item in allItems) {
      if (item.id != null && item.isEaten()) {
        uniqueItems[item.id!] = item;
      }
    }

    for (final item in uniqueItems.values) {
      _stabilizer!.addEntry(CalorieEntry(
        timestamp: item.eatenAt ?? item.createdAt,
        calories: item.value,
        note: item.description,
      ));
    }

    // Add historical data from days30
    final today = DateTime.now();
    for (final day in state.days30) {
      // Skip today (already added from todayCalorieItems)
      if (day.createdAtDay.year == today.year &&
          day.createdAtDay.month == today.month &&
          day.createdAtDay.day == today.day) {
        continue;
      }

      // Add as a single entry at midday
      if (day.valueSum > 0) {
        _stabilizer!.addEntry(CalorieEntry(
          timestamp: day.createdAtDay.add(const Duration(hours: 12)),
          calories: day.valueSum,
        ));
      }
    }

    _recommendation = _stabilizer!.getRecommendation();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        if (state is HomeFetchingInProgress) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HomeFetched) {
          _initializeStabilizer(state);

          if (_recommendation == null) {
            return const Center(child: Text('Failed to calculate recommendations'));
          }

          final rec = _recommendation!;
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _initializeStabilizer(state);
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildMainCard(context, rec, state, isDarkMode),
                const SizedBox(height: 12),
                _buildNextMealCard(context, rec, isDarkMode),
                const SizedBox(height: 12),
                if (rec.warnings.isNotEmpty)
                  _buildWarningsCard(context, rec, isDarkMode),
                if (rec.warnings.isNotEmpty) const SizedBox(height: 12),
                _buildStatsCard(context, rec, state, isDarkMode),
                const SizedBox(height: 12),
                _buildDebtCard(context, rec, isDarkMode),
              ],
            ),
          );
        }

        return const Center(child: Text('Error loading data'));
      },
    );
  }

  Widget _buildMainCard(
      BuildContext context, DailyRecommendation rec, HomeFetched state, bool isDarkMode) {
    final progressPercent = rec.progressPercent.clamp(0.0, 100.0);
    final isOver = rec.consumed > rec.adjustedTarget;
    final progressColor = isOver ? DangerColor : SuccessColor;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                _buildAdjustmentBadge(rec.compensation, isDarkMode),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Circular progress
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: CircularProgressIndicator(
                          value: progressPercent / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation(progressColor),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${progressPercent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: progressColor,
                              ),
                            ),
                            Text(
                              isOver ? 'exceeded' : 'completed',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Consumed / Target
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${rec.consumed.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${rec.adjustedTarget.toStringAsFixed(0)} kcal',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Base target
                      if (rec.compensation > 0)
                        Text(
                          'Base target: ${rec.baseTarget.toStringAsFixed(0)} kcal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Remaining
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (rec.remaining >= 0 ? SuccessColor : DangerColor)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              rec.remaining >= 0 ? Icons.check_circle : Icons.warning,
                              size: 16,
                              color: rec.remaining >= 0 ? SuccessColor : DangerColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rec.remaining >= 0
                                  ? 'Remaining: ${rec.remaining.toStringAsFixed(0)} kcal'
                                  : 'Exceeded by: ${rec.remaining.abs().toStringAsFixed(0)} kcal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: rec.remaining >= 0 ? SuccessColor : DangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentBadge(double compensation, bool isDarkMode) {
    if (compensation.abs() < 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: SuccessColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 14, color: SuccessColor),
            const SizedBox(width: 4),
            const Text(
              'On track',
              style: TextStyle(
                  fontSize: 12, color: SuccessColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DangerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_down, size: 14, color: DangerColor),
          const SizedBox(width: 4),
          Text(
            '-${compensation.toStringAsFixed(0)} kcal',
            style: const TextStyle(
                fontSize: 12, color: DangerColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMealCard(
      BuildContext context, DailyRecommendation rec, bool isDarkMode) {
    final nextMeal = rec.nextMeal;
    final now = DateTime.now();
    final canEatNow = nextMeal.suggestedTime.isBefore(now) ||
        nextMeal.suggestedTime.difference(now).inMinutes < 5;

    final timeUntilMeal = nextMeal.suggestedTime.difference(now);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: canEatNow
                        ? SuccessColor.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    canEatNow ? Icons.restaurant : Icons.schedule,
                    color: canEatNow ? SuccessColor : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canEatNow ? 'You can eat now' : 'Next meal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextMeal.reason,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Time and calories
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.access_time,
                    title: canEatNow ? 'Now' : _formatDuration(timeUntilMeal),
                    subtitle: canEatNow ? 'time to eat' : 'until meal',
                    color: canEatNow ? SuccessColor : Colors.orange,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.local_fire_department,
                    title: '${nextMeal.suggestedCalories.toStringAsFixed(0)}',
                    subtitle: 'kcal recommended',
                    color: Colors.deepOrange,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Calorie range
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCalorieRange('Min', nextMeal.minCalories, Colors.green),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey.shade400,
                  ),
                  _buildCalorieRange('Rec', nextMeal.suggestedCalories, Colors.blue),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey.shade400,
                  ),
                  _buildCalorieRange('Max', nextMeal.maxCalories, Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieRange(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'kcal',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningsCard(
      BuildContext context, DailyRecommendation rec, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: rec.hasCriticalWarnings ? DangerColor : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Warnings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...rec.warnings.map((warning) => _buildWarningItem(warning, isDarkMode)),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningItem(Warning warning, bool isDarkMode) {
    Color color;
    IconData icon;

    switch (warning.severity) {
      case WarningSeverity.critical:
        color = DangerColor;
        icon = Icons.error;
        break;
      case WarningSeverity.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case WarningSeverity.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              warning.message,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, DailyRecommendation rec,
      HomeFetched state, bool isDarkMode) {
    final mealsToday = _stabilizer?.getMealsInWindow(DateTime.now()) ?? 0;
    final hoursSinceLastMeal =
        _stabilizer?.getHoursSinceLastMeal(DateTime.now()) ?? 0;
    final remainingMeals = _stabilizer?.estimateRemainingMeals(DateTime.now()) ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.restaurant,
                  value: '$mealsToday',
                  label: 'meals',
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.timer,
                  value: '${hoursSinceLastMeal.toStringAsFixed(1)}h',
                  label: 'since last',
                  color: hoursSinceLastMeal > 6 ? Colors.orange : Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.event_note,
                  value: '$remainingMeals',
                  label: 'remaining',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtCard(
      BuildContext context, DailyRecommendation rec, bool isDarkMode) {
    final hasDebt = rec.calorieDebt > 100;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calorie compensation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hasDebt
                        ? DangerColor.withOpacity(0.1)
                        : SuccessColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasDebt ? 'Has debt' : 'All good',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasDebt ? DangerColor : SuccessColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Debt visualization
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accumulated excess:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${rec.calorieDebt.toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasDebt ? DangerColor : SuccessColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s compensation:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '-${rec.compensation.toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: rec.compensation > 0 ? Colors.orange : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasDebt
                          ? 'Your target has been reduced to compensate for excess in previous days. Debt decreases over time.'
                          : 'You\'re controlling your calorie intake well! Keep it up.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Now';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '$minutes min';
  }
}