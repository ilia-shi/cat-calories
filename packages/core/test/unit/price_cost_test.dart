import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:test/test.dart';

void main() {
  group('Product price', () {
    Product product({
      double? pricePerPackage,
      double? packageWeightGrams,
      String? priceCurrency,
    }) =>
        Product(
          id: 'p1',
          title: 'Chicken',
          description: null,
          usesCount: 0,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          profileId: 'prof-1',
          barcode: null,
          sortOrder: 0,
          packageWeightGrams: packageWeightGrams,
          pricePerPackage: pricePerPackage,
          priceCurrency: priceCurrency,
          priceUpdatedAt: DateTime(2026, 6, 1),
        );

    test('calculateCost scales package price by weight', () {
      final p = product(pricePerPackage: 5, packageWeightGrams: 500);
      expect(p.calculateCost(250), 2.5);
      expect(p.hasPrice, isTrue);
    });

    test('calculateCost is null without price or package weight', () {
      expect(product(pricePerPackage: 5).calculateCost(100), isNull);
      expect(product(packageWeightGrams: 500).calculateCost(100), isNull);
      expect(product(pricePerPackage: 5).hasPrice, isFalse);
    });

    test('price fields survive JSON round-trip', () {
      final p = product(
        pricePerPackage: 3.99,
        packageWeightGrams: 400,
        priceCurrency: 'EUR',
      );
      final restored = Product.fromJson(p.toJson());
      expect(restored.pricePerPackage, 3.99);
      expect(restored.priceCurrency, 'EUR');
      expect(restored.priceUpdatedAt, DateTime(2026, 6, 1));
    });

    test('copyWith carries price fields', () {
      final p = product(pricePerPackage: 3.99, priceCurrency: 'EUR')
          .copyWith(title: 'Renamed');
      expect(p.pricePerPackage, 3.99);
      expect(p.priceCurrency, 'EUR');
    });
  });

  group('CalorieRecord cost snapshot', () {
    CalorieRecord record({
      double? costValue,
      String? costCurrency,
      bool costIsManual = false,
    }) =>
        CalorieRecord(
          id: 'r1',
          value: 100,
          description: 'x',
          sortOrder: 0,
          eatenAt: DateTime(2026, 6, 29),
          createdAt: DateTime(2026, 6, 29),
          profileId: 'prof-1',
          wakingPeriodId: null,
          costValue: costValue,
          costCurrency: costCurrency,
          costIsManual: costIsManual,
        );

    test('cost fields survive JSON round-trip, bool stored as 0/1', () {
      final json =
          record(costValue: 2.5, costCurrency: 'EUR', costIsManual: true)
              .toJson();
      expect(json['cost_is_manual'], 1);

      final restored = CalorieRecord.fromJson(json);
      expect(restored.costValue, 2.5);
      expect(restored.costCurrency, 'EUR');
      expect(restored.costIsManual, isTrue);
    });

    test('defaults: no cost, not manual', () {
      final restored = CalorieRecord.fromJson(record().toJson());
      expect(restored.costValue, isNull);
      expect(restored.costCurrency, isNull);
      expect(restored.costIsManual, isFalse);
    });
  });

  group('Profile default currency', () {
    test('survives JSON round-trip and defaults to null', () {
      final profile = Profile(
        id: 'p1',
        name: 'Ilya',
        wakingTimeSeconds: 57600,
        caloriesLimitGoal: 1800,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        defaultCurrency: 'EUR',
      );
      expect(Profile.fromJson(profile.toJson()).defaultCurrency, 'EUR');

      profile.defaultCurrency = null;
      expect(Profile.fromJson(profile.toJson()).defaultCurrency, isNull);
    });
  });
}
