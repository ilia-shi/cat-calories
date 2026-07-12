import 'dart:ui' show ImageFilter;

import 'package:cat_calories/common/theme/theme.dart';
import 'package:flutter/material.dart';

/// Frosted-glass surface: blurs whatever is painted behind it and paints a
/// translucent [tint] on top. Used by the app bar, bottom nav and floating
/// toolbars.
///
/// Centralises the app's blur so its cost lives in one place: [BackdropFilter]
/// forces a `saveLayer` + framebuffer read-back every frame the content behind
/// it moves, and the home screen stacks several of these at once — the biggest
/// scroll/animation jank source on weak GPUs. Gating it here (via
/// [CustomTheme.surfaceBlurEnabled]) or lowering [CustomTheme.surfaceBlurSigma]
/// tunes every frosted surface at once. The [RepaintBoundary] keeps the bar's
/// own repaints from leaking into (or being dirtied by) its neighbours.
class FrostedSurface extends StatelessWidget {
  final Widget child;

  /// Translucent colour painted over the blurred backdrop.
  final Color tint;

  /// Clips the blur (and content) to this shape. Null = a plain rectangle.
  final ShapeBorder? clipShape;

  /// Shape of the tint layer — may carry a border the [clipShape] omits so the
  /// stroke sits inside the clip. Null = a plain rectangle fill.
  final ShapeBorder? tintShape;

  const FrostedSurface({
    Key? key,
    required this.child,
    required this.tint,
    this.clipShape,
    this.tintShape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = DecoratedBox(
      decoration: tintShape == null
          ? BoxDecoration(color: tint)
          : ShapeDecoration(color: tint, shape: tintShape!),
      child: child,
    );

    if (CustomTheme.surfaceBlurEnabled) {
      content = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: CustomTheme.surfaceBlurSigma,
          sigmaY: CustomTheme.surfaceBlurSigma,
        ),
        child: content,
      );
    }

    final clipped = clipShape == null
        ? ClipRect(child: content)
        : ClipPath(
            clipper: ShapeBorderClipper(shape: clipShape!),
            child: content,
          );

    return RepaintBoundary(child: clipped);
  }
}
