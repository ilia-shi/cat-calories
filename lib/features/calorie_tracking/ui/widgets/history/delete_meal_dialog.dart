import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';

/// Confirmation dialog for deleting a meal together with its records. Pops
/// itself on confirm, then invokes [onConfirm].
class DeleteMealDialog extends StatelessWidget {
  final Meal meal;
  final int recordCount;
  final double totalCalories;
  final VoidCallback onConfirm;

  const DeleteMealDialog({
    Key? key,
    required this.meal,
    required this.recordCount,
    required this.totalCalories,
    required this.onConfirm,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required Meal meal,
    required int recordCount,
    required double totalCalories,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => DeleteMealDialog(
        meal: meal,
        recordCount: recordCount,
        totalCalories: totalCalories,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: AppCard.squircleBorder(radius: 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: DangerColor.withValues(alpha: 0.1),
              shape: AppCard.squircleBorder(radius: 8),
            ),
            child: const Icon(Icons.delete_outline, color: DangerColor),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Delete Meal')),
        ],
      ),
      content: Text(
        'Delete "${meal.title}" and ${recordCount == 1 ? 'its 1 record' : 'all $recordCount of its records'} '
        '(${totalCalories.toStringAsFixed(0)} kcal)?\n\n'
        'This action cannot be undone. To keep the records, ungroup the meal '
        'instead.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DangerColor,
            shape: AppCard.squircleBorder(radius: 8),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
