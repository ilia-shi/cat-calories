import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/macro_chips.dart';
import 'package:flutter/material.dart';

/// Gradient hero card at the top of the calorie history: all-time totals,
/// per-day average and aggregate macros.
class HistorySummaryCard extends StatelessWidget {
  final int totalDays;
  final int totalItems;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;

  const HistorySummaryCard({
    Key? key,
    required this.totalDays,
    required this.totalItems,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final avgPerDay = totalDays > 0 ? totalCalories / totalDays : 0.0;
    final hasMacroData = totalProtein > 0 || totalFat > 0 || totalCarbs > 0;

    return AppCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        colors: [
          Theme.of(context).primaryColor.withValues(alpha: 0.8),
          Theme.of(context).primaryColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: Theme.of(context).primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(
                icon: Icons.calendar_month,
                value: totalDays.toString(),
                label: 'Days Tracked',
              ),
              _divider(),
              _SummaryItem(
                icon: Icons.local_fire_department,
                value: totalCalories.toStringAsFixed(0),
                label: 'Total kcal',
              ),
              _divider(),
              _SummaryItem(
                icon: Icons.analytics_outlined,
                value: avgPerDay.toStringAsFixed(0),
                label: 'Avg/Day',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasMacroData) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: AppCard.squircleBorder(radius: 12),
              ),
              child: Center(
                child: MacroBadgesRow(
                  protein: totalProtein,
                  fat: totalFat,
                  carbs: totalCarbs,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: AppCard.squircleBorder(radius: 20),
            ),
            child: Text(
              '$totalItems entries total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
