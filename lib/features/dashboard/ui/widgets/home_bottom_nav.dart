import 'dart:ui' show lerpDouble;

import 'package:cat_calories/common/theme/theme.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';

/// A single destination shown in [HomeBottomNav].
class HomeBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const HomeBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Frosted-glass squircle bottom navigation bar.
///
/// A squircle pill slides between items, driven by [position] — the live tab
/// position — so it tracks both taps and swipes. [collapse] (0 = expanded,
/// 1 = collapsed) fades the labels and shrinks the icons as the user scrolls.
class HomeBottomNav extends StatelessWidget {
  /// Rebuild trigger for the dynamic parts (pill position, icon sizes, bar
  /// height). Only the subtree under the inner [AnimatedBuilder] rebuilds when
  /// this ticks — the frosted shell (blur, clip, shadow) is built once.
  final Listenable animation;

  /// Live, continuous tab position (e.g. 0.0 .. items.length - 1). A getter,
  /// not a value, so it is sampled per frame inside the animation builder.
  final ValueGetter<double> position;
  final ValueChanged<int> onTap;

  /// 0 = labels fully visible, 1 = labels hidden and icons shrunk. Sampled per
  /// frame, like [position].
  final ValueGetter<double> collapse;
  final List<HomeBottomNavItem> items;

  const HomeBottomNav({
    Key? key,
    required this.animation,
    required this.position,
    required this.onTap,
    required this.collapse,
    required this.items,
  }) : super(key: key);

  static const double _barRadius = 22;
  static const double _pillInset = 7;
  static const double _pillRadius = _barRadius - _pillInset; // 15

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = theme.bottomNavigationBarTheme.backgroundColor ??
        theme.colorScheme.surface;
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = isDark ? Colors.white60 : Colors.black54;

    final clipShape = AppCard.squircleBorder(radius: _barRadius);
    final barShape = AppCard.squircleBorder(
      radius: _barRadius,
      side: BorderSide(
        color: (isDark ? Colors.white : Colors.black)
            .withValues(alpha: isDark ? 0.12 : 0.08),
        width: 1,
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
              // Only this subtree rebuilds per animation frame; the frosted
              // shell above it is built once.
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final t = collapse().clamp(0.0, 1.0);
                  final pos = position();
                  return SizedBox(
                    height: lerpDouble(62, 50, t),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final slotWidth = constraints.maxWidth / items.length;
                        // Fixed inset (not a fraction of the slot) so the
                        // horizontal gap equals the vertical inset below.
                        final pillWidth = slotWidth - _pillInset * 2;
                        final clampedPos =
                            pos.clamp(0.0, (items.length - 1).toDouble());

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Squircle pill that glides between items.
                            Positioned(
                              top: _pillInset,
                              bottom: _pillInset,
                              left: slotWidth * clampedPos +
                                  (slotWidth - pillWidth) / 2,
                              width: pillWidth,
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                  color: selectedColor.withValues(alpha: 0.16),
                                  shape: AppCard.squircleBorder(
                                      radius: _pillRadius),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (int i = 0; i < items.length; i++)
                                  Expanded(
                                    child: _HomeBottomNavTile(
                                      item: items[i],
                                      // 1 when fully on this item, 0 when a full
                                      // step away — lerps as the pill slides.
                                      selection:
                                          (1 - (pos - i).abs()).clamp(0.0, 1.0),
                                      collapse: t,
                                      selectedColor: selectedColor,
                                      unselectedColor: unselectedColor,
                                      onTap: () => onTap(i),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBottomNavTile extends StatelessWidget {
  final HomeBottomNavItem item;

  /// 0 = unselected, 1 = selected (continuous; tracks the page transition).
  final double selection;
  final double collapse;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _HomeBottomNavTile({
    required this.item,
    required this.selection,
    required this.collapse,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = lerpDouble(26, 22, collapse)!;
    final color = Color.lerp(unselectedColor, selectedColor, selection)!;

    // GestureDetector (not InkWell) so the sliding pill is the only indicator —
    // no competing ripple/highlight at the tapped slot.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selection >= 0.5 ? item.activeIcon : item.icon,
              size: iconSize,
              color: color,
            ),
            // Collapses (and fades) the label as the user scrolls.
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 1 - collapse,
                child: Opacity(
                  opacity: 1 - collapse,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: selection >= 0.5
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
