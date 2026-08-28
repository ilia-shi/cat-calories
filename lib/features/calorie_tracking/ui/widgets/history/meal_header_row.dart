import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/meal_totals_strip.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_totals.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MealHeaderRow extends StatelessWidget {
  final Meal meal;
  final List<CalorieRecord> records;
  final VoidCallback onTap;

  const MealHeaderRow({
    Key? key,
    required this.meal,
    required this.records,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final accent = Theme.of(context).primaryColor;
    final totals = MealTotals.of(records);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: appColors.isDark ? 0.20 : 0.13),
          border: Border(
            bottom: BorderSide(
              color: accent.withValues(alpha: appColors.isDark ? 0.4 : 0.25),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: appColors.textPrimary,
                    ),
                  ),
                ),
                if (records.any((r) => !r.isEaten())) ...[
                  const SizedBox(width: 8),
                  _PlannedBadge(plannedFor: meal.plannedFor),
                ],
              ],
            ),
            const SizedBox(height: 6),
            _MealTotalsLine(records: records, totals: totals),
          ],
        ),
      ),
    );
  }
}

/// The second line of the header: the meal's macros and weight, then its item
/// count and kcal. One uninterrupted reading, so a narrow screen scales the
/// macro strip down rather than pushing the count onto a line of its own.
class _MealTotalsLine extends StatelessWidget {
  final List<CalorieRecord> records;
  final MealTotals totals;

  const _MealTotalsLine({required this.records, required this.totals});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return Row(
      children: [
        if (totals.hasMacros) ...[
          Flexible(child: MealTotalsStrip(totals: totals)),
          const SizedBox(width: 10),
        ],
        Text(
          '${records.length} items · ${totals.kcal.toStringAsFixed(0)} kcal',
          style: TextStyle(
            fontSize: 12,
            color: appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Marks a meal that still holds records nobody has eaten yet, naming the day
/// it is meant for once one is set.
class _PlannedBadge extends StatelessWidget {
  final DateTime? plannedFor;

  const _PlannedBadge({required this.plannedFor});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final day = plannedFor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: ShapeDecoration(
        color: appColors.border,
        shape: AppCard.squircleBorder(radius: 6),
      ),
      child: Text(
        day == null
            ? 'planned'
            : 'for ${DateFormat('EEE d MMM').format(day)}',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: appColors.textSecondary,
        ),
      ),
    );
  }
}
