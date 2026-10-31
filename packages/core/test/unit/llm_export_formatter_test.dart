import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/llm_export_formatter.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
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

  group('costs', () {
    test('record line and day sum include snapshotted cost', () {
      final output = formatter.format(profile: profile, records: [
        record(
          value: 395,
          description: 'chicken',
          eatenAt: DateTime(2026, 6, 29, 13),
        )
          ..costValue = 1.2
          ..costCurrency = 'EUR',
        record(
          value: 288,
          description: 'rice',
          eatenAt: DateTime(2026, 6, 29, 13),
        )
          ..costValue = 0.25
          ..costCurrency = 'EUR',
      ]);

      expect(output, contains('- chicken — 395 kcal · 1.20 EUR'));
      expect(output, contains('· cost 1.45 EUR'));
      expect(output, contains('Costs are snapshotted at eating time'));
    });

    test('partial day sum is marked with ≥; currencies not mixed', () {
      final output = formatter.format(profile: profile, records: [
        record(description: 'priced', eatenAt: DateTime(2026, 6, 29, 9))
          ..costValue = 2
          ..costCurrency = 'EUR',
        record(description: 'travel', eatenAt: DateTime(2026, 6, 29, 12))
          ..costValue = 9
          ..costCurrency = 'GEL',
        record(description: 'unpriced', eatenAt: DateTime(2026, 6, 29, 19)),
      ]);

      expect(output, contains('· cost ≥ 2 EUR + 9 GEL'));
    });

    test('no cost data → no cost fragments anywhere', () {
      final output = formatter.format(profile: profile, records: [
        record(description: 'apple', eatenAt: DateTime(2026, 6, 29, 9)),
      ]);

      expect(output, isNot(contains('cost')));
      expect(output, isNot(contains('EUR')));
    });

    test('product appendix shows package price', () {
      final output = formatter.format(
        profile: profile,
        records: [],
        products: [
          product(id: 'a', title: 'Chicken', caloriesPer100g: 158)
            ..packageWeightGrams = 500
            ..pricePerPackage = 3.5
            ..priceCurrency = 'EUR',
        ],
      );

      expect(output,
          contains('pack 500g · pack price 3.50 EUR'));
    });
  });

  group('meals', () {
    Meal curry({int? taste, int? cook}) => Meal(
          id: 'meal-1',
          profileId: 'p1',
          title: 'Chicken curry',
          notes: 'less oil, still good',
          createdAt: DateTime(2026, 6, 29, 12),
          eatenAt: DateTime(2026, 6, 29, 13),
          tasteRating: taste,
          cookingMinutes: cook,
        );

    test('day partitions into meal section and Ungrouped', () {
      final output = formatter.format(
        profile: profile,
        records: [
          record(
            value: 395,
            description: 'chicken thigh',
            eatenAt: DateTime(2026, 6, 29, 13),
          )..mealId = 'meal-1',
          record(
            value: 288,
            description: 'rice',
            eatenAt: DateTime(2026, 6, 29, 13),
          )..mealId = 'meal-1',
          record(
            value: 107,
            description: 'banana',
            eatenAt: DateTime(2026, 6, 29, 16),
          ),
        ],
        meals: [curry(taste: 4, cook: 30)],
      );

      expect(output,
          contains('### Meal: Chicken curry — 683 kcal · cook 30 min · taste 4/5'));
      expect(output, contains('Notes: less oil, still good'));
      expect(output, contains('### Ungrouped'));
      expect(output.indexOf('banana'), greaterThan(output.indexOf('### Ungrouped')));
    });

    test('day without meals stays a flat list', () {
      final output = formatter.format(
        profile: profile,
        records: [
          record(description: 'apple', eatenAt: DateTime(2026, 6, 29, 9)),
        ],
        meals: [curry()],
      );

      expect(output, isNot(contains('### Ungrouped')));
      expect(output, isNot(contains('### Meal:')));
    });

    test('meal header includes cost sum of its records', () {
      final output = formatter.format(
        profile: profile,
        records: [
          record(
            value: 395,
            description: 'chicken',
            eatenAt: DateTime(2026, 6, 29, 13),
          )
            ..mealId = 'meal-1'
            ..costValue = 1.2
            ..costCurrency = 'EUR',
        ],
        meals: [curry()],
      );

      expect(output, contains('### Meal: Chicken curry — 395 kcal · cost 1.20 EUR'));
    });

    test('record with unknown mealId is treated as ungrouped', () {
      final output = formatter.format(
        profile: profile,
        records: [
          record(description: 'orphan', eatenAt: DateTime(2026, 6, 29, 9))
            ..mealId = 'deleted-meal',
        ],
      );

      expect(output, contains('- orphan — 100 kcal'));
      expect(output, isNot(contains('### Meal:')));
    });
  });

  group('weekly summary', () {
    test('rolls up per week with counted days, avg and cost', () {
      final output = formatter.format(profile: profile, records: [
        // Week of Mon 2026-06-22
        record(value: 1800, description: 'mon', eatenAt: DateTime(2026, 6, 22, 12))
          ..costValue = 5
          ..costCurrency = 'EUR',
        record(value: 1600, description: 'tue', eatenAt: DateTime(2026, 6, 23, 12))
          ..costValue = 4
          ..costCurrency = 'EUR',
        // Week of Mon 2026-06-29
        record(value: 2000, description: 'wed', eatenAt: DateTime(2026, 7, 1, 12)),
      ], now: DateTime(2026, 7, 2, 12));

      expect(output, contains('## Weekly summary'));
      expect(
          output,
          contains(
              '- 2026-06-22 .. 2026-06-28: 7 days counted · 5 empty · avg 485.7 kcal/day · cost 9 EUR'));
      expect(output,
          contains('- 2026-06-29 .. 2026-07-05: 3 days counted · 2 empty · avg 666.7 kcal/day'));
    });

    test('absent when nothing was eaten', () {
      final output = formatter.format(profile: profile, records: [
        record(description: 'planned only', createdAt: DateTime(2026, 7, 1)),
      ]);
      expect(output, isNot(contains('## Weekly summary')));
    });
  });

  group('tracking gaps', () {
    final now = DateTime(2026, 10, 26, 12);

    TrackingGap gap(DateTime start, DateTime end,
            {String? description, DateTime? deletedAt}) =>
        TrackingGap(
          id: '$start',
          profileId: 'p1',
          startedAt: start,
          endedAt: end,
          description: description,
          createdAt: now,
          updatedAt: now,
          deletedAt: deletedAt,
        );

    final eaten = record(value: 950, eatenAt: DateTime(2026, 10, 20, 12));
    final eveningGap = gap(
      DateTime(2026, 10, 20, 18),
      DateTime(2026, 10, 20, 23, 30),
      description: 'Dinner at friends,\n  plus cake',
    );

    test('lists each gap once, in order, with its description on one line', () {
      final output = formatter.format(profile: profile, records: [
        eaten,
      ], gaps: [
        eveningGap,
        gap(DateTime(2026, 10, 10), DateTime(2026, 10, 15),
            description: 'Holiday, mostly restaurants'),
      ], now: now);

      expect(
        output,
        contains('- 2026-10-10 .. 2026-10-14 (5 days): '
            'Holiday, mostly restaurants\n'
            '- 2026-10-20 18:00 .. 23:30: Dinner at friends, plus cake\n'),
      );
    });

    test('keeps the explanation under a custom preamble', () {
      final output = formatter.format(
        profile: profile,
        records: [eaten],
        gaps: [eveningGap],
        preamble: 'My own preamble',
        now: now,
      );

      expect(output, contains('## Tracking gaps'));
      expect(output, contains('rough recollection'));
    });

    test('has no section without gaps', () {
      final output =
          formatter.format(profile: profile, records: [eaten], now: now);

      expect(output, isNot(contains('## Tracking gaps')));
    });

    test('leaves out a deleted gap', () {
      final output = formatter.format(profile: profile, records: [
        eaten,
      ], gaps: [
        gap(DateTime(2026, 10, 20, 18), DateTime(2026, 10, 20, 20),
            deletedAt: now),
      ], now: now);

      expect(output, isNot(contains('## Tracking gaps')));
      expect(output, isNot(contains('incomplete')));
    });

    test('marks the header of a partial day', () {
      final output = formatter.format(
        profile: profile,
        records: [eaten],
        gaps: [eveningGap],
        now: now,
      );

      expect(
        output,
        contains('## 2026-10-20 — total 950 kcal '
            '(incomplete: overlaps a tracking gap)'),
      );
    });

    test('joins consecutive empty days into one range', () {
      final output = formatter.format(profile: profile, records: [
        record(value: 500, description: 'a', eatenAt: DateTime(2026, 10, 16, 9)),
        record(value: 500, description: 'b', eatenAt: DateTime(2026, 10, 19, 9)),
        record(value: 500, description: 'c', eatenAt: DateTime(2026, 10, 21, 9)),
      ], now: DateTime(2026, 10, 22, 9));

      expect(output, contains('## Unconfirmed empty days'));
      expect(output, contains('may have forgotten'));
      expect(output, contains('- 2026-10-17 .. 2026-10-18\n'));
      expect(output, contains('- 2026-10-20\n'));
    });

    test('the weekly summary follows the app rule for a partial day', () {
      final output = formatter.format(profile: profile, records: [
        for (var day = 19; day <= 23; day++)
          record(
            id: 'r$day',
            value: 2000,
            eatenAt: DateTime(2026, 10, day, 12),
          ),
        record(id: 'sat', value: 500, eatenAt: DateTime(2026, 10, 24, 12)),
      ], gaps: [
        gap(DateTime(2026, 10, 24, 18), DateTime(2026, 10, 24, 20)),
      ], now: DateTime(2026, 10, 26, 12));

      expect(
        output,
        contains('- 2026-10-19 .. 2026-10-25: 6 days counted · 1 partial · '
            '1 empty · avg 1666.7 kcal/day'),
      );
    });

    test('a week of unknown days has no average', () {
      final output = formatter.format(profile: profile, records: [
        record(value: 500, description: 'a', eatenAt: DateTime(2026, 10, 18, 9)),
      ], gaps: [
        gap(DateTime(2026, 10, 19), DateTime(2026, 10, 26)),
      ], now: DateTime(2026, 10, 26, 12));

      expect(
        output,
        contains('- 2026-10-19 .. 2026-10-25: 0 days counted · 7 unknown\n'),
      );
    });
  });

  group('stale prices', () {
    Product priced({required DateTime updatedAt}) =>
        product(id: 'a', title: 'Chicken', caloriesPer100g: 158)
          ..packageWeightGrams = 500
          ..pricePerPackage = 3.5
          ..priceCurrency = 'EUR'
          ..priceUpdatedAt = updatedAt;

    test('flags prices older than 90 days', () {
      final output = formatter.format(
        profile: profile,
        records: [],
        products: [priced(updatedAt: DateTime(2026, 1, 2))],
        now: DateTime(2026, 7, 3),
      );

      expect(output,
          contains('pack price 3.50 EUR (stale, from 2026-01-02)'));
    });

    test('fresh prices are not flagged', () {
      final output = formatter.format(
        profile: profile,
        records: [],
        products: [priced(updatedAt: DateTime(2026, 6, 1))],
        now: DateTime(2026, 7, 3),
      );

      expect(output, contains('pack price 3.50 EUR'));
      expect(output, isNot(contains('stale')));
    });
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
