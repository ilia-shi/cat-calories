import 'package:flutter/material.dart';

const SuccessColor = Color(0xFF00BD2D);
const DangerColor = Color(0xFFE3002F);
const DangerLiteColor = Color(0xFFEE657F);

/// Macro nutrient colors
const MacroProteinColor = Colors.red;
const MacroFatColor = Colors.amber;
const MacroCarbColor = Colors.green;

/// Theme-aware color helpers accessed via `AppColors.of(context)`
class AppColors {
  final bool isDark;

  AppColors._(this.isDark);

  factory AppColors.of(BuildContext context) {
    return AppColors._(Theme.of(context).brightness == Brightness.dark);
  }

  // Text colors
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.white70 : Colors.grey.shade600;
  Color get textTertiary => isDark ? Colors.white54 : Colors.grey.shade500;
  Color get textDisabled => isDark ? Colors.white38 : Colors.grey.shade400;

  // Surface colors for chips, badges, containers
  Color get surfaceSubtle => isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100;
  Color get surfaceMuted => isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50;
  Color get surfaceElevated => isDark ? const Color(0xFF2C2C2C) : Colors.white;

  // Border colors
  Color get border => isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200;
  Color get borderSubtle => isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100;

  // Tinted surface (for colored chip backgrounds)
  Color tintedSurface(Color color, {double alpha = 0.1}) {
    return isDark
        ? color.withValues(alpha: alpha * 0.6)
        : color.withValues(alpha: alpha);
  }

  // Tinted text color (softer in dark mode)
  Color tintedText(Color color) {
    return isDark ? color.withValues(alpha: 0.85) : color;
  }

  // Info container colors (blue info boxes)
  Color get infoSurface => isDark ? Colors.blue.withValues(alpha: 0.12) : Colors.blue.shade50;
  Color get infoText => isDark ? Colors.blue.shade200 : Colors.blue.shade800;
  Color get infoIcon => isDark ? Colors.blue.shade300 : Colors.blue.shade700;

  // Macro chip colors (for day summaries, item macros)
  Color macroCircleBg(Color color, bool hasData) {
    if (!hasData) return isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.15);
    return isDark ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.15);
  }

  Color macroCircleText(Color color, bool hasData) {
    if (!hasData) return isDark ? Colors.grey.shade600 : Colors.grey;
    return isDark ? color.withValues(alpha: 0.9) : color;
  }

  Color macroValueText(bool hasData) {
    if (!hasData) return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    return isDark ? Colors.grey.shade300 : Colors.grey.shade700;
  }
}
