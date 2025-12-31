import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/calorie_stabilizer/calorie_stabilizer.dart';
import 'package:cat_calories/calorie_stabilizer/models.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Компактный виджет рекомендаций для отображения на главной странице
class StabilizerRecommendationWidget extends StatelessWidget {
  final HomeFetched state;

  const StabilizerRecommendationWidget({Key? key, required this.state}) : super(key: key);

  CalorieStabilizer _createStabilizer() {
    final profile = state.activeProfile;

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

    final stabilizer = CalorieStabilizer(settings: settings);

    // Добавляем данные
    final allItems = <CalorieItemModel>[
      ...state.todayCalorieItems,
      ...state.periodCalorieItems,
    ];

    final uniqueItems = <int, CalorieItemModel>{};
    for (final item in allItems) {
      if (item.id != null && item.isEaten()) {
        uniqueItems[item.id!] = item;
      }
    }

    for (final item in uniqueItems.values) {
      stabilizer.addEntry(CalorieEntry(
        timestamp: item.eatenAt ?? item.createdAt,
        calories: item.value,
        note: item.description,
      ));
    }

    // Исторические данные
    final today = DateTime.now();
    for (final day in state.days30) {
      if (day.createdAtDay.year == today.year &&
          day.createdAtDay.month == today.month &&
          day.createdAtDay.day == today.day) {
        continue;
      }
      if (day.valueSum > 0) {
        stabilizer.addEntry(CalorieEntry(
          timestamp: day.createdAtDay.add(const Duration(hours: 12)),
          calories: day.valueSum,
        ));
      }
    }

    return stabilizer;
  }

  @override
  Widget build(BuildContext context) {
    final stabilizer = _createStabilizer();
    final rec = stabilizer.getRecommendation();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final nextMeal = rec.nextMeal;
    final canEatNow = nextMeal.suggestedTime.isBefore(now) ||
        nextMeal.suggestedTime.difference(now).inMinutes < 5;
    final hoursSinceLastMeal = stabilizer.getHoursSinceLastMeal(now);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: canEatNow
                ? [SuccessColor.withOpacity(0.1), SuccessColor.withOpacity(0.05)]
                : [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с иконкой
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: canEatNow
                          ? SuccessColor.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      canEatNow ? Icons.restaurant : Icons.schedule,
                      color: canEatNow ? SuccessColor : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Рекомендация',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          canEatNow ? 'Можно поесть' : 'Следующий приём',
                          style: TextStyle(
                            fontSize: 12,
                            color: canEatNow ? SuccessColor : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Компенсация (если есть)
                  if (rec.compensation > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DangerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${rec.compensation.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: DangerColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Основная информация
              Row(
                children: [
                  // Рекомендуемые калории
                  Expanded(
                    child: _buildMiniStat(
                      icon: Icons.local_fire_department,
                      value: '${nextMeal.suggestedCalories.toStringAsFixed(0)}',
                      label: 'kcal',
                      color: Colors.deepOrange,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  // Время с последнего приёма
                  Expanded(
                    child: _buildMiniStat(
                      icon: Icons.timer,
                      value: '${hoursSinceLastMeal.toStringAsFixed(1)}ч',
                      label: 'с еды',
                      color: hoursSinceLastMeal > 6 ? Colors.orange : Colors.blue,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  // Осталось калорий
                  Expanded(
                    child: _buildMiniStat(
                      icon: rec.remaining >= 0 ? Icons.check_circle : Icons.warning,
                      value: '${rec.remaining.abs().toStringAsFixed(0)}',
                      label: rec.remaining >= 0 ? 'осталось' : 'превыш.',
                      color: rec.remaining >= 0 ? SuccessColor : DangerColor,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
              // Предупреждения (если есть критические)
              if (rec.warnings.any((w) => w.severity == WarningSeverity.critical ||
                  w.severity == WarningSeverity.warning)) ...[
                const SizedBox(height: 12),
                _buildWarningBanner(rec.warnings, isDarkMode),
              ],
              // Пояснение
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nextMeal.reason,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDarkMode,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBanner(List<Warning> warnings, bool isDarkMode) {
    final criticalOrWarning = warnings.where((w) =>
    w.severity == WarningSeverity.critical ||
        w.severity == WarningSeverity.warning).toList();

    if (criticalOrWarning.isEmpty) return const SizedBox.shrink();

    final warning = criticalOrWarning.first;
    final isCritical = warning.severity == WarningSeverity.critical;
    final color = isCritical ? DangerColor : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.error : Icons.warning,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning.message,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет прогресса дня с алгоритмом стабилизации
class StabilizerProgressWidget extends StatelessWidget {
  final HomeFetched state;

  const StabilizerProgressWidget({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profile = state.activeProfile;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Создаём стабилизатор
    final settings = StabilizerSettings(
      targetDailyCalories: profile.caloriesLimitGoal,
      windowHours: profile.wakingTimeSeconds / 3600.0,
      compensationRate: 0.5,
      maxCompensationPerDay: profile.caloriesLimitGoal * 0.15,
    );

    final stabilizer = CalorieStabilizer(settings: settings);

    // Добавляем данные
    final allItems = <CalorieItemModel>[
      ...state.todayCalorieItems,
      ...state.periodCalorieItems,
    ];

    final uniqueItems = <int, CalorieItemModel>{};
    for (final item in allItems) {
      if (item.id != null && item.isEaten()) {
        uniqueItems[item.id!] = item;
      }
    }

    for (final item in uniqueItems.values) {
      stabilizer.addEntry(CalorieEntry(
        timestamp: item.eatenAt ?? item.createdAt,
        calories: item.value,
        note: item.description,
      ));
    }

    // Исторические данные
    final today = DateTime.now();
    for (final day in state.days30) {
      if (day.createdAtDay.year == today.year &&
          day.createdAtDay.month == today.month &&
          day.createdAtDay.day == today.day) {
        continue;
      }
      if (day.valueSum > 0) {
        stabilizer.addEntry(CalorieEntry(
          timestamp: day.createdAtDay.add(const Duration(hours: 12)),
          calories: day.valueSum,
        ));
      }
    }

    final rec = stabilizer.getRecommendation();
    final progressPercent = rec.progressPercent.clamp(0.0, 100.0);
    final isOver = rec.consumed > rec.adjustedTarget;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Прогресс дня',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (rec.compensation > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Цель: ${rec.adjustedTarget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Прогресс бар
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  isOver ? DangerColor : SuccessColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${rec.consumed.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '${progressPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isOver ? DangerColor : SuccessColor,
                  ),
                ),
                Text(
                  '${rec.adjustedTarget.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}