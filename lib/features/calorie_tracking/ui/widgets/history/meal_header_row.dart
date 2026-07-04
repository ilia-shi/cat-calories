import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';

/// Header row above a meal's member records in the day list.
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
    final total = records.fold<double>(0, (sum, r) => sum + r.value);
    final hasUneaten = records.any((r) => !r.isEaten());

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: appColors.surfaceMuted,
          border: Border(bottom: BorderSide(color: appColors.borderSubtle)),
        ),
        child: Row(
          children: [
            Icon(Icons.restaurant,
                size: 16, color: Theme.of(context).primaryColor),
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
            if (hasUneaten) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: ShapeDecoration(
                  color: appColors.border,
                  shape: AppCard.squircleBorder(radius: 6),
                ),
                child: Text(
                  'planned',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: appColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${records.length} items · ${total.toStringAsFixed(0)} kcal',
              style: TextStyle(
                fontSize: 12,
                color: appColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.more_horiz, size: 16, color: appColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
