import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/planned_day_chips.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:flutter/material.dart';

/// Reschedules a planned meal. Resolves to the chosen day — null meaning no
/// particular day — or to nothing at all when the user backs out.
class MoveMealDaySheet extends StatefulWidget {
  final Meal meal;
  final List<CalorieRecord> members;

  const MoveMealDaySheet({
    super.key,
    required this.meal,
    required this.members,
  });

  /// Resolves to a one-element list holding the chosen day (or null for no
  /// particular day), and to null when dismissed — the two outcomes have to
  /// stay distinguishable, since "no day" is itself a choice here.
  static Future<List<DateTime?>?> show(
    BuildContext context, {
    required Meal meal,
    required List<CalorieRecord> members,
  }) {
    return showModalBottomSheet<List<DateTime?>>(
      context: context,
      isScrollControlled: true,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => MoveMealDaySheet(meal: meal, members: members),
    );
  }

  @override
  State<MoveMealDaySheet> createState() => _MoveMealDaySheetState();
}

class _MoveMealDaySheetState extends State<MoveMealDaySheet> {
  late DateTime? _day = widget.meal.plannedFor;

  /// Eaten ingredients do not follow the meal: each belongs to the day it was
  /// eaten on. Naming that before the move is what keeps the resulting split
  /// across two day cards from looking like a bug.
  String? get _splitWarning {
    final eaten = widget.members.where((r) => r.isEaten()).toList();
    if (eaten.isEmpty) {
      return null;
    }
    final moving = widget.members.length - eaten.length;
    final target = _day == null
        ? 'no particular day'
        : PlannedDayChips.labelFor(_day!);
    final eatenDays = eaten.map(recordDay).toSet();
    final staying = eatenDays.length == 1
        ? 'stay on ${PlannedDayChips.labelFor(eatenDays.single)}'
        : 'stay on the days they were eaten';

    return 'Moves $moving of ${widget.members.length} ingredients to $target — '
        '${eaten.length} already eaten $staying.';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final warning = _splitWarning;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Move "${widget.meal.title}"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To which day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            PlannedDayChips(
              day: _day,
              onChanged: (day) => setState(() => _day = day),
            ),
            if (warning != null) ...[
              const SizedBox(height: 14),
              Text(
                warning,
                style: TextStyle(fontSize: 12, color: appColors.textTertiary),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop([_day]),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: AppCard.squircleBorder(radius: 14),
                ),
                child: const Text('Move'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
