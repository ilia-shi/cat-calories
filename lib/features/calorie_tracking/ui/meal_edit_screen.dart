import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/app_top_bar.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/meal_signal_inputs.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/planned_day_chips.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The edited fields collected by [MealEditScreen]. [title] is null when the
/// field was left blank (keep the existing title); [notes] is null when empty;
/// [plannedFor] is null when the meal is for no particular day.
class MealEditResult {
  final String? title;
  final String? notes;
  final DateTime? plannedFor;
  final int? cookingMinutes;
  final int? tasteRating;
  final int? satietyRating;

  const MealEditResult({
    required this.title,
    required this.notes,
    required this.plannedFor,
    required this.cookingMinutes,
    required this.tasteRating,
    required this.satietyRating,
  });
}

/// Screen to rename a meal and edit its notes and cooking signals. Gathers the
/// values and hands them back through [Navigator.pop]; persistence is the
/// caller's job.
class MealEditScreen extends StatefulWidget {
  final Meal meal;

  const MealEditScreen(this.meal, {super.key});

  /// Pushes the screen and resolves to the edited fields, or null when the user
  /// left without saving.
  static Future<MealEditResult?> push(BuildContext context, Meal meal) {
    return Navigator.of(context).push<MealEditResult>(
      MaterialPageRoute(builder: (_) => MealEditScreen(meal)),
    );
  }

  @override
  State<MealEditScreen> createState() => _MealEditScreenState();
}

class _MealEditScreenState extends State<MealEditScreen> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.meal.title);
  late final TextEditingController _notesController =
      TextEditingController(text: widget.meal.notes ?? '');
  late DateTime? _plannedFor = widget.meal.plannedFor;
  late int? _cookingMinutes = widget.meal.cookingMinutes;
  late int? _tasteRating = widget.meal.tasteRating;
  late int? _satietyRating = widget.meal.satietyRating;

  @override
  void initState() {
    super.initState();
    // Typing has to repaint the bar: it flips Save between active and inactive.
    _titleController.addListener(_onTextChanged);
    _notesController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  bool get _hasChanges {
    final title = _titleController.text.trim();
    return (title.isNotEmpty && title != widget.meal.title) ||
        _notesController.text.trim() != (widget.meal.notes ?? '') ||
        _plannedFor != widget.meal.plannedFor ||
        _cookingMinutes != widget.meal.cookingMinutes ||
        _tasteRating != widget.meal.tasteRating ||
        _satietyRating != widget.meal.satietyRating;
  }

  void _submit() {
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    Navigator.of(context).pop(MealEditResult(
      title: title.isEmpty ? null : title,
      notes: notes.isEmpty ? null : notes,
      plannedFor: _plannedFor,
      cookingMinutes: _cookingMinutes,
      tasteRating: _tasteRating,
      satietyRating: _satietyRating,
    ));
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: AppCard.squircleBorder(),
        title: const Text('Discard changes?'),
        content: const Text('The edits to this meal will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DangerColor,
              foregroundColor: Colors.white,
              shape: AppCard.squircleBorder(radius: 8),
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<MealEditResult?>(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: 'Edit meal',
          actions: [
            AppTopBarTextAction(
              label: 'Save',
              enabled: _hasChanges,
              onPressed: _submit,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Meal name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes (goes into the LLM export)',
                      hintText: 'e.g., less oil than last time',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            // An eaten meal that was never planned has nothing to say here.
            if (!widget.meal.isEaten() || _plannedFor != null) ...[
              const SizedBox(height: 16),
              _PlannedForCard(
                isEaten: widget.meal.isEaten(),
                plannedFor: _plannedFor,
                onChanged: (day) => setState(() => _plannedFor = day),
              ),
            ],
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Cook time'),
                  const SizedBox(height: 12),
                  CookTimeChips(
                    minutes: _cookingMinutes,
                    onChanged: (value) =>
                        setState(() => _cookingMinutes = value),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('How it went'),
                  const SizedBox(height: 12),
                  RatingDots(
                    label: 'Taste',
                    value: _tasteRating,
                    onChanged: (value) => setState(() => _tasteRating = value),
                  ),
                  RatingDots(
                    label: 'Filling',
                    value: _satietyRating,
                    onChanged: (value) =>
                        setState(() => _satietyRating = value),
                  ),
                  const SizedBox(height: 8),
                  const _SectionHint('Tap a selected value again to clear it.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The day the meal is meant to be eaten. Offered as an editable value only
/// while the meal is uneaten: once it is eaten, the day the meal counts on
/// comes from when it was actually eaten, so chips here would be a control that
/// changes nothing visible. The stored day is kept, not cleared, and shown as a
/// record of what had been planned.
class _PlannedForCard extends StatelessWidget {
  final bool isEaten;
  final DateTime? plannedFor;
  final ValueChanged<DateTime?> onChanged;

  const _PlannedForCard({
    required this.isEaten,
    required this.plannedFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isEaten) {
      return AppCard(
        child: Row(
          children: [
            Icon(
              Icons.event_available,
              size: 16,
              color: AppColors.of(context).textTertiary,
            ),
            const SizedBox(width: 8),
            _SectionHint(
              'Was planned for ${DateFormat('EEE d MMM').format(plannedFor!)}',
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Planned for'),
          const SizedBox(height: 12),
          PlannedDayChips(day: plannedFor, onChanged: onChanged),
          const SizedBox(height: 8),
          const _SectionHint(
            'The day you mean to eat it. Tap the chosen day again to clear it.',
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.of(context).textSecondary,
      ),
    );
  }
}

class _SectionHint extends StatelessWidget {
  final String text;

  const _SectionHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.of(context).textTertiary,
      ),
    );
  }
}
