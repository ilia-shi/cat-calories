import 'package:flutter/material.dart';

import '../../../tracking/calorie_tracker.dart';

/// Widget displaying recent calorie entries within the 24h window
class RecentEntriesWidget extends StatelessWidget {
  final List<CalorieEntry> entries;
  final DateTime currentTime;
  final Function(CalorieEntry)? onRemove;
  final int maxEntries;

  const RecentEntriesWidget({
    Key? key,
    required this.entries,
    required this.currentTime,
    this.onRemove,
    this.maxEntries = 5,
  }) : super(key: key);

  Color _getMealAgeColor(double hoursAgo) {
    if (hoursAgo < 4) return Colors.blue.shade500;
    if (hoursAgo < 12) return Colors.orange.shade500;
    return Colors.green.shade500;
  }

  String _formatTimeAgo(DateTime entryTime) {
    final diff = currentTime.difference(entryTime);
    final minutes = diff.inMinutes;
    final hours = diff.inHours;

    if (minutes < 60) {
      return '${minutes}m ago';
    } else if (hours < 24) {
      final m = minutes % 60;
      if (m == 0) {
        return '${hours}h ago';
      }
      return '${hours}h ${m}m ago';
    }

    return 'Over 24h ago';
  }

  String _formatExpiresIn(DateTime entryTime) {
    final expiresAt = entryTime.add(const Duration(hours: 24));
    final diff = expiresAt.difference(currentTime);
    final minutes = diff.inMinutes;
    final hours = diff.inHours;

    if (diff.isNegative) {
      return 'Expired';
    }

    if (minutes < 60) {
      return 'Expires in ${minutes}m';
    } else if (hours < 24) {
      final m = minutes % 60;
      if (m == 0) {
        return 'Expires in ${hours}h';
      }
      return 'Expires in ${hours}h ${m}m';
    }
    return 'Expires in 24h+';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayEntries = entries.take(maxEntries).toList();
    final hasMore = entries.length > maxEntries;

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
                '📋 Recent Meals (24h)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entries.length} entries',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Entries list
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No meals logged in the last 24 hours',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ...displayEntries.map((entry) => _buildEntryRow(context, entry)),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+ ${entries.length - maxEntries} more entries',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEntryRow(BuildContext context, CalorieEntry entry) {
    final theme = Theme.of(context);
    final hoursAgo = currentTime.difference(entry.createdAt).inMinutes / 60.0;
    final dotColor = _getMealAgeColor(hoursAgo);
    final expiresText = _formatExpiresIn(entry.createdAt);
    final isExpiringSoon = expiresText.contains('m') && !expiresText.contains('h');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isExpiringSoon
            ? Colors.green.shade50
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpiringSoon
              ? Colors.green.shade200
              : theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Dot indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Value
          Text(
            '${entry.value.toStringAsFixed(entry.value.truncateToDouble() == entry.value ? 0 : 1)} kcal',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          // Description if present
          if (entry.description != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),

          // Time info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimeAgo(entry.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                expiresText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isExpiringSoon
                      ? Colors.green.shade600
                      : Colors.grey.shade500,
                  fontWeight: isExpiringSoon
                      ? FontWeight.w600
                      : FontWeight.normal,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}