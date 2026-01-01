import 'package:flutter/material.dart';
import 'dart:math';
import '../../../tracking/calorie_tracker.dart';

class DensityScaleWidget extends StatelessWidget {
  final List<CalorieEntry> entries;
  final DateTime currentTime;
  final int bucketCount;

  const DensityScaleWidget({
    Key? key,
    required this.entries,
    required this.currentTime,
    this.bucketCount = 24,
  }) : super(key: key);

  List<double> _calculateDensity() {
    final buckets = List<double>.filled(bucketCount, 0);
    final windowStart = currentTime.subtract(const Duration(hours: 24));

    for (final entry in entries) {
      if (entry.createdAt.isAfter(windowStart) &&
          !entry.createdAt.isAfter(currentTime)) {
        final hoursAgo =
            currentTime.difference(entry.createdAt).inMinutes / 60.0;

        // FIXED: Clamp bucket index to valid range (0 to bucketCount-1)
        // This fixes edge case where entries at exactly currentTime would get bucketIndex = bucketCount
        final bucketIndex = ((24 - hoursAgo) / 24 * bucketCount).floor().clamp(0, bucketCount - 1);

        buckets[bucketIndex] += entry.value;
      }
    }

    return buckets;
  }

  Color _getDensityColor(double value, double maxValue, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (maxValue <= 0) {
      return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    }

    final intensity = (value / maxValue).clamp(0.0, 1.0);

    if (intensity == 0) {
      return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    }
    if (intensity < 0.25) {
      return isDark ? Colors.blue.shade700 : Colors.blue.shade200;
    }
    if (intensity < 0.5) {
      return isDark ? Colors.blue.shade500 : Colors.blue.shade400;
    }
    if (intensity < 0.75) {
      return isDark ? Colors.orange.shade600 : Colors.orange.shade400;
    }

    return isDark ? Colors.red.shade600 : Colors.red.shade500;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final densities = _calculateDensity();
    final maxDensity = densities.reduce(max);
    final totalCalories = densities.fold<double>(0, (a, b) => a + b);

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
                '🔥 24h Calorie Density',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.purple.shade900 : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${totalCalories.round()} kcal total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Density heatmap
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Row(
                children: densities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  final color = _getDensityColor(value, maxDensity, context);
                  final isLast = index == densities.length - 1;

                  // Calculate time label for tooltip
                  final hoursAgo = 24 - (index / bucketCount * 24);
                  final timeLabel = hoursAgo <= 1
                      ? 'Last hour'
                      : '${hoursAgo.round()}h ago';

                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        border: isLast
                            ? null
                            : Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Tooltip(
                        message: value > 0
                            ? '$timeLabel: ${value.round()} kcal'
                            : '$timeLabel: No calories',
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '24h ago',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
              Text(
                '12h ago',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
              Text(
                'Now',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}