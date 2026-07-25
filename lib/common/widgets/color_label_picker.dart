import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/horizontal_drag_scroll_area.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:flutter/material.dart';

/// Swatch picker for an optional [ColorLabel]: a "no color" option first, then
/// the presets. Circles, not squircles — a label is drawn as a dot wherever it
/// is shown, and round swatches read as a palette instead of as buttons.
class ColorLabelPicker extends StatelessWidget {
  static const double swatchSize = 34;
  static const double _gap = 12;

  final ColorLabel? value;
  final ValueChanged<ColorLabel?> onChanged;
  final List<ColorLabelPreset> presets;

  /// One horizontally scrolling row instead of a wrapping grid — for places
  /// with height to spare but not three rows of it, like a bottom sheet.
  final bool singleLine;

  /// Inset around the swatches. On a [singleLine] picker this is the scroll
  /// view's content padding, so swatches scroll all the way to the edge
  /// instead of being clipped inside a narrower viewport.
  final EdgeInsetsGeometry padding;

  const ColorLabelPicker({
    Key? key,
    required this.value,
    required this.onChanged,
    this.presets = ColorLabelPreset.values,
    this.singleLine = false,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final swatches = _buildSwatches();

    if (singleLine) {
      return HorizontalDragScrollArea(
        padding: padding,
        child: Row(spacing: _gap, children: swatches),
      );
    }

    return Padding(
      padding: padding,
      child: Wrap(spacing: _gap, runSpacing: _gap, children: swatches),
    );
  }

  List<Widget> _buildSwatches() {
    final selected = value;
    final isPreset = presets.any((preset) => preset.color == selected);

    return [
      _Swatch(
        color: null,
        isSelected: selected == null,
        semanticLabel: 'No color',
        onTap: () => onChanged(null),
      ),
      for (final preset in presets)
        _Swatch(
          color: preset.color,
          isSelected: preset.color == selected,
          semanticLabel: preset.name,
          onTap: () => onChanged(preset.color),
        ),

      // A color set on another device (or by a later custom picker) is not in
      // the preset list; show it so the user sees their label instead of an
      // apparently empty selection.
      if (selected != null && !isPreset)
        _Swatch(
          color: selected,
          isSelected: true,
          semanticLabel: 'Custom ${selected.hex}',
          onTap: () => onChanged(selected),
        ),
    ];
  }
}

class _Swatch extends StatelessWidget {
  final ColorLabel? color;
  final bool isSelected;
  final String semanticLabel;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.isSelected,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final fill = color == null ? null : Color(color!.argb);

    return Semantics(
      label: semanticLabel,
      selected: isSelected,
      button: true,
      child: Tooltip(
        message: semanticLabel,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: ColorLabelPicker.swatchSize,
            height: ColorLabelPicker.swatchSize,
            decoration: BoxDecoration(
              color: fill ?? appColors.surfaceSubtle,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? appColors.textPrimary : appColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: _SwatchMark(fill: fill, isSelected: isSelected),
          ),
        ),
      ),
    );
  }
}

class _SwatchMark extends StatelessWidget {
  final Color? fill;
  final bool isSelected;

  const _SwatchMark({required this.fill, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    if (fill == null) {
      return Icon(
        Icons.format_color_reset,
        size: 18,
        color: isSelected ? appColors.textPrimary : appColors.textTertiary,
      );
    }

    if (!isSelected) {
      return const SizedBox.shrink();
    }

    // Pale swatches (yellow, lime) need a dark check or it disappears.
    return Icon(
      Icons.check,
      size: 20,
      color: fill!.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
    );
  }
}
