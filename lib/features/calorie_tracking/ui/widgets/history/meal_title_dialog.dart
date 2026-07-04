import 'package:flutter/material.dart';

/// Prompts for a meal name. Resolves to the entered text, or null if cancelled.
Future<String?> promptMealTitle(
  BuildContext context, {
  String dialogTitle = 'Group as meal',
  String confirmLabel = 'Group',
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Meal name',
          hintText: 'e.g., Breakfast',
        ),
        onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
