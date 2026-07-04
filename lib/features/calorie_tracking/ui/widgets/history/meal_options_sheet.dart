import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';

/// Bottom sheet of actions for a meal group. Presentational: it pops itself,
/// then invokes the matching callback — the screen owns the work.
class MealOptionsSheet extends StatelessWidget {
  final Meal meal;
  final List<CalorieRecord> members;
  final VoidCallback onCookingMode;
  final VoidCallback onDuplicate;
  final VoidCallback onEdit;
  final VoidCallback onMarkEaten;
  final VoidCallback onUngroup;

  const MealOptionsSheet({
    Key? key,
    required this.meal,
    required this.members,
    required this.onCookingMode,
    required this.onDuplicate,
    required this.onEdit,
    required this.onMarkEaten,
    required this.onUngroup,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required Meal meal,
    required List<CalorieRecord> members,
    required VoidCallback onCookingMode,
    required VoidCallback onDuplicate,
    required VoidCallback onEdit,
    required VoidCallback onMarkEaten,
    required VoidCallback onUngroup,
  }) {
    showModalBottomSheet(
      context: context,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => MealOptionsSheet(
        meal: meal,
        members: members,
        onCookingMode: onCookingMode,
        onDuplicate: onDuplicate,
        onEdit: onEdit,
        onMarkEaten: onMarkEaten,
        onUngroup: onUngroup,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final hasUneaten = members.any((r) => !r.isEaten());

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  Icon(Icons.restaurant, color: Theme.of(context).primaryColor),
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
              leading:
                  const Icon(Icons.soup_kitchen, color: Colors.teal, size: 20),
              title: const Text('Cooking Mode'),
              subtitle:
                  const Text('Adjust weights and ingredients while cooking'),
              onTap: () {
                Navigator.pop(context);
                onCookingMode();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.copy_all, color: Colors.indigo, size: 20),
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
            ListTile(
              leading: const Icon(Icons.playlist_remove,
                  color: Colors.orange, size: 20),
              title: const Text('Ungroup Meal'),
              subtitle: const Text('Records stay, only the group is removed'),
              onTap: () {
                Navigator.pop(context);
                onUngroup();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
