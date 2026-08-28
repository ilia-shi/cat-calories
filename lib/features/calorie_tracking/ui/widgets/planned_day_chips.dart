import 'package:cat_calories/common/widgets/selectable_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Picks the day a meal is planned for: today, tomorrow, the day after, or any
/// other day from the calendar. Tapping the selected chip clears the day back
/// to null, the same way the cook-time chips and rating dots revoke a value.
///
/// Every day it emits is local midnight, so two days compare equal by `==`.
class PlannedDayChips extends StatelessWidget {
  final DateTime? day;
  final ValueChanged<DateTime?> onChanged;

  const PlannedDayChips({
    super.key,
    required this.day,
    required this.onChanged,
  });

  /// Local midnight [offset] days from today. Built by field rather than
  /// `add(Duration(days:))`, which lands an hour off across a DST change.
  static DateTime dayFromToday(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset);
  }

  Future<void> _pickDay(BuildContext context) async {
    final today = dayFromToday(0);
    final picked = await showDatePicker(
      context: context,
      initialDate: day ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 2),
    );
    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = <DateTime, String>{
      dayFromToday(0): 'Today',
      dayFromToday(1): 'Tomorrow',
      dayFromToday(2): DateFormat('EEE').format(dayFromToday(2)),
    };
    final isOtherDay = day != null && !presets.containsKey(day);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final preset in presets.entries)
          SelectableChip(
            label: preset.value,
            selected: preset.key == day,
            onTap: () => onChanged(preset.key == day ? null : preset.key),
          ),
        if (isOtherDay)
          SelectableChip(
            label: DateFormat('EEE d MMM').format(day!),
            selected: true,
            onTap: () => onChanged(null),
          ),
        SelectableChip(
          label: 'Pick a day',
          icon: Icons.calendar_today_outlined,
          selected: false,
          onTap: () => _pickDay(context),
        ),
      ],
    );
  }
}
