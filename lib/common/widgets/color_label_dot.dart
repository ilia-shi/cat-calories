import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:flutter/material.dart';

/// A [ColorLabel] rendered as a dot next to an entry.
class ColorLabelDot extends StatelessWidget {
  final ColorLabel color;
  final double size;

  const ColorLabelDot({
    Key? key,
    required this.color,
    this.size = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final fill = Color(color.argb);
    final name = ColorLabelPreset.forColor(color)?.name ?? color.hex;

    return Semantics(
      label: 'Color label: $name',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          // Pale labels (yellow, lime) vanish on a light card without an
          // outline; darker ones look cleaner with none.
          border: fill.computeLuminance() > 0.6
              ? Border.all(color: appColors.border)
              : null,
        ),
      ),
    );
  }
}
