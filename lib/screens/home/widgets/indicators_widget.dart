import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final class IndicatorData {
  final double averageLast7Days;
  final double caloriesLast24Hours;
  final double caloriesToday;
  final double caloriesYesterday;
  final double caloriesCurrentPeriod;
  final double dailyGoal;
  final double? periodGoal;
  final bool hasPeriod;
  final List<CalorieItemModel> todayCalorieItems;

  const IndicatorData({
    required this.averageLast7Days,
    required this.caloriesLast24Hours,
    required this.caloriesToday,
    required this.caloriesYesterday,
    required this.caloriesCurrentPeriod,
    required this.dailyGoal,
    required this.todayCalorieItems,
    this.periodGoal,
    this.hasPeriod = false,
  });
}

final class IndicatorsWidget extends StatelessWidget {
  final IndicatorData data;

  const IndicatorsWidget({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final firstItem = _firstTodayCalorieItem();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Expanded(
                child: _buildIndicatorCard(
                  context: context,
                  title: '24h Rolling',
                  value: data.caloriesLast24Hours,
                  goal: data.dailyGoal,
                  icon: Icons.update,
                  color: _get24hColor(context),
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndicatorCard(
                  context: context,
                  title: _getTodayTitle(),
                  value: data.caloriesToday,
                  goal: data.dailyGoal,
                  icon: Icons.today,
                  color: _getTodayColor(context),
                  isPrimary: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildCompactIndicator(
                  context: context,
                  title: 'Yesterday',
                  value: data.caloriesYesterday,
                  goal: data.dailyGoal,
                  icon: Icons.history,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactIndicator(
                  context: context,
                  title: '7-Day Avg',
                  value: data.averageLast7Days,
                  goal: data.dailyGoal,
                  icon: Icons.show_chart,
                ),
              ),
              if (data.hasPeriod) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactIndicator(
                    context: context,
                    title: 'Period',
                    value: data.caloriesCurrentPeriod,
                    goal: data.periodGoal ?? data.dailyGoal,
                    icon: Icons.bedtime_outlined,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Progress summary
          _buildProgressSummary(context),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard({
    required BuildContext context,
    required String title,
    required double value,
    required double goal,
    required IconData icon,
    required Color color,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = goal > 0 ? (value / goal).clamp(0.0, 1.5) : 0.0;
    final isOver = value > goal;
    final remaining = goal - value;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark
                        ? color.withValues(alpha: 0.9)
                        : color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${value.round()}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            'kcal',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? _getOverColor(context) : color,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isOver
                ? '+${(-remaining).round()} over'
                : '${remaining.round()} left',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isOver
                  ? _getOverColor(context)
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactIndicator({
    required BuildContext context,
    required String title,
    required double value,
    required double goal,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = goal > 0 ? (value / goal * 100).round() : 0;
    final isOver = value > goal;

    Color indicatorColor;
    if (isOver) {
      indicatorColor = _getOverColor(context);
    } else if (percentage >= 80) {
      indicatorColor = Colors.orange.shade600;
    } else {
      indicatorColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${value.round()}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: indicatorColor.withValues(alpha: isDark ? 0.25 : 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: indicatorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate overall status
    final rolling24hPercent = data.dailyGoal > 0
        ? (data.caloriesLast24Hours / data.dailyGoal * 100).round()
        : 0;

    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (rolling24hPercent < 70) {
      statusText =
          'Under target - ${100 - rolling24hPercent}% budget remaining';
      statusIcon = Icons.trending_down;
      statusColor = Colors.blue.shade600;
    } else if (rolling24hPercent <= 100) {
      statusText = 'On track - ${100 - rolling24hPercent}% budget remaining';
      statusIcon = Icons.check_circle_outline;
      statusColor = Colors.green.shade600;
    } else if (rolling24hPercent <= 115) {
      statusText = 'Slightly over target (+${rolling24hPercent - 100}%)';
      statusIcon = Icons.warning_amber_outlined;
      statusColor = Colors.orange.shade600;
    } else {
      statusText = 'Over target (+${rolling24hPercent - 100}%)';
      statusIcon = Icons.error_outline;
      statusColor = Colors.red.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            size: 18,
            color: statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    isDark ? statusColor.withValues(alpha: 0.9) : statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'Goal: ${data.dailyGoal.round()}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _get24hColor(BuildContext context) {
    final percentage =
        data.dailyGoal > 0 ? data.caloriesLast24Hours / data.dailyGoal : 0.0;

    if (percentage > 1.0) return Colors.red.shade600;
    if (percentage > 0.9) return Colors.orange.shade600;
    return Colors.blue.shade600;
  }

  Color _getTodayColor(BuildContext context) {
    final percentage =
        data.dailyGoal > 0 ? data.caloriesToday / data.dailyGoal : 0.0;

    if (percentage > 1.0) {
      return Colors.red.shade600;
    }

    if (percentage > 0.9) {
      return Colors.orange.shade600;
    }

    return Colors.green.shade600;
  }

  Color _getOverColor(BuildContext context) {
    return Colors.red.shade600;
  }

  CalorieItemModel? _firstTodayCalorieItem() {
    if (data.todayCalorieItems.isEmpty) {
      return null;
    }

    final eatenItems =
        data.todayCalorieItems.where((item) => null != item.eatenAt).toList();

    if (eatenItems.isEmpty) {
      return null;
    }

    return eatenItems.reduce((earliest, current) =>
        earliest.eatenAt!.isBefore(current.eatenAt!) ? earliest : current);
  }
  
  String _getTodayTitle() {
    final firstItem = _firstTodayCalorieItem();
    if (null == firstItem) {
      return 'Today';
    }

    final dateTime = firstItem.eatenAt;
    if (null == dateTime) {
      return 'Today';
    }

    final dateString = DateFormat('MMM dd HH:mm').format(dateTime);

    return '${dateString}';
  }
}
