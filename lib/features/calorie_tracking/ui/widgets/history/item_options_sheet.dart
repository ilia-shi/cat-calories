import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/calorie_record_row.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Bottom sheet of actions for a single calorie record. Presentational: it
/// pops itself, then invokes the matching callback — the screen owns the work.
class ItemOptionsSheet extends StatelessWidget {
  final CalorieRecord item;

  /// Title of the meal this record belongs to, when [item.mealId] is set.
  final String? mealTitle;

  final VoidCallback onAdjustWeight;
  final VoidCallback onEdit;
  final VoidCallback onToggleEaten;
  final VoidCallback onRemoveFromMeal;
  final VoidCallback onDelete;

  const ItemOptionsSheet({
    Key? key,
    required this.item,
    required this.mealTitle,
    required this.onAdjustWeight,
    required this.onEdit,
    required this.onToggleEaten,
    required this.onRemoveFromMeal,
    required this.onDelete,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required CalorieRecord item,
    required String? mealTitle,
    required VoidCallback onAdjustWeight,
    required VoidCallback onEdit,
    required VoidCallback onToggleEaten,
    required VoidCallback onRemoveFromMeal,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ItemOptionsSheet(
        item: item,
        mealTitle: mealTitle,
        onAdjustWeight: onAdjustWeight,
        onEdit: onEdit,
        onToggleEaten: onToggleEaten,
        onRemoveFromMeal: onRemoveFromMeal,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final hasWeight = item.weightGrams != null && item.weightGrams! > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: appColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _ItemPreview(item: item),
            const SizedBox(height: 8),
            if (hasWeight)
              _OptionTile(
                icon: Icons.scale,
                color: Colors.teal,
                title: 'Adjust Weight',
                subtitle: 'Scale all values proportionally',
                onTap: () {
                  Navigator.pop(context);
                  onAdjustWeight();
                },
              ),
            _OptionTile(
              icon: Icons.edit,
              color: Colors.blue,
              title: 'Edit Entry',
              subtitle: 'Modify calories or description',
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            _OptionTile(
              icon: item.isEaten() ? Icons.cancel : Icons.check_circle,
              color: item.isEaten() ? Colors.orange : SuccessColor,
              title: item.isEaten() ? 'Mark as Not Eaten' : 'Mark as Eaten',
              subtitle: item.isEaten()
                  ? 'Remove from today\'s total'
                  : 'Add to today\'s total',
              onTap: () {
                Navigator.pop(context);
                onToggleEaten();
              },
            ),
            if (item.mealId != null)
              _OptionTile(
                icon: Icons.playlist_remove,
                color: Colors.orange,
                title: 'Remove from Meal',
                subtitle: mealTitle ?? 'Ungrouped meal',
                onTap: () {
                  Navigator.pop(context);
                  onRemoveFromMeal();
                },
              ),
            _OptionTile(
              icon: Icons.delete,
              color: DangerColor,
              title: 'Delete Entry',
              titleColor: DangerColor,
              subtitle: 'Permanently remove this entry',
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ItemPreview extends StatelessWidget {
  final CalorieRecord item;

  const _ItemPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final hasMacros = item.proteinGrams != null ||
        item.fatGrams != null ||
        item.carbGrams != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: item.value > 0 ? DangerColor : SuccessColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.value >= 0 ? '+' : ''}${item.value.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.value > 0 ? DangerColor : SuccessColor,
                      ),
                    ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, HH:mm').format(item.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: appColors.textTertiary,
                ),
              ),
            ],
          ),
          if (hasMacros) ...[
            const SizedBox(height: 8),
            CalorieRecordMacros(item: item),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: appColors.tintedSurface(color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: titleColor == null ? null : TextStyle(color: titleColor),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
