import 'package:flutter/material.dart';
import 'package:cat_calories/common/theme/colors.dart';

final class AppCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? shadowColor;
  final bool emphasized;
  final VoidCallback? onTap;

  const AppCard({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.gradient,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = defaultBorderRadius,
    this.shadowColor,
    this.emphasized = false,
    this.onTap,
  }) : super(key: key);

  static const double defaultBorderRadius = 16;
  static const double _squircleScale = 1.5;

  static ContinuousRectangleBorder squircleBorder({
    double radius = defaultBorderRadius,
    bool top = true,
    bool bottom = true,
    BorderSide side = BorderSide.none,
    squircleScale = _squircleScale
  }) {
    final r = Radius.circular(radius * squircleScale);

    return ContinuousRectangleBorder(
      side: side,
      borderRadius: BorderRadius.vertical(
        top: top ? r : Radius.zero,
        bottom: bottom ? r : Radius.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final shape = squircleBorder(radius: borderRadius);

    Widget content = Padding(padding: padding, child: child);
    content = Material(
      type: MaterialType.transparency,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(onTap: onTap, customBorder: shape, child: content)
          : content,
    );

    return Container(
      margin: margin,
      decoration: ShapeDecoration(
        color: gradient == null
            ? (backgroundColor ?? appColors.surfaceElevated)
            : null,
        gradient: gradient,
        shape: shape,
        shadows: _buildShadow(appColors),
      ),
      child: content,
    );
  }

  List<BoxShadow> _buildShadow(AppColors appColors) {
    final hasTint = shadowColor != null;
    final color = shadowColor ?? Colors.black;
    final alpha = hasTint ? 0.30 : (appColors.isDark ? 0.40 : 0.08);
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: emphasized ? 16 : 10,
        offset: Offset(0, emphasized ? 6 : 4),
      ),
    ];
  }
}
