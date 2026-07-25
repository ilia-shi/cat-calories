import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_header_row.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';

/// A meal's header plus its member records, enclosed in one tinted, outlined
/// block so it reads as a single unit against the ungrouped rows around it.
///
/// [rows] are built by the owning screen so record tap handling stays there;
/// they must carry no divider of their own — the block separates them with an
/// accent-tinted line, since the rows' own subtle grey divider disappears
/// against the tinted background.
class MealGroupBlock extends StatelessWidget {
  /// Inset from the day card on all four sides. The block's corner radius is
  /// [AppCard.defaultBorderRadius] minus this, so it stays concentric with the
  /// card when a meal is the day's first or last entry.
  static const double _inset = 8;

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
      radius: AppCard.defaultBorderRadius - _inset,
      side: BorderSide(
        color: accent.withValues(alpha: appColors.isDark ? 0.5 : 0.3),
      ),
    );

    return Container(
      margin: const EdgeInsets.all(_inset),
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
