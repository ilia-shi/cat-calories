import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Corner radius shared by the back button, icon actions and text actions, so
/// every pill on the bar reads as the same shape.
const double _pillRadius = 12;

/// The single app bar for every screen: a flat transparent bar with a squircle
/// back button on the left, a centred title, and squircle pill actions on the
/// right.
///
/// The back button appears automatically whenever the route can be popped; pass
/// [showBack] to force it on or off.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool centerTitle;
  final bool? showBack;
  final VoidCallback? onBack;

  const AppTopBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.centerTitle = true,
    this.showBack,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final withBack = showBack ?? Navigator.of(context).canPop();

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: withBack
          ? AppTopBarAction(
              icon: Icons.arrow_back_ios_new_rounded,
              iconSize: 18,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions.isEmpty
          ? null
          : [...actions, const SizedBox(width: 4)],
    );
  }
}

/// A squircle pill icon button for [AppTopBar.actions] — the same shape as the
/// bar's back button.
///
/// Pass either [icon] or, when the glyph needs decorating (a rotation, a badge),
/// a [child]; the child inherits the action's icon size and colour.
class AppTopBarAction extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double iconSize;

  const AppTopBarAction({
    super.key,
    this.icon,
    this.child,
    this.onPressed,
    this.tooltip,
    this.color,
    this.iconSize = 20,
  }) : assert(icon != null || child != null, 'Pass either icon or child');

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: DecoratedBox(
        decoration: ShapeDecoration(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          shape: AppCard.squircleBorder(radius: _pillRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: IconTheme.merge(
            data: IconThemeData(
              size: iconSize,
              color: onPressed == null
                  ? colors.textDisabled
                  : (color ?? colors.textPrimary),
            ),
            child: child ?? Icon(icon),
          ),
        ),
      ),
    );
  }
}

/// A labelled action for [AppTopBar.actions] — the "Save" button and friends.
///
/// Dims to half opacity and stops responding while [enabled] is false or [busy]
/// is true, so a form with nothing to save reads as inactive without the button
/// jumping in and out of the bar.
class AppTopBarTextAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool busy;
  final String? busyLabel;
  final Color? color;

  const AppTopBarTextAction({
    super.key,
    required this.label,
    this.icon = Icons.check_rounded,
    this.onPressed,
    this.enabled = true,
    this.busy = false,
    this.busyLabel,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy && onPressed != null;

    return AnimatedOpacity(
      opacity: active ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextButton.icon(
          onPressed: active ? onPressed : null,
          icon: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (icon == null ? null : Icon(icon, size: 20)),
          label: Text(
            busy ? (busyLabel ?? label) : label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            foregroundColor: color ?? Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: AppCard.squircleBorder(radius: _pillRadius),
          ),
        ),
      ),
    );
  }
}
