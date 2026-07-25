import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_header_row.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';

class MealGroupBlock extends StatelessWidget {
  static const double _inset = 0;

  final Meal meal;
  final List<CalorieRecord> records;
  final VoidCallback onHeaderTap;
  final List<Widget> rows;

  const MealGroupBlock({
    Key? key,
    required this.meal,
    required this.records,
    required this.onHeaderTap,
    required this.rows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final accent = Theme.of(context).primaryColor;
    final shape = AppCard.squircleBorder(
      radius: 0,
      side: BorderSide(
        color: accent.withValues(alpha: appColors.isDark ? 0.3 : 0.3),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: _inset, horizontal: 0),
      decoration: ShapeDecoration(
        color: accent.withValues(alpha: appColors.isDark ? 0.10 : 0.07),
        shape: shape,
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            MealHeaderRow(
              meal: meal,
              records: records,
              onTap: onHeaderTap,
            ),
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Container(
                  height: 1,
                  color: accent.withValues(alpha: appColors.isDark ? 0.3 : 0.2),
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}
