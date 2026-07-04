import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:flutter/material.dart';

/// Confirmation dialog for deleting a single calorie record. Pops itself on
/// confirm, then invokes [onConfirm].
class DeleteEntryDialog extends StatelessWidget {
  final CalorieRecord item;
  final VoidCallback onConfirm;

  const DeleteEntryDialog({
    Key? key,
    required this.item,
    required this.onConfirm,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required CalorieRecord item,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => DeleteEntryDialog(item: item, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DangerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_outline, color: DangerColor),
          ),
          const SizedBox(width: 12),
          const Text('Delete Entry'),
        ],
      ),
      content: Text(
        'Are you sure you want to delete this ${item.value.toStringAsFixed(0)} kcal entry?\n\nThis action cannot be undone.',
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
