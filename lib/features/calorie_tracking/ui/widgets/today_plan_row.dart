import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/meal_cooking_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/state/meal_eating.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_totals.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/planned_meals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What is still to be eaten today, with the one action that matters on it.
/// Without this the plan lives only in the history screen, so a meal cooked
/// ahead has to be hunted down to be marked eaten. Renders nothing when nothing
/// is planned for today.
class TodayPlanRow extends StatefulWidget {
  const TodayPlanRow({super.key});

  @override
  State<TodayPlanRow> createState() => _TodayPlanRowState();
}

class _TodayPlanRowState extends State<TodayPlanRow> {
  final _mealRepo = locator.get<MealRepositoryInterface>();
  final _recordRepo = locator.get<CalorieRecordRepositoryInterface>();

  List<PlannedMeal> _planned = [];

  late final MealEating _eating = MealEating(
    mealRepository: _mealRepo,
    recordRepository: _recordRepo,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileResolver().resolve();
    final meals = await _mealRepo.fetchByProfile(profile);
    final records = await _recordRepo.fetchAllByProfile(profile);

    if (mounted) {
      setState(() {
        _planned = plannedMealsOn(
          DateTime.now(),
          meals: meals,
          records: records,
        );
      });
    }
  }

  Future<void> _markEaten(PlannedMeal planned) async {
    await _eating.markEaten(planned.meal, planned.records);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${planned.meal.title}" marked as eaten'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // The day totals and every other surface read the same records.
    BlocProvider.of<HomeBloc>(context)
        .add(CalorieItemListFetchingInProgressEvent());
    await _load();
  }

  Future<void> _openCooking(PlannedMeal planned) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MealCookingScreen(planned.meal)),
    );
    if (mounted) {
      BlocProvider.of<HomeBloc>(context)
          .add(CalorieItemListFetchingInProgressEvent());
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Anything that changes a record elsewhere lands here as a refetch.
    return BlocListener<HomeBloc, AbstractHomeState>(
      listener: (context, state) {
        if (state is HomeFetched) {
          _load();
        }
      },
      child: _planned.isEmpty
          ? const SizedBox.shrink()
          : TodayPlanCard(
              planned: _planned,
              onEaten: _markEaten,
              onOpen: _openCooking,
            ),
    );
  }
}

/// The card itself, given the day's plan. Separate from the loading around it
/// so it can be built from a plain list.
class TodayPlanCard extends StatelessWidget {
  final List<PlannedMeal> planned;
  final ValueChanged<PlannedMeal> onEaten;
  final ValueChanged<PlannedMeal> onOpen;

  const TodayPlanCard({
    super.key,
    required this.planned,
    required this.onEaten,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final total = planned.fold<double>(
      0,
      (sum, entry) => sum + MealTotals.of(entry.records).kcal,
    );

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule,
                  size: 18, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Planned for today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${total.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: appColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final entry in planned)
            _PlannedMealRow(
              planned: entry,
              onEaten: () => onEaten(entry),
              onOpen: () => onOpen(entry),
            ),
        ],
      ),
    );
  }
}

class _PlannedMealRow extends StatelessWidget {
  final PlannedMeal planned;
  final VoidCallback onEaten;
  final VoidCallback onOpen;

  const _PlannedMealRow({
    required this.planned,
    required this.onEaten,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final totals = MealTotals.of(planned.records);
    final count = planned.records.length;

    return InkWell(
      onTap: onOpen,
      customBorder: AppCard.squircleBorder(radius: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planned.meal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${count == 1 ? 'item' : 'items'} · '
                    '${totals.kcal.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onEaten,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: SuccessColor,
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Eaten'),
            ),
          ],
        ),
      ),
    );
  }
}
