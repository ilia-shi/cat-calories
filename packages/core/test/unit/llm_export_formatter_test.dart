import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/llm_export_formatter.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:test/test.dart';

void main() {
  const formatter = LlmExportFormatter();

  final profile = Profile(
    id: 'p1',
    name: 'Ilya',
    wakingTimeSeconds: 57600,
    caloriesLimitGoal: 1800,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  CalorieRecord record({
    String? id,
    double value = 100,
    String? description,
    DateTime? eatenAt,
    DateTime? createdAt,
    double? weightGrams,
    double? proteinGrams,
    double? fatGrams,
    double? carbGrams,
    String? productId,
  }) =>
      CalorieRecord(
        id: id ?? 'r-${description ?? value}',
        value: value,
        description: description,
        sortOrder: 0,
        eatenAt: eatenAt,
        createdAt: createdAt ?? DateTime(2026, 6, 29, 10),
        profileId: 'p1',
        wakingPeriodId: null,
        weightGrams: weightGrams,
        proteinGrams: proteinGrams,
        fatGrams: fatGrams,
        carbGrams: carbGrams,
        productId: productId,
      );

  Product product({
    String id = 'prod-1',
    String title = 'Chicken thigh',
    double? caloriesPer100g,
    double? proteinsPer100g,
    double? fatsPer100g,
    double? carbsPer100g,
    double? packageWeightGrams,
    int usesCount = 0,
  }) =>
      Product(
        id: id,
        title: title,
        description: null,
        usesCount: usesCount,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        profileId: 'p1',
        barcode: null,
        sortOrder: 0,
        caloriesPer100g: caloriesPer100g,
        proteinsPer100g: proteinsPer100g,
        fatsPer100g: fatsPer100g,
        carbsPer100g: carbsPer100g,
        packageWeightGrams: packageWeightGrams,
      );

  test('header contains profile name, goal and period', () {
    final output = formatter.format(profile: profile, records: [
      record(description: 'apple', eatenAt: DateTime(2026, 6, 28, 9)),
      record(description: 'banana', eatenAt: DateTime(2026, 6, 30, 9)),
    ]);

    expect(output, contains('# Cat Calories — nutrition log'));
    expect(output, contains('Profile: Ilya · Daily goal: 1800 kcal'));
    expect(output, contains('Period: 2026-06-28 .. 2026-06-30'));
    expect(output, contains(LlmExportFormatter.defaultPreamble));
  });

  test('groups eaten records by day in ascending order with totals', () {
    final output = formatter.format(profile: profile, records: [
      record(value: 300, description: 'late', eatenAt: DateTime(2026, 6, 30, 20)),
      record(value: 200, description: 'lunch', eatenAt: DateTime(2026, 6, 29, 13)),
      record(value: 100, description: 'breakfast', eatenAt: DateTime(2026, 6, 29, 8)),
    ]);

    final day29 = output.indexOf('## 2026-06-29 — total 300 kcal');
    final day30 = output.indexOf('## 2026-06-30 — total 300 kcal');
    expect(day29, greaterThanOrEqualTo(0));
    expect(day30, greaterThan(day29));
    expect(output.indexOf('breakfast'), lessThan(output.indexOf('lunch')));
  });

  test('day heading sums macros only when some record has them', () {
    final withMacros = formatter.format(profile: profile, records: [
      record(
        description: 'chicken',
        eatenAt: DateTime(2026, 6, 29, 13),
        proteinGrams: 42,
        fatGrams: 25.5,
        carbGrams: 0,
      ),
    ]);
    expect(withMacros, contains('(P 42g / F 25.5g / C 0g)'));

    final withoutMacros = formatter.format(profile: profile, records: [
      record(description: 'mystery', eatenAt: DateTime(2026, 6, 29, 13)),
    ]);
    expect(withoutMacros, contains('## 2026-06-29 — total 100 kcal\n'));
    expect(withoutMacros, isNot(contains('(P ')));
  });

  test('record line includes weight and partial macros with ? placeholders',
      () {
    final output = formatter.format(profile: profile, records: [
      record(
        value: 395,
        description: 'chicken thigh',
        eatenAt: DateTime(2026, 6, 29, 13),
        weightGrams: 250,
        proteinGrams: 42,
      ),
    ]);

    expect(output,
        contains('- chicken thigh 250g — 395 kcal (P 42 / F ? / C ?)'));
  });

  test('falls back to product title, then placeholder, for missing description',
      () {
    final output = formatter.format(
      profile: profile,
      records: [
        record(eatenAt: DateTime(2026, 6, 29, 9), productId: 'prod-1'),
        record(id: 'r-x', value: 55, eatenAt: DateTime(2026, 6, 29, 10)),
      ],
      products: [product(id: 'prod-1', title: 'Chicken thigh')],
    );

    expect(output, contains('- Chicken thigh — 100 kcal'));
    expect(output, contains('- (no description) — 55 kcal'));
  });

  test('planned records go to their own section with added date', () {
    final output = formatter.format(profile: profile, records: [
      record(
        description: 'overnight oats',
        createdAt: DateTime(2026, 7, 1, 21),
        value: 410,
      ),
    ]);

    expect(output, contains('## Planned (not eaten yet)'));
    expect(output,
        contains('- overnight oats — 410 kcal (added 2026-07-01)'));
  });

  test('products appendix sorts by usesCount and shows per-100g data', () {
    final output = formatter.format(
      profile: profile,
      records: [],
      products: [
        product(id: 'a', title: 'Rice', caloriesPer100g: 360, usesCount: 2),
        product(
          id: 'b',
          title: 'Chicken thigh',
          caloriesPer100g: 158,
          proteinsPer100g: 17,
          fatsPer100g: 10,
          carbsPer100g: 0,
          packageWeightGrams: 500,
          usesCount: 42,
        ),
      ],
    );

    expect(output, contains('## Products'));
    expect(
        output,
        contains(
            '- Chicken thigh — 158 kcal · (P 17 / F 10 / C 0) · pack 500g · used 42×'));
    expect(output.indexOf('Chicken thigh —'), lessThan(output.indexOf('- Rice')));
  });

  test('empty input still produces a valid header-only document', () {
    final output = formatter.format(profile: profile, records: []);

    expect(output, contains('# Cat Calories — nutrition log'));
    expect(output, isNot(contains('Period:')));
    expect(output, isNot(contains('## Planned')));
    expect(output, isNot(contains('## Products')));
  });

  test('custom preamble replaces the default', () {
    final output = formatter.format(
      profile: profile,
      records: [],
      preamble: 'My custom goals.',
    );

    expect(output, contains('My custom goals.'));
    expect(output, isNot(contains('opportunistically')));
  });
}
