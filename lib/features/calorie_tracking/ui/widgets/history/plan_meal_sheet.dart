import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/planned_day_chips.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A planned meal's name and the day it is meant for.
class PlanMealResult {
  final String title;
  final DateTime? plannedFor;

  const PlanMealResult({required this.title, required this.plannedFor});
}

/// Asks for a meal's name and the day it is for, in one sheet. Today is
/// preselected, so planning for right now costs no extra tap.
class PlanMealSheet extends StatefulWidget {
  final String? initialTitle;

  const PlanMealSheet({super.key, this.initialTitle});

  /// Resolves to the entered name and day, or null when the user backs out.
  static Future<PlanMealResult?> show(
    BuildContext context, {
    String? initialTitle,
  }) {
    return showModalBottomSheet<PlanMealResult>(
      context: context,
      isScrollControlled: true,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => PlanMealSheet(initialTitle: initialTitle),
    );
  }

  @override
  State<PlanMealSheet> createState() => _PlanMealSheetState();
}

class _PlanMealSheetState extends State<PlanMealSheet> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.initialTitle ?? '');

  /// Today, so its chip reads as chosen from the start. It is normalised back
  /// to null on submit — "today" and "no particular day" are the same thing to
  /// everything downstream, and the column stays empty for the common case.
  DateTime? _day = PlannedDayChips.dayFromToday(0);

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// The day the meal actually lands on, which is today whenever no chip is
  /// chosen — used for the fallback title, so an unnamed meal still says when.
  DateTime get _effectiveDay => _day ?? PlannedDayChips.dayFromToday(0);

  void _submit() {
    final typed = _titleController.text.trim();
    Navigator.of(context).pop(PlanMealResult(
      title: typed.isEmpty
          ? 'Meal for ${DateFormat('EEE d MMM').format(_effectiveDay)}'
          : typed,
      plannedFor: _day == PlannedDayChips.dayFromToday(0) ? null : _day,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return Padding(
      // Lifts the sheet clear of the keyboard the name field raises.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan a meal',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Meal name (optional)',
                  hintText: 'e.g., Chicken curry',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'For which day',
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: AppCard.squircleBorder(radius: 14),
                  ),
                  child: const Text('Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
