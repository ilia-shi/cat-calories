import 'dart:ui' show lerpDouble;

import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/theme/theme.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FloatingToolbar extends StatelessWidget {
  final List<Widget> children;

  final double collapseProgress;

  final EdgeInsetsGeometry? padding;

  const FloatingToolbar({
    Key? key,
    required this.children,
    this.collapseProgress = 0,
    this.padding,
  }) : super(key: key);

  static const double horizontalMargin = 8;
  static const double topMargin = 8;
  static const double bottomGap = 8;
  static const double expandedHeight = 48;
  static const double collapsedHeight = 40;
  static const double _radius = 18;

  /// Inset a host must reserve above scrolling content so it clears one bar.
  static const double reservedHeight = topMargin + expandedHeight + bottomGap;

  static double insetForBars(int count) =>
      count * (topMargin + expandedHeight) + bottomGap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;

    final t = collapseProgress.clamp(0.0, 1.0);

    final clipShape = AppCard.squircleBorder(radius: _radius);
    final barShape = AppCard.squircleBorder(
      radius: _radius,
      side: BorderSide(
        color: (isDark ? Colors.white : Colors.black)
            .withValues(alpha: isDark ? 0.12 : 0.08),
        width: 1,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          horizontalMargin, topMargin, horizontalMargin, 0),
      child: DecoratedBox(
        // Soft shadow lives outside the clip so the bar appears to float.
        decoration: ShapeDecoration(
          shape: clipShape,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FrostedSurface(
          clipShape: clipShape,
          tintShape: barShape,
          tint: background.withValues(alpha: CustomTheme.surfaceOpacity),
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              height: lerpDouble(expandedHeight, collapsedHeight, t),
              child: Padding(
                padding: padding ??
                    EdgeInsets.symmetric(horizontal: lerpDouble(12, 8, t)!),
                child: Row(children: children),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pins [toolbars] (which receive a live collapse value driven by the scroll
/// direction) over a scrolling [builder] child. [topInset] must match the
/// pinned bars' height, or content hides behind them instead of scrolling under.
class FloatingToolbarHost extends StatefulWidget {
  final Widget Function(BuildContext context, double collapseProgress) toolbars;
  final double topInset;
  final Widget Function(BuildContext context, double topInset) builder;

  const FloatingToolbarHost({
    Key? key,
    required this.toolbars,
    required this.builder,
    this.topInset = FloatingToolbar.reservedHeight,
  }) : super(key: key);

  @override
  State<FloatingToolbarHost> createState() => _FloatingToolbarHostState();
}

class _FloatingToolbarHostState extends State<FloatingToolbarHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _collapse;

  @override
  void initState() {
    super.initState();
    _collapse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _collapse.dispose();
    super.dispose();
  }

  bool _onScroll(UserScrollNotification notification) {
    // Ignore horizontal scrollables (e.g. a category chip row) — only the
    // vertical content scroll should collapse the bar.
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    switch (notification.direction) {
      case ScrollDirection.reverse:
        _collapse.forward();
        break;
      case ScrollDirection.forward:
        _collapse.reverse();
        break;
      case ScrollDirection.idle:
        break;
    }
    // Keep bubbling so outer listeners (e.g. the bottom nav) collapse in sync.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.builder(context, widget.topInset),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _collapse,
              builder: (context, _) =>
                  widget.toolbars(context, _collapse.value),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact [IconButton] that won't overflow a [FloatingToolbar]'s collapsed height.
class ToolbarActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const ToolbarActionButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
      color: AppColors.of(context).textPrimary,
    );
  }
}
