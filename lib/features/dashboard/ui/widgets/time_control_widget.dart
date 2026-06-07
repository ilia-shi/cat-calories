import 'dart:async';
import 'package:flutter/material.dart';

class TimeControlWidget extends StatefulWidget {
  final DateTime baseTime;
  final double hoursOffset;
  final ValueChanged<double> onOffsetChanged;
  final double minOffset;
  final double maxOffset;

  const TimeControlWidget({
    Key? key,
    required this.baseTime,
    required this.hoursOffset,
    required this.onOffsetChanged,
    this.minOffset = -96,
    this.maxOffset = 96,
  }) : super(key: key);

  @override
  State<TimeControlWidget> createState() => _TimeControlWidgetState();
}

class _TimeControlWidgetState extends State<TimeControlWidget> {
  Timer? _liveTimeTimer;
  late DateTime _displayTime;

  @override
  void initState() {
    super.initState();
    _updateDisplayTime();
    _startLiveTimeUpdates();
  }

  @override
  void didUpdateWidget(TimeControlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update display time when widget parameters change
    _updateDisplayTime();

    // Restart or stop timer based on offset
    if (widget.hoursOffset == 0 && oldWidget.hoursOffset != 0) {
      _startLiveTimeUpdates();
    } else if (widget.hoursOffset != 0 && _liveTimeTimer != null) {
      _liveTimeTimer?.cancel();
      _liveTimeTimer = null;
    }
  }

  void _updateDisplayTime() {
    if (widget.hoursOffset == 0) {
      _displayTime = DateTime.now();
    } else {
      _displayTime = widget.baseTime.add(Duration(
        minutes: (widget.hoursOffset * 60).round(),
      ));
    }
  }

  void _startLiveTimeUpdates() {
    _liveTimeTimer?.cancel();

    // Only run live updates when showing current time (offset == 0)
    if (widget.hoursOffset == 0) {
      _liveTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && widget.hoursOffset == 0) {
          setState(() {
            _displayTime = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _liveTimeTimer?.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');

    // FIXED: Show seconds when displaying live time (offset == 0)
    if (widget.hoursOffset == 0) {
      return '$weekday, $month ${dt.day}, ${dt.year} at $hour:$minute:$second';
    }
    return '$weekday, $month ${dt.day}, ${dt.year} at $hour:$minute';
  }

  String _formatOffset(double offset) {
    final sign = offset >= 0 ? '+' : '';
    final absOffset = offset.abs();

    if (absOffset < 1) {
      return '${sign}${(offset * 60).round()}m';
    } else if (absOffset == absOffset.floor()) {
      return '$sign${offset.toInt()}h';
    } else {
      final hours = offset.floor();
      final minutes = ((offset - hours) * 60).abs().round();
      return '$sign${hours}h ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOffset = widget.hoursOffset != 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOffset
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOffset
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: isOffset ? 2 : 1,
        ),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOffset
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOffset ? Icons.history : Icons.access_time,
                  size: 20,
                  color: isOffset
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isOffset ? 'Time Simulation' : 'Current Time',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isOffset
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        // FIXED: Show live indicator when showing actual time
                        if (!isOffset) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(_displayTime),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOffset)
                TextButton.icon(
                  onPressed: () => widget.onOffsetChanged(0),
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Time slider
          Column(
            children: [
              // Tick marks
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTickMark('-96h', isStart: true),
                    _buildTickMark('-48h'),
                    _buildTickMark('Now', isCenter: true),
                    _buildTickMark('+48h'),
                    _buildTickMark('+96h', isEnd: true),
                  ],
                ),
              ),

              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                    elevation: 4,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                  thumbColor: theme.colorScheme.primary,
                  overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: widget.hoursOffset,
                  min: widget.minOffset,
                  max: widget.maxOffset,
                  divisions: ((widget.maxOffset - widget.minOffset) * 2).toInt(), // 30-min steps
                  onChanged: widget.onOffsetChanged,
                ),
              ),
            ],
          ),

          // Offset indicator
          if (isOffset)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.hoursOffset > 0 ? Icons.fast_forward : Icons.fast_rewind,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Offset: ${_formatOffset(widget.hoursOffset)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTickMark(String label, {bool isCenter = false, bool isStart = false, bool isEnd = false}) {
    return Column(
      children: [
        Container(
          width: isCenter ? 3 : 1,
          height: isCenter ? 12 : 8,
          decoration: BoxDecoration(
            color: isCenter ? Colors.grey.shade600 : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCenter ? FontWeight.w600 : FontWeight.normal,
            color: isCenter ? Colors.grey.shade700 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}