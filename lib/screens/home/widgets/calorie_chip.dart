import 'package:flutter/material.dart';
import '../../../ui/colors.dart';

final class CalorieChip extends StatelessWidget {
  final String label;
  final int value;
  final int goal;
  final bool isOver;
  final String tooltip;

  const CalorieChip({
    required this.label,
    required this.value,
    required this.goal,
    required this.isOver,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOver ? DangerColor : SuccessColor;
    final percentage = goal > 0 ? (value / goal * 100).clamp(0, 100) : 0.0;

    return Tooltip(
      message: '$tooltip: $value / $goal kcal',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text(
            //   label,
            //   style: TextStyle(
            //     fontSize: 9,
            //     fontWeight: FontWeight.w600,
            //     color: color,
            //   ),
            // ),
            Text(
              '$label $value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            // Mini progress bar
            Container(
              width: 32,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}