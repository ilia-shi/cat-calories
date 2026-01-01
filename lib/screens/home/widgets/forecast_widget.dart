import 'package:flutter/material.dart';

import '../../../tracking/calorie_tracker.dart';

/// Widget displaying budget forecast over the next several hours
class ForecastWidget extends StatelessWidget {
  final List<BudgetForecast> forecast;
  final double targetCalories;
  final DateTime currentTime;

  const ForecastWidget({
    Key? key,
    required this.forecast,
    required this.targetCalories,
    required this.currentTime,
  }) : super(key: key);

  String _formatHoursFromNow(DateTime time) {
    final diff = time.difference(currentTime);
    final hours = diff.inHours;
    if (hours == 0) return 'Now';
    return '+${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                '📈 Budget Forecast',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Next 12 hours',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: forecast.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                final isFirst = index == 0;
                final barHeightPercent = (point.availableBudget / targetCalories).clamp(0.0, 1.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label
                        Text(
                          '${point.availableBudget.round()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isFirst
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Bar
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              height: (barHeightPercent * 70).clamp(8.0, 70.0),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: isFirst
                                      ? [Colors.green.shade400, Colors.green.shade200]
                                      : [Colors.blue.shade400, Colors.blue.shade200],
                                ),
                                boxShadow: isFirst
                                    ? [
                                  BoxShadow(
                                    color: Colors.green.shade200,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Time label
                        Text(
                          _formatHoursFromNow(point.time),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: isFirst
                                ? Colors.green.shade600
                                : Colors.grey.shade500,
                            fontWeight: isFirst
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context, Colors.green.shade400, 'Current'),
              const SizedBox(width: 20),
              _buildLegendItem(context, Colors.blue.shade400, 'Projected'),
            ],
          ),

          const SizedBox(height: 12),

          // Info text
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'As meals age past 24h, budget frees up automatically',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}