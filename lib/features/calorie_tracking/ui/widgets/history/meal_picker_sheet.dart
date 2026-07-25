import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';

/// Picks the meal a record should move into. Presentational: it pops with the
/// chosen [Meal] (or null when dismissed) and the screen does the moving.
///
/// [meals] is the candidate list the caller has already filtered — the sheet
/// shows exactly what it is given.
class MealPickerSheet extends StatefulWidget {
  /// Above this many candidates the list gets a search field; below it,
  /// scanning the list is faster than typing.
  static const int _searchThreshold = 8;

  final CalorieRecord item;
  final List<Meal> meals;
  final Map<String, List<CalorieRecord>> membersByMeal;

  const MealPickerSheet({
    Key? key,
    required this.item,
    required this.meals,
    required this.membersByMeal,
  }) : super(key: key);

  static Future<Meal?> show(
    BuildContext context, {
    required CalorieRecord item,
    required List<Meal> meals,
    required Map<String, List<CalorieRecord>> membersByMeal,
  }) {
    return showModalBottomSheet<Meal>(
      context: context,
      isScrollControlled: true,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => MealPickerSheet(
        item: item,
        meals: meals,
        membersByMeal: membersByMeal,
      ),
    );
  }

  @override
  State<MealPickerSheet> createState() => _MealPickerSheetState();
}

class _MealPickerSheetState extends State<MealPickerSheet> {
  String _query = '';

  List<Meal> get _visibleMeals {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.meals;
    }
    return widget.meals
        .where((meal) => meal.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final meals = _visibleMeals;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Padding(
          // Lift the sheet above the keyboard, or searching hides the results.
          padding: EdgeInsets.only(
            top: 8,
            bottom: 8 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PickerHeader(item: widget.item),
              if (widget.meals.length > MealPickerSheet._searchThreshold)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    autofocus: false,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search, size: 20),
                      hintText: 'Search meals',
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              const SizedBox(height: 8),
              Flexible(
                child: meals.isEmpty
                    ? _EmptyResult(query: _query)
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];
                          return _MealTile(
                            meal: meal,
                            members: widget.membersByMeal[meal.id] ??
                                const <CalorieRecord>[],
                            onTap: () => Navigator.pop(context, meal),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Handle bar, sheet title and a one-line reminder of which record is moving.
class _PickerHeader extends StatelessWidget {
  final CalorieRecord item;

  const _PickerHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: ShapeDecoration(
              color: appColors.border,
              shape: AppCard.squircleBorder(radius: 2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move to meal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _label(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _label() {
    final calories = '${item.value >= 0 ? '+' : ''}'
        '${item.value.toStringAsFixed(0)} kcal';
    final description = item.description;
    if (description == null || description.isEmpty) {
      return calories;
    }
    return '$description · $calories';
  }
}

class _MealTile extends StatelessWidget {
  final Meal meal;
  final List<CalorieRecord> members;
  final VoidCallback onTap;

  const _MealTile({
    required this.meal,
    required this.members,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final accent = Theme.of(context).primaryColor;
    final total = members.fold<double>(0, (sum, r) => sum + r.value);
    final hasUneaten = members.any((r) => !r.isEaten());

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: ShapeDecoration(
          color: appColors.tintedSurface(accent),
          shape: AppCard.squircleBorder(radius: 8),
        ),
        child: Icon(Icons.restaurant, color: accent, size: 20),
      ),
      title: Text(
        meal.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        members.isEmpty
            ? 'No items yet'
            : '${members.length} items · ${total.toStringAsFixed(0)} kcal',
      ),
      trailing: hasUneaten || members.isEmpty
          ? _PlannedChip(eaten: meal.isEaten())
          : null,
      onTap: onTap,
    );
  }
}

/// Mirrors the badge on [MealHeaderRow], so a meal reads the same in the picker
/// as it does in the history.
class _PlannedChip extends StatelessWidget {
  final bool eaten;

  const _PlannedChip({required this.eaten});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: ShapeDecoration(
        color: appColors.border,
        shape: AppCard.squircleBorder(radius: 6),
      ),
      child: Text(
        eaten ? 'partly eaten' : 'planned',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: appColors.textSecondary,
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final String query;

  const _EmptyResult({required this.query});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Text(
        query.trim().isEmpty
            ? 'No meals to move this entry into.'
            : 'No meals match "$query".',
        textAlign: TextAlign.center,
        style: TextStyle(color: appColors.textSecondary),
      ),
    );
  }
}
