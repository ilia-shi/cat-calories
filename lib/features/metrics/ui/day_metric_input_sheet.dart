import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_field_display.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_keypad.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_sheet.dart';
import 'package:cat_calories/features/metrics/ui/day_metric_look.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayMetricInputSheet extends StatefulWidget {
  final DayMetric metric;
  final DateTime day;
  final DayMetricEntry? entry;

  /// Receives the value to store, already normalized, and the trimmed note.
  final void Function(double value, String? note) onSave;
  final VoidCallback onClear;

  const DayMetricInputSheet({
    super.key,
    required this.metric,
    required this.day,
    required this.entry,
    required this.onSave,
    required this.onClear,
  });

  @override
  State<DayMetricInputSheet> createState() => _DayMetricInputSheetState();
}

class _DayMetricInputSheetState extends State<DayMetricInputSheet> {
  late String _text;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _text = entry == null ? '' : widget.metric.toInput(entry.value);
    _note = TextEditingController(text: entry?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  double? get _stored {
    final typed = double.tryParse(_text);

    return typed == null ? null : widget.metric.fromInput(typed);
  }

  String? get _error {
    final stored = _stored;
    if (stored == null) {
      return null;
    }

    return dayMetricError(widget.metric, stored, widget.day, DateTime.now());
  }

  void _onKey(String key) {
    setState(() {
      if (key == 'C') {
        _text = '';
      } else if (key == '⌫') {
        if (_text.isNotEmpty) {
          _text = _text.substring(0, _text.length - 1);
        }
      } else if (key == '.') {
        if (!_text.contains('.')) {
          _text = _text.isEmpty ? '0.' : '$_text.';
        }
      } else {
        _text += key;
      }
    });
  }

  bool get _canSubmit => _stored != null && _error == null;

  void _submit() {
    // CalculatorKeypad fires onSubmit even when canSubmit is false.
    if (!_canSubmit) {
      return;
    }

    final note = _note.text.trim();
    widget.onSave(_stored!, note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;
    final colors = AppColors.of(context);
    final error = _error;

    return CalculatorSheet(
      header: _SheetHeader(
        metric: metric,
        day: widget.day,
        onClear: widget.entry == null ? null : widget.onClear,
      ),
      children: [
        CalculatorFieldDisplay(
          icon: metric.icon,
          label: metric.title,
          color: metric.color,
          value: _text.isEmpty ? '0' : _text,
          unit: metric.inputUnit,
          isPlaceholder: _text.isEmpty,
        ),
        if (error != null)
          _SheetLine(text: error, color: Theme.of(context).colorScheme.error)
        else if (metric.hint != null)
          _SheetLine(text: metric.hint!, color: colors.textSecondary),
        const SizedBox(height: 8),
        _NoteField(controller: _note),
        const SizedBox(height: 16),
        CalculatorKeypad(
          canSubmit: _canSubmit,
          onKey: _onKey,
          onSubmit: _submit,
          submitLabel: 'Save',
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final DayMetric metric;
  final DateTime day;
  final VoidCallback? onClear;

  const _SheetHeader({
    required this.metric,
    required this.day,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${metric.title}, ${DateFormat('d MMM yyyy').format(day)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          if (onClear != null)
            TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

class _SheetLine extends StatelessWidget {
  final String text;
  final Color color;

  const _SheetLine({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  final TextEditingController controller;

  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        color: AppColors.of(context).surfaceSubtle,
        shape: AppCard.squircleBorder(radius: 12),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Note',
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
