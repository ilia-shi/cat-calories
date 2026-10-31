import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/days_screen.dart';
import 'package:flutter/material.dart';

/// Points at days counted as 0 kcal that the user may want to mark as not
/// tracked. Renders nothing when there are none.
class EmptyDaysRow extends StatelessWidget {
  final int count;

  const EmptyDaysRow({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }
    final appColors = AppColors.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DaysScreen()),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_outlined,
              size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'day' : 'days'} without records',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: appColors.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: appColors.textDisabled),
        ],
      ),
    );
  }
}
