import 'package:cat_calories/common/theme/colors.dart';
import 'package:flutter/material.dart';

/// Placeholder shown in the calorie history when no records exist yet.
class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: appColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: 64,
              color: appColors.textDisabled,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No calories recorded yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your calories\nto see your history here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: appColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
