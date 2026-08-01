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

enum ColorLabelPreset {
  red(ColorLabel._('#F44336')),
  purple(ColorLabel._('#9C27B0')),
  blue(ColorLabel._('#2196F3')),
  yellow(ColorLabel._('#FFEB3B')),
  orange(ColorLabel._('#FF9800'));

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
