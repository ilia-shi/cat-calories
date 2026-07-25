/// A color tag the user can attach to an entity, stored on the wire and in
/// sqlite as an opaque `#RRGGBB` string. Hex was picked over a packed ARGB int
/// because the same value has to survive sqlite TEXT, JSON, CSS in the web
/// client and Flutter's `Color` — and stays readable when inspecting rows by
/// hand. Alpha is deliberately not part of it: a label is drawn as a solid
/// swatch, and transparency would make labels indistinguishable over different
/// backgrounds.
final class ColorLabel {
  static final RegExp _hexPattern = RegExp(r'^#?([0-9a-fA-F]{6})$');

  /// Normalized `#RRGGBB`, uppercase.
  final String hex;

  const ColorLabel._(this.hex);

  factory ColorLabel.fromRgb(int rgb) => ColorLabel._(
      '#${(rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}');

  /// Returns null for anything that isn't a 6-digit hex color, so a value from
  /// an older client or a peer replica degrades to "no label" instead of
  /// throwing in the middle of a sync batch.
  static ColorLabel? tryParse(Object? value) {
    if (value is ColorLabel) {
      return value;
    }
    if (value is! String) {
      return null;
    }

    final match = _hexPattern.firstMatch(value.trim());

    if (match == null) {
      return null;
    }

    return ColorLabel._('#${match.group(1)!.toUpperCase()}');
  }

  int get rgb => int.parse(hex.substring(1), radix: 16);

  /// Opaque ARGB for Flutter's `Color`, which this package cannot import.
  int get argb => 0xFF000000 | rgb;

  @override
  bool operator ==(Object other) => other is ColorLabel && other.hex == hex;

  @override
  int get hashCode => hex.hashCode;

  @override
  String toString() => hex;
}

/// The swatches offered in a picker. Same Material-500 hues as the product
/// category palette in `categories_screen.dart`, so a category color and a
/// record label read as one visual system — keep the two lists in step.
/// [ColorLabel] itself accepts any color, so this set can grow, or give way to
/// a free-form picker, without a migration.
enum ColorLabelPreset {
  red(ColorLabel._('#F44336')),
  pink(ColorLabel._('#E91E63')),
  purple(ColorLabel._('#9C27B0')),
  deepPurple(ColorLabel._('#673AB7')),
  indigo(ColorLabel._('#3F51B5')),
  blue(ColorLabel._('#2196F3')),
  lightBlue(ColorLabel._('#03A9F4')),
  cyan(ColorLabel._('#00BCD4')),
  teal(ColorLabel._('#009688')),
  green(ColorLabel._('#4CAF50')),
  lightGreen(ColorLabel._('#8BC34A')),
  lime(ColorLabel._('#CDDC39')),
  yellow(ColorLabel._('#FFEB3B')),
  amber(ColorLabel._('#FFC107')),
  orange(ColorLabel._('#FF9800')),
  deepOrange(ColorLabel._('#FF5722')),
  brown(ColorLabel._('#795548')),
  grey(ColorLabel._('#9E9E9E')),
  blueGrey(ColorLabel._('#607D8B'));

  final ColorLabel color;

  const ColorLabelPreset(this.color);

  /// The preset a stored color came from, or null if it is a custom color —
  /// callers use the [name] to describe the swatch (tooltips, screen readers).
  static ColorLabelPreset? forColor(ColorLabel? color) {
    for (final preset in values) {
      if (preset.color == color) {
        return preset;
      }
    }

    return null;
  }
}
