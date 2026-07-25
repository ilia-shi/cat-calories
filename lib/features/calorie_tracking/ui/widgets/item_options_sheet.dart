import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/color_label_dot.dart';
import 'package:cat_calories/common/widgets/color_label_picker.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/calorie_record_row.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Bottom sheet of actions for a single calorie record. Presentational: it
/// pops itself, then invokes the matching callback — the screen owns the work.
/// The colour label is the exception: it applies in place and the sheet stays
/// open, so a mistap can be corrected without reopening the sheet.
class ItemOptionsSheet extends StatefulWidget {
  final CalorieRecord item;

  /// Title of the meal this record belongs to, when [item.mealId] is set.
  final String? mealTitle;

  /// Whether any meal is available to move this record into. False hides the
  /// move tile, so the sheet never offers a picker with nothing to pick.
  final bool canMoveToMeal;

  final VoidCallback onAdjustWeight;
  final VoidCallback onEditValues;
  final VoidCallback onEdit;
  final VoidCallback onToggleEaten;
  final VoidCallback onMoveToMeal;
  final VoidCallback onRemoveFromMeal;
  final VoidCallback onDelete;
  final ValueChanged<ColorLabel?> onColorLabelChanged;

  const ItemOptionsSheet({
    Key? key,
    required this.item,
    required this.mealTitle,
    required this.canMoveToMeal,
    required this.onAdjustWeight,
    required this.onEditValues,
    required this.onEdit,
    required this.onToggleEaten,
    required this.onMoveToMeal,
    required this.onRemoveFromMeal,
    required this.onDelete,
    required this.onColorLabelChanged,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required CalorieRecord item,
    required String? mealTitle,
    required bool canMoveToMeal,
    required VoidCallback onAdjustWeight,
    required VoidCallback onEditValues,
    required VoidCallback onEdit,
    required VoidCallback onToggleEaten,
    required VoidCallback onMoveToMeal,
    required VoidCallback onRemoveFromMeal,
    required VoidCallback onDelete,
    required ValueChanged<ColorLabel?> onColorLabelChanged,
  }) {
    showModalBottomSheet(
      context: context,
      // The palette makes the sheet taller than the default 9/16 of the screen
      // on small devices, so let it size itself and scroll instead of clipping.
      isScrollControlled: true,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => ItemOptionsSheet(
        item: item,
        mealTitle: mealTitle,
        canMoveToMeal: canMoveToMeal,
        onAdjustWeight: onAdjustWeight,
        onEditValues: onEditValues,
        onEdit: onEdit,
        onToggleEaten: onToggleEaten,
        onMoveToMeal: onMoveToMeal,
        onRemoveFromMeal: onRemoveFromMeal,
        onDelete: onDelete,
        onColorLabelChanged: onColorLabelChanged,
      ),
    );
  }

  @override
  State<ItemOptionsSheet> createState() => _ItemOptionsSheetState();
}

class _ItemOptionsSheetState extends State<ItemOptionsSheet> {
  late ColorLabel? _colorLabel;

  @override
  void initState() {
    super.initState();
    _colorLabel = widget.item.colorLabel;
  }

  void _handleColorLabelChanged(ColorLabel? color) {
    setState(() {
      _colorLabel = color;
    });
    widget.onColorLabelChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final item = widget.item;
    final hasWeight = item.weightGrams != null && item.weightGrams! > 0;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
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
                _ItemPreview(item: item, colorLabel: _colorLabel),
                const SizedBox(height: 16),
                _ColorLabelSection(
                  value: _colorLabel,
                  onChanged: _handleColorLabelChanged,
                ),
                const SizedBox(height: 8),
                if (hasWeight)
                  _OptionTile(
                    icon: Icons.scale,
                    color: Colors.teal,
                    title: 'Adjust Weight',
                    subtitle: 'Scale all values proportionally',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAdjustWeight();
                    },
                  ),
                _OptionTile(
                  icon: Icons.calculate,
                  color: Colors.blue,
                  title: 'Edit Values',
                  subtitle: 'Weight, calories and macros on the keypad',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEditValues();
                  },
                ),
                _OptionTile(
                  icon: Icons.edit,
                  color: Colors.blue,
                  title: 'Edit Entry',
                  subtitle: 'Description, time and colour label',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEdit();
                  },
                ),
                _OptionTile(
                  icon: item.isEaten() ? Icons.cancel : Icons.check_circle,
                  color: item.isEaten() ? Colors.orange : SuccessColor,
                  title:
                      item.isEaten() ? 'Mark as Not Eaten' : 'Mark as Eaten',
                  subtitle: item.isEaten()
                      ? 'Remove from today\'s total'
                      : 'Add to today\'s total',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onToggleEaten();
                  },
                ),
                if (widget.canMoveToMeal)
                  _OptionTile(
                    icon: Icons.playlist_add,
                    color: Colors.indigo,
                    title: item.mealId == null
                        ? 'Add to Meal'
                        : 'Move to Another Meal',
                    subtitle: item.mealId == null
                        ? 'Group with an existing meal'
                        : 'Currently: ${widget.mealTitle ?? 'Ungrouped meal'}',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onMoveToMeal();
                    },
                  ),
                if (item.mealId != null)
                  _OptionTile(
                    icon: Icons.playlist_remove,
                    color: Colors.orange,
                    title: 'Remove from Meal',
                    subtitle: widget.mealTitle ?? 'Ungrouped meal',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onRemoveFromMeal();
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
                    widget.onDelete();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorLabelSection extends StatelessWidget {
  final ColorLabel? value;
  final ValueChanged<ColorLabel?> onChanged;

  const _ColorLabelSection({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Color label',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: appColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ColorLabelPicker(
          value: value,
          onChanged: onChanged,
          singleLine: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ],
    );
  }
}

class _ItemPreview extends StatelessWidget {
  final CalorieRecord item;

  /// Passed in rather than read off [item] so the preview follows the sheet's
  /// pending selection while the screen persists it.
  final ColorLabel? colorLabel;

  const _ItemPreview({required this.item, required this.colorLabel});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final dotColor = colorLabel;
    final hasMacros = item.proteinGrams != null ||
        item.fatGrams != null ||
        item.carbGrams != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: appColors.surfaceSubtle,
        shape: AppCard.squircleBorder(radius: 12),
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
                    Row(
                      children: [
                        Text(
                          '${item.value >= 0 ? '+' : ''}${item.value.toStringAsFixed(0)} kcal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.value > 0 ? DangerColor : SuccessColor,
                          ),
                        ),
                        // On the value line, not next to the description, so a
                        // labelled record without a description still shows it.
                        if (dotColor != null) ...[
                          const SizedBox(width: 8),
                          ColorLabelDot(color: dotColor),
                        ],
                      ],
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
