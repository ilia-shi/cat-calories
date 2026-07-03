import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/meal_signal_inputs.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The laziness-contract rating surface: a small dismissible card listing
/// unrated meals eaten in the last 48h. Never blocks anything; dismissing is
/// permanent for the listed meals (per-device, SharedPreferences). Renders
/// nothing when there is nothing to rate.
class RateMealsRow extends StatefulWidget {
  const RateMealsRow({super.key});

  @override
  State<RateMealsRow> createState() => _RateMealsRowState();
}

class _RateMealsRowState extends State<RateMealsRow> {
  static const String _dismissedKey = 'meal_rating_dismissed_ids';
  static const Duration _window = Duration(hours: 48);

  final _mealRepo = locator.get<MealRepositoryInterface>();
  List<Meal> _unrated = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileResolver().resolve();
    final meals = await _mealRepo.fetchByProfile(profile);
    final prefs = await SharedPreferences.getInstance();
    final dismissed = (prefs.getStringList(_dismissedKey) ?? []).toSet();
    final now = DateTime.now();

    final unrated = meals.where((meal) {
      if (meal.id == null || dismissed.contains(meal.id)) {
        return false;
      }
      if (meal.tasteRating != null || meal.satietyRating != null) {
        return false;
      }
      final eatenAt = meal.eatenAt;
      return eatenAt != null && now.difference(eatenAt) <= _window;
    }).toList();

    if (mounted) {
      setState(() => _unrated = unrated);
    }
  }

  Future<void> _dismissAll() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = (prefs.getStringList(_dismissedKey) ?? []).toSet()
      ..addAll(_unrated.map((meal) => meal.id!));
    await prefs.setStringList(_dismissedKey, dismissed.toList());
    if (mounted) {
      setState(() => _unrated = []);
    }
  }

  Future<void> _rateMeal(Meal meal) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => _RateMealSheet(meal: meal, mealRepo: _mealRepo),
    );
    if (saved == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unrated.isEmpty) {
      return const SizedBox.shrink();
    }
    final appColors = AppColors.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_outline,
                  size: 18, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rate recent meals',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    size: 18, color: appColors.textDisabled),
                tooltip: 'Dismiss (won\'t ask again for these meals)',
                onPressed: _dismissAll,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final meal in _unrated)
                GestureDetector(
                  onTap: () => _rateMeal(meal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: ShapeDecoration(
                      color: appColors.surfaceMuted,
                      shape: AppCard.squircleBorder(
                        radius: 10,
                        side: BorderSide(color: appColors.border),
                      ),
                    ),
                    child: Text(
                      meal.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: appColors.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two 5-dot rows (taste, "how long did it keep you full") + optional note.
class _RateMealSheet extends StatefulWidget {
  final Meal meal;
  final MealRepositoryInterface mealRepo;

  const _RateMealSheet({required this.meal, required this.mealRepo});

  @override
  State<_RateMealSheet> createState() => _RateMealSheetState();
}

class _RateMealSheetState extends State<_RateMealSheet> {
  late int? _taste = widget.meal.tasteRating;
  late int? _satiety = widget.meal.satietyRating;
  late final TextEditingController _noteController =
      TextEditingController(text: widget.meal.notes ?? '');

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final meal = widget.meal;
    meal.tasteRating = _taste;
    meal.satietyRating = _satiety;
    final note = _noteController.text.trim();
    meal.notes = note.isEmpty ? null : note;
    meal.updatedAt = DateTime.now();
    await widget.mealRepo.update(meal);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.meal.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RatingDots(
              label: 'Taste',
              value: _taste,
              onChanged: (value) => setState(() => _taste = value),
            ),
            const SizedBox(height: 4),
            RatingDots(
              label: 'Filling',
              value: _satiety,
              onChanged: (value) => setState(() => _satiety = value),
            ),
            const SizedBox(height: 4),
            Text(
              'Filling = how long it kept you full',
              style: TextStyle(fontSize: 11, color: appColors.textTertiary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional, goes into the LLM export)',
                hintText: 'e.g., less oil next time',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: AppCard.squircleBorder(radius: 12),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
