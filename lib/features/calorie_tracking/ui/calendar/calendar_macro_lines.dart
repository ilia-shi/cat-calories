import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:flutter/material.dart';

class CalendarMacroLines extends StatelessWidget {
  final CalendarCell cell;
  final bool showLetters;
  final double fontSize;

  const CalendarMacroLines({
    super.key,
    required this.cell,
    this.showLetters = true,
    this.fontSize = 10,
  });

  Widget _line(BuildContext context, String letter, double grams, Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        '${showLetters ? '$letter ' : ''}${cell.macroLabel(grams)}',
        maxLines: 1,
        style: TextStyle(
          fontSize: fontSize,
          color: AppColors.of(context).tintedText(color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _line(context, 'P', cell.protein, MacroProteinColor),
        _line(context, 'F', cell.fat, MacroFatColor),
        _line(context, 'C', cell.carbs, MacroCarbColor),
      ],
    );
  }
}
