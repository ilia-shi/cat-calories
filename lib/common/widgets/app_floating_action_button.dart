import 'dart:ui' show ImageFilter;

import 'package:cat_calories/common/theme/theme.dart';
import 'package:flutter/material.dart';

/// The app's frosted circular action button: a blurred, semi-transparent FAB
/// so every screen's "add" button reads the same as the home one. Passing a
/// null [onPressed] renders it disabled.
class AppFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Object? heroTag;

  const AppFloatingActionButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = onPressed == null
        ? theme.disabledColor
        : theme.floatingActionButtonTheme.backgroundColor ??
            theme.colorScheme.primary;

    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: CustomTheme.surfaceBlurSigma,
          sigmaY: CustomTheme.surfaceBlurSigma,
        ),
        child: FloatingActionButton(
          onPressed: onPressed,
          tooltip: tooltip,
          heroTag: heroTag,
          backgroundColor:
              baseColor.withValues(alpha: CustomTheme.surfaceOpacity),
          elevation: 0,
          child: child,
        ),
      ),
    );
  }
}
