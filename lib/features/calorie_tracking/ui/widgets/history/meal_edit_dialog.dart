import 'package:cat_calories/features/calorie_tracking/ui/widgets/meal_signal_inputs.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';

/// The edited fields collected by [MealEditDialog]. [title] is null when the
/// field was left blank (keep the existing title); [notes] is null when empty.
class MealEditResult {
  final String? title;
  final String? notes;
  final int? cookingMinutes;
  final int? tasteRating;
  final int? satietyRating;

  const MealEditResult({
    required this.title,
    required this.notes,
    required this.cookingMinutes,
    required this.tasteRating,
    required this.satietyRating,
  });
}

/// Dialog to rename a meal and edit its notes and cooking signals. Gathers the
/// values and hands them back via [onSave]; persistence is the caller's job.
class MealEditDialog extends StatefulWidget {
  final Meal meal;
  final ValueChanged<MealEditResult> onSave;

  const MealEditDialog({
    Key? key,
    required this.meal,
    required this.onSave,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required Meal meal,
    required ValueChanged<MealEditResult> onSave,
  }) {
    showDialog(
      context: context,
      builder: (_) => MealEditDialog(meal: meal, onSave: onSave),
    );
  }

  @override
  State<MealEditDialog> createState() => _MealEditDialogState();
}

class _MealEditDialogState extends State<MealEditDialog> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.meal.title);
  late final TextEditingController _notesController =
      TextEditingController(text: widget.meal.notes ?? '');
  late int? _cookingMinutes = widget.meal.cookingMinutes;
  late int? _tasteRating = widget.meal.tasteRating;
  late int? _satietyRating = widget.meal.satietyRating;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop();
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    widget.onSave(MealEditResult(
      title: title.isEmpty ? null : title,
      notes: notes.isEmpty ? null : notes,
      cookingMinutes: _cookingMinutes,
      tasteRating: _tasteRating,
      satietyRating: _satietyRating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Meal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Meal name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (goes into the LLM export)',
                hintText: 'e.g., less oil than last time',
              ),
            ),
            const SizedBox(height: 16),
            CookTimeChips(
              minutes: _cookingMinutes,
              onChanged: (value) => setState(() => _cookingMinutes = value),
            ),
            const SizedBox(height: 16),
            RatingDots(
              label: 'Taste',
              value: _tasteRating,
              onChanged: (value) => setState(() => _tasteRating = value),
            ),
            RatingDots(
              label: 'Filling',
              value: _satietyRating,
              onChanged: (value) => setState(() => _satietyRating = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
