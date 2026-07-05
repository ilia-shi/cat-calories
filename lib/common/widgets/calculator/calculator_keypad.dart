import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calc_key_button.dart';

/// Internal description of one key in the grid.
class _KeySpec {
  final String label;
  final CalcKeyRole role;
  final int flex;
  const _KeySpec(this.label, this.role, {this.flex = 1});
}

/// Shared numeric keypad used by every in-app calculator. The visual style of
/// each key comes from [CalcKeyButton]; this widget owns only the grid layout
/// and which special keys are present.
///
/// Layout variants:
/// * [showOperators] — adds arithmetic keys (+ - * /) for the expression-based
///   quick-add and product calculators.
/// * [showNextField] — adds a '→' key for moving between fields in the
///   multi-field nutrition calculator.
class CalculatorKeypad extends StatefulWidget {
  /// Emits the pressed key: a digit, '.', 'C' (clear), '⌫' (backspace),
  /// '→' (next field), or an operator ('+', '-', '*', '/'). The submit key is
  /// reported through [onSubmit] instead.
  final void Function(String key) onKey;

  final VoidCallback onSubmit;

  /// Whether the submit key is enabled (and shown in [submitAccent]).
  final bool canSubmit;

  /// Label of the submit key, e.g. 'OK' or 'Save'.
  final String submitLabel;

  /// Accent colour of the submit key when [canSubmit].
  final Color submitAccent;

  final bool showOperators;
  final bool showNextField;

  const CalculatorKeypad({
    Key? key,
    required this.onKey,
    required this.onSubmit,
    required this.canSubmit,
    this.submitLabel = 'OK',
    this.submitAccent = Colors.green,
    this.showOperators = false,
    this.showNextField = false,
  }) : super(key: key);

  @override
  State<CalculatorKeypad> createState() => _CalculatorKeypadState();
}

class _CalculatorKeypadState extends State<CalculatorKeypad> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'CalculatorKeypad');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  static final Map<LogicalKeyboardKey, String> _digitKeys = {
    LogicalKeyboardKey.digit0: '0',
    LogicalKeyboardKey.digit1: '1',
    LogicalKeyboardKey.digit2: '2',
    LogicalKeyboardKey.digit3: '3',
    LogicalKeyboardKey.digit4: '4',
    LogicalKeyboardKey.digit5: '5',
    LogicalKeyboardKey.digit6: '6',
    LogicalKeyboardKey.digit7: '7',
    LogicalKeyboardKey.digit8: '8',
    LogicalKeyboardKey.digit9: '9',
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.numpad9: '9',
  };

  static final Map<LogicalKeyboardKey, String> _operatorKeys = {
    LogicalKeyboardKey.add: '+',
    LogicalKeyboardKey.numpadAdd: '+',
    LogicalKeyboardKey.minus: '-',
    LogicalKeyboardKey.numpadSubtract: '-',
    LogicalKeyboardKey.asterisk: '*',
    LogicalKeyboardKey.numpadMultiply: '*',
    LogicalKeyboardKey.slash: '/',
    LogicalKeyboardKey.numpadDivide: '/',
  };

  /// Maps physical/hardware key presses onto the same [CalculatorKeypad.onKey]
  /// / [CalculatorKeypad.onSubmit] callbacks used by the on-screen buttons, so
  /// a Bluetooth/USB keyboard (Android) or desktop keyboard works identically
  /// to tapping.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    final digit = _digitKeys[key];
    if (digit != null) {
      widget.onKey(digit);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal) {
      widget.onKey('.');
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.backspace) {
      widget.onKey('⌫');
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      widget.onSubmit();
      return KeyEventResult.handled;
    }

    if (widget.showOperators) {
      final operator = _operatorKeys[key];
      if (operator != null) {
        widget.onKey(operator);
        return KeyEventResult.handled;
      }
    }

    if (widget.showNextField && key == LogicalKeyboardKey.tab) {
      widget.onKey('→');
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  List<List<_KeySpec>> _layout() {
    if (widget.showOperators) {
      return [
        const [
          _KeySpec('C', CalcKeyRole.clear),
          _KeySpec('⌫', CalcKeyRole.backspace),
          _KeySpec('/', CalcKeyRole.operator),
          _KeySpec('*', CalcKeyRole.operator),
        ],
        const [
          _KeySpec('7', CalcKeyRole.digit),
          _KeySpec('8', CalcKeyRole.digit),
          _KeySpec('9', CalcKeyRole.digit),
          _KeySpec('-', CalcKeyRole.operator),
        ],
        const [
          _KeySpec('4', CalcKeyRole.digit),
          _KeySpec('5', CalcKeyRole.digit),
          _KeySpec('6', CalcKeyRole.digit),
          _KeySpec('+', CalcKeyRole.operator),
        ],
        const [
          _KeySpec('1', CalcKeyRole.digit),
          _KeySpec('2', CalcKeyRole.digit),
          _KeySpec('3', CalcKeyRole.digit),
          _KeySpec('.', CalcKeyRole.digit),
        ],
        [
          const _KeySpec('0', CalcKeyRole.digit, flex: 2),
          _KeySpec(widget.submitLabel, CalcKeyRole.submit, flex: 2),
        ],
      ];
    }

    // Plain digit entry. The right-hand column carries the editing keys; the
    // multi-field variant promotes '→' there and pushes '.' to the last row.
    final List<_KeySpec> rightColumn = widget.showNextField
        ? const [
            _KeySpec('→', CalcKeyRole.next),
            _KeySpec('⌫', CalcKeyRole.backspace),
            _KeySpec('C', CalcKeyRole.clear),
          ]
        : const [
            _KeySpec('⌫', CalcKeyRole.backspace),
            _KeySpec('C', CalcKeyRole.clear),
            _KeySpec('.', CalcKeyRole.digit),
          ];

    final List<_KeySpec> lastRow = widget.showNextField
        ? [
            const _KeySpec('.', CalcKeyRole.digit),
            const _KeySpec('0', CalcKeyRole.digit),
            _KeySpec(widget.submitLabel, CalcKeyRole.submit, flex: 2),
          ]
        : [
            const _KeySpec('0', CalcKeyRole.digit, flex: 2),
            _KeySpec(widget.submitLabel, CalcKeyRole.submit, flex: 2),
          ];

    return [
      [
        const _KeySpec('1', CalcKeyRole.digit),
        const _KeySpec('2', CalcKeyRole.digit),
        const _KeySpec('3', CalcKeyRole.digit),
        rightColumn[0],
      ],
      [
        const _KeySpec('4', CalcKeyRole.digit),
        const _KeySpec('5', CalcKeyRole.digit),
        const _KeySpec('6', CalcKeyRole.digit),
        rightColumn[1],
      ],
      [
        const _KeySpec('7', CalcKeyRole.digit),
        const _KeySpec('8', CalcKeyRole.digit),
        const _KeySpec('9', CalcKeyRole.digit),
        rightColumn[2],
      ],
      lastRow,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _layout().map((row) {
            return Row(
              children: row.map((spec) {
                final isSubmit = spec.role == CalcKeyRole.submit;
                return Expanded(
                  flex: spec.flex,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: CalcKeyButton(
                      label: spec.label,
                      role: spec.role,
                      enabled: isSubmit ? widget.canSubmit : true,
                      accent: widget.submitAccent,
                      onTap: isSubmit ? widget.onSubmit : () => widget.onKey(spec.label),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
