import 'package:flutter/material.dart';
import '../../../tracking/calorie_tracker.dart';

/// Widget showing meal recommendations and timing
class MealRecommendationWidget extends StatelessWidget {
  final MealRecommendation recommendation;
  final DateTime currentTime;

  const MealRecommendationWidget({
    Key? key,
    required this.recommendation,
    required this.currentTime,
  }) : super(key: key);

  _TimingStatus _getTimingStatus() {
    if (recommendation.remaining24h <= 0) {
      return _TimingStatus(
        color: Colors.red.shade600,
        backgroundColor: Colors.red.shade50,
        icon: Icons.hourglass_empty,
        text: 'Budget Used',
        subtitle: 'Wait for calories to expire',
      );
    }

    if (null == recommendation.waitUntil ||
        recommendation.waitUntil!.isBefore(currentTime)) {
      return _TimingStatus(
        color: Colors.green.shade600,
        backgroundColor: Colors.green.shade50,
        icon: Icons.restaurant,
        text: 'Ready to Eat!',
        subtitle: 'You can have a meal now',
      );
    }

    final waitMinutes = recommendation.waitUntil!.difference(currentTime).inMinutes;
    return _TimingStatus(
      color: Colors.orange.shade600,
      backgroundColor: Colors.orange.shade50,
      icon: Icons.schedule,
      text: 'Wait ${_formatDuration(waitMinutes)}',
      subtitle: 'Time until next meal window',
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }

  String _formatLastMeal() {
    if (null == recommendation.hoursSinceLastMeal) {
      return 'No recent meals';
    }

    final hours = recommendation.hoursSinceLastMeal!;
    if (hours < 1) {
      return '${(hours * 60).round()} minutes ago';
    } else if (hours < 24) {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      if (m == 0) {
        return '${h}h ago';
      }
      return '${h}h ${m}m ago';
    }

    return 'Over 24h ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _getTimingStatus();

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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: status.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: status.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status.icon,
                    size: 28,
                    color: status.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: status.color,
                        ),
                      ),
                      Text(
                        status.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: status.color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Portion recommendation
          if (recommendation.recommendedMax > 0) ...[
            Text(
              'Recommended Portion',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildPortionScale(context),
            const SizedBox(height: 16),
          ],

          // Info section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.reasoning,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade800,
                        ),
                      ),
                      if (recommendation.lastMealTime != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Last meal: ${_formatLastMeal()}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortionScale(BuildContext context) {
    final theme = Theme.of(context);
    final minKcal = recommendation.recommendedMin.round();
    final maxKcal = recommendation.recommendedMax.round();
    final idealKcal = ((minKcal + maxKcal) / 2).round();

    return Column(
      children: [
        // Scale markers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildScaleMarker(context, '$minKcal', 'Min', Colors.grey.shade600),
            _buildScaleMarker(context, '$idealKcal', 'Ideal', Colors.green.shade600),
            _buildScaleMarker(context, '$maxKcal', 'Max', Colors.grey.shade600),
          ],
        ),
        const SizedBox(height: 8),
        // Gradient bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.orange.shade300,
                Colors.green.shade400,
                Colors.orange.shade300,
                Colors.grey.shade300,
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Too small',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
            Text(
              'Perfect',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.green.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Too large',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScaleMarker(BuildContext context, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade500,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingStatus {
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final String text;
  final String subtitle;

  const _TimingStatus({
    required this.color,
    required this.backgroundColor,
    required this.icon,
    required this.text,
    required this.subtitle,
  });
}