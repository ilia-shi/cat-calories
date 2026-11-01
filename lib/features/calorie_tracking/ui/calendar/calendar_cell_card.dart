import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_bars.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_item.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_labels.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_macro_lines.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:flutter/material.dart';

class CalendarCellCard extends StatelessWidget {
  static const double height = 128;
  static const double _barsHeight = 32;
  static final _shape = AppCard.squircleBorder(radius: 10);

  final CalendarItem item;

  const CalendarCellCard({super.key, required this.item});

  static double widthFor(CalendarMode mode) {
    return mode == CalendarMode.months ? 96 : 56;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final macros = item.macros;

    return Material(
      color: appColors.surfaceMuted,
      shape: _shape,
      child: InkWell(
        customBorder: _shape,
        onTap: () => item.openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  shortPeriodLabel(item.start, item.mode),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    color: appColors.textSecondary,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              CalendarBars(
                bars: item.bars,
                showGoalLine: item.showGoalLine,
                height: _barsHeight,
              ),
              if (macros != null) ...[
                const SizedBox(height: 4),
                CalendarMacroLines(cell: macros),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
