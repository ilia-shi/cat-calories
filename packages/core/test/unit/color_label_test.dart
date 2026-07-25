import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:test/test.dart';

void main() {
  group('ColorLabel parsing', () {
    test('normalizes case and an omitted leading hash', () {
      expect(ColorLabel.tryParse('#f44336')!.hex, '#F44336');
      expect(ColorLabel.tryParse('f44336')!.hex, '#F44336');
      expect(ColorLabel.tryParse('  #F44336  ')!.hex, '#F44336');
    });

    test('rejects anything that is not a 6-digit hex color', () {
      expect(ColorLabel.tryParse(null), isNull);
      expect(ColorLabel.tryParse(''), isNull);
      expect(ColorLabel.tryParse('#FFF'), isNull);
      expect(ColorLabel.tryParse('#GGGGGG'), isNull);
      expect(ColorLabel.tryParse('#FF44336'), isNull);
      expect(ColorLabel.tryParse('red'), isNull);
      expect(ColorLabel.tryParse(0xF44336), isNull);
    });

    test('fromRgb masks alpha bits away', () {
      expect(ColorLabel.fromRgb(0xF44336).hex, '#F44336');
      expect(ColorLabel.fromRgb(0xFFF44336).hex, '#F44336');
      expect(ColorLabel.fromRgb(0x0000FF).hex, '#0000FF');
    });

    test('exposes opaque argb for Flutter Color', () {
      expect(ColorLabel.tryParse('#F44336')!.argb, 0xFFF44336);
      expect(ColorLabel.tryParse('#000000')!.argb, 0xFF000000);
    });

    test('equality is by value', () {
      expect(ColorLabel.tryParse('#f44336'), ColorLabel.fromRgb(0xF44336));
      expect(ColorLabel.tryParse('#f44336'), isNot(ColorLabelPreset.blue.color));
    });

    test('forColor maps a stored color back to its preset', () {
      expect(ColorLabelPreset.forColor(ColorLabel.tryParse('#009688')),
          ColorLabelPreset.teal);
      expect(ColorLabelPreset.forColor(ColorLabel.tryParse('#123456')), isNull);
      expect(ColorLabelPreset.forColor(null), isNull);
    });

    test('every preset is a valid normalized color', () {
      for (final preset in ColorLabelPreset.values) {
        expect(ColorLabel.tryParse(preset.color.hex), preset.color,
            reason: preset.name);
      }
      expect(ColorLabelPreset.values.map((p) => p.color.hex).toSet(),
          hasLength(ColorLabelPreset.values.length));
    });
  });

  group('CalorieRecord color label', () {
    CalorieRecord record({ColorLabel? colorLabel}) => CalorieRecord(
          id: 'r1',
          value: 100,
          description: 'x',
          sortOrder: 0,
          eatenAt: DateTime(2026, 7, 25),
          createdAt: DateTime(2026, 7, 25),
          profileId: 'prof-1',
          wakingPeriodId: null,
          colorLabel: colorLabel,
        );

    test('survives a JSON round-trip as a hex string', () {
      final json = record(colorLabel: ColorLabelPreset.teal.color).toJson();
      expect(json['color_label'], '#009688');

      expect(CalorieRecord.fromJson(json).colorLabel,
          ColorLabelPreset.teal.color);
    });

    test('unlabelled by default', () {
      final json = record().toJson();
      expect(json['color_label'], isNull);
      expect(CalorieRecord.fromJson(json).colorLabel, isNull);
    });

    test('a stored garbage value degrades to unlabelled', () {
      final json = record().toJson()..['color_label'] = 'not-a-color';
      expect(CalorieRecord.fromJson(json).colorLabel, isNull);
    });

    test('copyForPlanning carries the label', () {
      final copy = record(colorLabel: ColorLabelPreset.amber.color)
          .copyForPlanning(DateTime(2026, 7, 26));
      expect(copy.colorLabel, ColorLabelPreset.amber.color);
    });
  });
}
