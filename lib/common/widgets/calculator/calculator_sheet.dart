import 'dart:ui' show ImageFilter;

import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/theme/theme.dart';
import 'package:flutter/material.dart';

/// Frosted-glass bottom-sheet chrome shared by every calculator sheet: a
/// rounded, blurred, semi-transparent surface with a drag handle, an optional
/// [header], and a scrollable column of [children]. The keyboard inset and
/// safe area are handled internally, so callers only supply content.
class CalculatorSheet extends StatelessWidget {
  /// Content shown below the handle (and below [header] when present).
  final List<Widget> children;

  /// Optional header row (e.g. icon + title + subtitle) shown above [children].
  final Widget? header;

  const CalculatorSheet({
    Key? key,
    required this.children,
    this.header,
  }) : super(key: key);

  static const BorderRadius _radius =
      BorderRadius.vertical(top: Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: _radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: CustomTheme.surfaceBlurSigma,
          sigmaY: CustomTheme.surfaceBlurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: appColors.surfaceElevated
                .withValues(alpha: CustomTheme.surfaceOpacity),
            borderRadius: _radius,
          ),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHandle(color: appColors.textDisabled),
                  if (header != null) header!,
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The small rounded drag handle at the top of a [CalculatorSheet].
class _SheetHandle extends StatelessWidget {
  final Color color;

  const _SheetHandle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
