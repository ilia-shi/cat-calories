import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Semantic role of a calculator key, used to pick its colours so every
/// keypad in the app shares one visual language.
enum CalcKeyRole { digit, clear, backspace, next, operator, submit }

/// A single styled calculator key. Shared across all calculator keypads so
/// they look identical regardless of the host bottom sheet.
class CalcKeyButton extends StatelessWidget {
  final String label;
  final CalcKeyRole role;
  final VoidCallback onTap;

  /// Only meaningful for [CalcKeyRole.submit]: greys the button out when false.
  final bool enabled;

  /// Accent colour for the submit key when [enabled] (e.g. green, teal).
  final Color accent;

  final double height;

  const CalcKeyButton({
    Key? key,
    required this.label,
    required this.role,
    required this.onTap,
    this.enabled = true,
    this.accent = Colors.green,
    this.height = 52,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor;
    final Color foregroundColor;

    switch (role) {
      case CalcKeyRole.submit:
        backgroundColor = enabled ? accent : Colors.grey;
        foregroundColor = Colors.white;
        break;
      case CalcKeyRole.clear:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        foregroundColor = Colors.red;
        break;
      case CalcKeyRole.backspace:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        foregroundColor = Colors.orange;
        break;
      case CalcKeyRole.next:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        foregroundColor = Colors.blue;
        break;
      case CalcKeyRole.operator:
        backgroundColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
        foregroundColor = isDark ? Colors.white : Colors.black87;
        break;
      case CalcKeyRole.digit:
        backgroundColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
        foregroundColor = isDark ? Colors.white : Colors.black87;
        break;
    }

    final shape = AppCard.squircleBorder(radius: 10, squircleScale: 2);

    return Material(
      color: backgroundColor,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Container(
          height: height,
          alignment: Alignment.center,
          child: _buildChild(foregroundColor),
        ),
      ),
    );
  }

  Widget _buildChild(Color color) {
    switch (role) {
      case CalcKeyRole.backspace:
        return Icon(Icons.backspace_outlined, color: color, size: 22);
      case CalcKeyRole.next:
        return Icon(Icons.arrow_forward, color: color, size: 22);
      default:
        return Text(
          label,
          style: TextStyle(
            fontSize: role == CalcKeyRole.submit ? 16 : 20,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        );
    }
  }
}
