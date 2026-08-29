import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/planned_day_chips.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';

class MealOptionsSheet extends StatelessWidget {
  final Meal meal;
  final List<CalorieRecord> members;
  final VoidCallback onCookingMode;
  final VoidCallback onDuplicate;
  final VoidCallback onEdit;
  final VoidCallback onMoveToDay;
  final VoidCallback onMarkEaten;
  final VoidCallback onMarkNotEaten;
  final VoidCallback onUngroup;
  final VoidCallback onDelete;

  const MealOptionsSheet({
    Key? key,
    required this.meal,
    required this.members,
    required this.onCookingMode,
    required this.onDuplicate,
    required this.onEdit,
    required this.onMoveToDay,
    required this.onMarkEaten,
    required this.onMarkNotEaten,
    required this.onUngroup,
    required this.onDelete,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required Meal meal,
    required List<CalorieRecord> members,
    required VoidCallback onCookingMode,
    required VoidCallback onDuplicate,
    required VoidCallback onEdit,
    required VoidCallback onMoveToDay,
    required VoidCallback onMarkEaten,
    required VoidCallback onMarkNotEaten,
    required VoidCallback onUngroup,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      // An uneaten meal adds a tile, pushing the sheet past the default 9/16 of
      // the screen, so let it size itself and scroll instead of clipping.
      isScrollControlled: true,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => MealOptionsSheet(
        meal: meal,
        members: members,
        onCookingMode: onCookingMode,
        onDuplicate: onDuplicate,
        onEdit: onEdit,
        onMoveToDay: onMoveToDay,
        onMarkEaten: onMarkEaten,
        onMarkNotEaten: onMarkNotEaten,
        onUngroup: onUngroup,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final hasUneaten = members.any((r) => !r.isEaten());
    final hasEaten = meal.isEaten() || members.any((r) => r.isEaten());
    // Once the meal is eaten it belongs to the day it was eaten on, so a
    // planned day would no longer decide anything — offering to change it
    // would be a control that does nothing visible. "Mark as not eaten" is
    // the way back to it.
    final canMoveDay = !meal.isEaten();

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
                ListTile(
                  leading: Icon(Icons.restaurant,
                      color: Theme.of(context).primaryColor),
                  title: Text(
                    meal.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${members.length} items'
                    '${meal.notes?.trim().isNotEmpty == true ? ' · ${meal.notes}' : ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: appColors.textSecondary),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.soup_kitchen,
                      color: Colors.teal, size: 20),
                  title: const Text('Cooking Mode'),
                  subtitle: const Text(
                      'Adjust weights and ingredients while cooking'),
                  onTap: () {
                    Navigator.pop(context);
                    onCookingMode();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_all,
                      color: Colors.indigo, size: 20),
                  title: const Text('Duplicate Meal (cook again)'),
                  subtitle: const Text(
                      'New planned meal with the same ingredients and weights'),
                  onTap: () {
                    Navigator.pop(context);
                    onDuplicate();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  title: const Text('Rename / Edit Notes'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                if (canMoveDay)
                  ListTile(
                    leading: const Icon(Icons.event_repeat,
                        color: Colors.purple, size: 20),
                    title: const Text('Move to Another Day'),
                    subtitle: Text(
                      meal.plannedFor == null
                          ? 'Plan it for a specific day'
                          : 'Planned for '
                              '${PlannedDayChips.labelFor(meal.plannedFor!)}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onMoveToDay();
                    },
                  ),
                if (hasUneaten)
                  ListTile(
                    leading: const Icon(Icons.check_circle,
                        color: SuccessColor, size: 20),
                    title: const Text('Mark Meal as Eaten'),
                    subtitle: const Text('Stamps all its records at once'),
                    onTap: () {
                      Navigator.pop(context);
                      onMarkEaten();
                    },
                  ),
                if (hasEaten)
                  ListTile(
                    leading: const Icon(Icons.restore,
                        color: Colors.orange, size: 20),
                    title: const Text('Mark as Not Eaten'),
                    subtitle: const Text(
                        'Back to planned, so it can be moved to another day'),
                    onTap: () {
                      Navigator.pop(context);
                      onMarkNotEaten();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.playlist_remove,
                      color: Colors.orange, size: 20),
                  title: const Text('Ungroup Meal'),
                  subtitle:
                      const Text('Records stay, only the group is removed'),
                  onTap: () {
                    Navigator.pop(context);
                    onUngroup();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: DangerColor, size: 20),
                  title: const Text('Delete Meal'),
                  subtitle: Text(
                    'Removes the group and its '
                    '${members.length == 1 ? '1 record' : '${members.length} records'}',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
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
