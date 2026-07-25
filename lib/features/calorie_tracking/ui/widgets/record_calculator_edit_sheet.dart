import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/calculator/calorie_calculator_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:flutter/material.dart';

/// Edits an existing record's numbers — weight, calories and macros — on the
/// keypad, prefilled from the record. Unlike the proportional weight sheet,
/// every value can be changed independently.
///
/// Presentational: it pops itself before handing the result back, so the
/// caller only persists.
class RecordCalculatorEditSheet extends StatelessWidget {
  final CalorieRecord item;
  final void Function(CalorieCalculatorResult result) onSave;

  const RecordCalculatorEditSheet({
    Key? key,
    required this.item,
    required this.onSave,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required CalorieRecord item,
    required void Function(CalorieCalculatorResult result) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => RecordCalculatorEditSheet(
        item: item,
        onSave: (result) {
          Navigator.pop(sheetContext);
          onSave(result);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalorieCalculatorSheet(
      header: _EditHeader(item: item),
      submitLabel: 'Save',
      onSubmit: onSave,
      initialCalories: item.value,
      initialWeightGrams: item.weightGrams,
      initialProteinGrams: item.proteinGrams,
      initialFatGrams: item.fatGrams,
      initialCarbGrams: item.carbGrams,
    );
  }
}

class _EditHeader extends StatelessWidget {
  final CalorieRecord item;

  const _EditHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final subtitle = [
      if (item.weightGrams != null) '${item.weightGrams!.toStringAsFixed(0)}g',
      '${item.value.toStringAsFixed(0)} kcal',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: appColors.tintedSurface(Colors.blue),
              shape: AppCard.squircleBorder(radius: 8),
            ),
            child: const Icon(Icons.edit, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description ?? 'Edit entry',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Currently $subtitle',
                  style: TextStyle(
                    fontSize: 13,
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
