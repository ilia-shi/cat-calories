import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Creates a gap, or edits [gap] when one is given.
class TrackingGapSheet extends StatefulWidget {
  final TrackingGap? gap;
  final String profileId;
  final DateTime initialStart;
  final DateTime initialEnd;
  final ValueChanged<TrackingGap> onSave;

  const TrackingGapSheet({
    super.key,
    this.gap,
    required this.profileId,
    required this.initialStart,
    required this.initialEnd,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    TrackingGap? gap,
    required String profileId,
    required DateTime start,
    required DateTime end,
  }) {
    final bloc = context.read<HomeBloc>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => TrackingGapSheet(
        gap: gap,
        profileId: profileId,
        initialStart: start,
        initialEnd: end,
        onSave: (saved) => bloc.add(TrackingGapSavingEvent(saved)),
      ),
    );
  }

  @override
  State<TrackingGapSheet> createState() => _TrackingGapSheetState();
}

class _TrackingGapSheetState extends State<TrackingGapSheet> {
  late DateTime _start = widget.initialStart;
  late DateTime _end = widget.initialEnd;
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.gap?.description ?? '');
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) {
      return null;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStart() async {
    final picked = await _pick(_start);
    if (picked != null) {
      setState(() => _start = picked);
    }
  }

  Future<void> _pickEnd() async {
    final picked = await _pick(_end);
    if (picked != null) {
      setState(() => _end = picked);
    }
  }

  void _save() {
    final now = DateTime.now();
    final error = trackingGapError(_start, _end, now);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final description = _descriptionController.text.trim();
    widget.onSave(TrackingGap(
      id: widget.gap?.id,
      profileId: widget.profileId,
      startedAt: _start,
      endedAt: _end,
      description: description.isEmpty ? null : description,
      createdAt: widget.gap?.createdAt ?? now,
      updatedAt: now,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Not tracked',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _BoundRow(label: 'From', value: _start, onTap: _pickStart),
            const SizedBox(height: 8),
            _BoundRow(label: 'To', value: _end, onTap: _pickEnd),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Roughly what did you eat? How hungry were you?',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: AppCard.squircleBorder(radius: 12),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoundRow extends StatelessWidget {
  static final _format = DateFormat('MMM d, y · HH:mm');
  static final _shape = AppCard.squircleBorder(radius: 10);

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _BoundRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return Material(
      color: appColors.surfaceMuted,
      shape: _shape,
      child: InkWell(
        customBorder: _shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: appColors.textSecondary),
                ),
              ),
              Text(
                _format.format(value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
