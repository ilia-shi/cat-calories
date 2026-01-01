import 'package:flutter/material.dart';

import '../../../tracking/calorie_tracker.dart';

class BudgetDisplayWidget extends StatelessWidget {
  final MealRecommendation recommendation;
  final VoidCallback? onTap;

  const BudgetDisplayWidget({
    Key? key,
    required this.recommendation,
    this.onTap,
  }) : super(key: key);

  Color _getBudgetColor(double percentUsed) {
    if (percentUsed >= 100) return Colors.red.shade600;
    if (percentUsed >= 85) return Colors.orange.shade600;
    if (percentUsed >= 70) return Colors.amber.shade600;
    return Colors.green.shade600;
  }

  Color _getBudgetBackgroundColor(double percentUsed) {
    if (percentUsed >= 100) return Colors.red.shade50;
    if (percentUsed >= 85) return Colors.orange.shade50;
    if (percentUsed >= 70) return Colors.amber.shade50;
    return Colors.green.shade50;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgetColor = _getBudgetColor(recommendation.percentUsed);
    final backgroundColor = _getBudgetBackgroundColor(recommendation.percentUsed);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: budgetColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: budgetColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '24h Budget',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: budgetColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${recommendation.remaining24h.round()}',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: budgetColor,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            'kcal left',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: budgetColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildCircularProgress(context, budgetColor),
              ],
            ),

            const SizedBox(height: 20),

            // Progress bar
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (recommendation.percentUsed / 100).clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.6),
                    valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${recommendation.consumed24h.round()} kcal consumed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'of ${recommendation.target24h.round()} kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Compensation info
            if (recommendation.compensation.isActive) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: recommendation.compensation.amount < 0
                      ? Colors.orange.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      recommendation.compensation.amount < 0
                          ? Icons.trending_down
                          : Icons.trending_up,
                      size: 16,
                      color: recommendation.compensation.amount < 0
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation.compensation.reason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: recommendation.compensation.amount < 0
                              ? Colors.orange.shade800
                              : Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress(BuildContext context, Color color) {
    final percentage = recommendation.percentUsed.clamp(0, 100);

    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'used',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}