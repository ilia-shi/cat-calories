import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/products/domain/product_category.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';

final class SeedGenerators {
  SeedGenerators._();

  static const _defaultWakingSeconds = 16 * 60 * 60; // 16 hours
  static const _defaultCalorieGoal = 2000.0;

  static Profile generateProfile(DateTime now) {
    return Profile(
      id: null,
      name: 'Default Profile',
      wakingTimeSeconds: _defaultWakingSeconds,
      caloriesLimitGoal: _defaultCalorieGoal,
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<ProductCategory> generateDefaultCategories(
    String profileId,
    DateTime now,
  ) {
    const defaults = [
      ('Beverages', 'local_drink', '#2196F3'),
      ('Fruits & Vegetables', 'eco', '#4CAF50'),
      ('Dairy', 'egg', '#FFC107'),
      ('Meat & Fish', 'restaurant', '#F44336'),
      ('Grains & Bread', 'bakery_dining', '#795548'),
      ('Snacks', 'cookie', '#FF9800'),
      ('Other', 'category', '#9E9E9E'),
    ];

    return [
      for (int i = 0; i < defaults.length; i++)
        ProductCategory(
          id: null,
          name: defaults[i].$1,
          iconName: defaults[i].$2,
          colorHex: defaults[i].$3,
          sortOrder: i,
          profileId: profileId,
          createdAt: now,
          updatedAt: now,
        ),
    ];
  }

  static List<Product> generateProducts(
    String profileId,
    DateTime now,
    Map<String, ProductCategory> categoriesByName,
  ) {
    return [
      Product(
        id: null,
        title: 'Oatmeal',
        description: 'Rolled oats, dry',
        barcode: null,
        caloriesPer100g: 370,
        proteinsPer100g: 13,
        fatsPer100g: 7,
        carbsPer100g: 60,
        packageWeightGrams: 500,
        categoryId: categoriesByName['Grains & Bread']?.id,
        usesCount: 5,
        sortOrder: 0,
        profileId: profileId,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: null,
        title: 'Chicken Breast',
        description: 'Skinless, cooked',
        barcode: null,
        caloriesPer100g: 165,
        proteinsPer100g: 31,
        fatsPer100g: 3.6,
        carbsPer100g: 0,
        packageWeightGrams: null,
        categoryId: categoriesByName['Meat & Fish']?.id,
        usesCount: 4,
        sortOrder: 1,
        profileId: profileId,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: null,
        title: 'White Rice',
        description: 'Cooked long-grain',
        barcode: null,
        caloriesPer100g: 130,
        proteinsPer100g: 2.7,
        fatsPer100g: 0.3,
        carbsPer100g: 28,
        packageWeightGrams: null,
        categoryId: categoriesByName['Grains & Bread']?.id,
        usesCount: 3,
        sortOrder: 2,
        profileId: profileId,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: null,
        title: 'Eggs',
        description: 'Whole, large',
        barcode: null,
        caloriesPer100g: 155,
        proteinsPer100g: 13,
        fatsPer100g: 11,
        carbsPer100g: 1.1,
        packageWeightGrams: null,
        categoryId: categoriesByName['Dairy']?.id,
        usesCount: 3,
        sortOrder: 3,
        profileId: profileId,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: null,
        title: 'Salmon Fillet',
        description: 'Atlantic, raw',
        barcode: null,
        caloriesPer100g: 208,
        proteinsPer100g: 20,
        fatsPer100g: 13,
        carbsPer100g: 0,
        packageWeightGrams: null,
        categoryId: categoriesByName['Meat & Fish']?.id,
        usesCount: 2,
        sortOrder: 4,
        profileId: profileId,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: null,
        title: 'Apple',
        description: 'Fresh, medium',
        barcode: null,
        caloriesPer100g: 52,
        proteinsPer100g: 0.3,
        fatsPer100g: 0.2,
        carbsPer100g: 14,
        packageWeightGrams: null,
        categoryId: categoriesByName['Fruits & Vegetables']?.id,
        usesCount: 4,
        sortOrder: 5,
        profileId: profileId,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  static WakingPeriod generateTodayWakingPeriod(
    String profileId,
    DateTime now,
  ) {
    final todayStart = DateTime(now.year, now.month, now.day, 7, 0);
    return WakingPeriod(
      id: null,
      description: null,
      startedAt: todayStart,
      endedAt: null,
      caloriesValue: 0,
      profileId: profileId,
      expectedWakingTimeSeconds: _defaultWakingSeconds,
      caloriesLimitGoal: _defaultCalorieGoal,
      createdAt: now,
      updatedAt: now,
    );
  }

  static WakingPeriod generateYesterdayWakingPeriod(
    String profileId,
    DateTime now,
  ) {
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStart = DateTime(
      yesterday.year, yesterday.month, yesterday.day, 7, 30,
    );
    final yesterdayEnd = DateTime(
      yesterday.year, yesterday.month, yesterday.day, 23, 30,
    );
    return WakingPeriod(
      id: null,
      description: null,
      startedAt: yesterdayStart,
      endedAt: yesterdayEnd,
      caloriesValue: 1710,
      profileId: profileId,
      expectedWakingTimeSeconds: _defaultWakingSeconds,
      caloriesLimitGoal: _defaultCalorieGoal,
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<CalorieRecord> generateCalorieRecords(
    String profileId,
    DateTime now,
    List<WakingPeriod> wakingPeriods,
    Map<String, Product> productsByTitle,
  ) {
    final records = <CalorieRecord>[];

    final todayWp = wakingPeriods.firstWhere(
      (wp) => wp.endedAt == null,
      orElse: () => wakingPeriods.last,
    );
    final yesterdayWp = wakingPeriods.length > 1 ? wakingPeriods[1] : null;

    int sortOrder = 0;

    void r({
      required int daysAgo,
      required int hour,
      required int minute,
      required double value,
      required String description,
      Product? product,
      double? weightGrams,
      WakingPeriod? period,
      bool eaten = true,
    }) {
      final day = now.subtract(Duration(days: daysAgo));
      final timestamp = DateTime(day.year, day.month, day.day, hour, minute);
      final eatenAt = eaten ? timestamp : null;

      double? proteinGrams;
      double? fatGrams;
      double? carbGrams;

      if (product != null && weightGrams != null) {
        proteinGrams = product.calculateProtein(weightGrams);
        fatGrams = product.calculateFat(weightGrams);
        carbGrams = product.calculateCarbs(weightGrams);
      }

      records.add(CalorieRecord(
        id: null,
        value: value,
        description: description,
        sortOrder: sortOrder++,
        eatenAt: eatenAt,
        createdAt: timestamp,
        profileId: profileId,
        wakingPeriodId: period?.id,
        weightGrams: weightGrams,
        proteinGrams: proteinGrams,
        fatGrams: fatGrams,
        carbGrams: carbGrams,
        productId: product?.id,
      ));
    }

    final oats = productsByTitle['Oatmeal'];
    final chicken = productsByTitle['Chicken Breast'];
    final rice = productsByTitle['White Rice'];
    final eggs = productsByTitle['Eggs'];
    final salmon = productsByTitle['Salmon Fillet'];
    final apple = productsByTitle['Apple'];

    // --- Day -6 ---
    r(daysAgo: 6, hour: 8, minute: 0, value: 222, description: 'Morning oatmeal', product: oats, weightGrams: 60);
    r(daysAgo: 6, hour: 8, minute: 15, value: 50, description: 'Coffee with milk');
    r(daysAgo: 6, hour: 13, minute: 0, value: 508, description: 'Chicken with rice', product: chicken, weightGrams: 150);
    r(daysAgo: 6, hour: 13, minute: 30, value: 260, description: 'Side of rice', product: rice, weightGrams: 200);
    r(daysAgo: 6, hour: 19, minute: 0, value: 420, description: 'Light dinner salad');
    r(daysAgo: 6, hour: 21, minute: 0, value: 94, description: 'Evening apple', product: apple, weightGrams: 180);

    // --- Day -5 ---
    r(daysAgo: 5, hour: 9, minute: 0, value: 310, description: 'Scrambled eggs on toast', product: eggs, weightGrams: 200);
    r(daysAgo: 5, hour: 9, minute: 15, value: 180, description: 'Toast with butter');
    r(daysAgo: 5, hour: 14, minute: 0, value: 650, description: 'Chicken rice bowl', product: rice, weightGrams: 300);
    r(daysAgo: 5, hour: 20, minute: 0, value: 480, description: 'Salmon with veggies', product: salmon, weightGrams: 230);
    r(daysAgo: 5, hour: 22, minute: 0, value: 300, description: 'Ice cream dessert');

    // --- Day -4 ---
    r(daysAgo: 4, hour: 7, minute: 30, value: 280, description: 'Oatmeal breakfast', product: oats, weightGrams: 75);
    r(daysAgo: 4, hour: 12, minute: 0, value: 550, description: 'Chicken wrap', product: chicken, weightGrams: 220);
    r(daysAgo: 4, hour: 19, minute: 30, value: 800, description: 'Dinner out — pasta');

    // --- Day -3 ---
    r(daysAgo: 3, hour: 8, minute: 0, value: 450, description: 'Eggs and toast breakfast', product: eggs, weightGrams: 200);
    r(daysAgo: 3, hour: 13, minute: 0, value: 500, description: 'Rice with stir-fried vegetables', product: rice, weightGrams: 385);
    r(daysAgo: 3, hour: 18, minute: 0, value: 416, description: 'Salmon fillet', product: salmon, weightGrams: 200);
    r(daysAgo: 3, hour: 20, minute: 0, value: 250, description: 'Chocolate bar');

    // --- Day -2 ---
    r(daysAgo: 2, hour: 9, minute: 0, value: 300, description: 'Hearty oatmeal', product: oats, weightGrams: 80);
    r(daysAgo: 2, hour: 14, minute: 0, value: 480, description: 'Chicken salad bowl', product: chicken, weightGrams: 200);
    r(daysAgo: 2, hour: 19, minute: 0, value: 650, description: 'Pasta bolognese');
    r(daysAgo: 2, hour: 21, minute: 0, value: 95, description: 'Apple snack', product: apple, weightGrams: 183);

    // --- Day -1 (yesterday) ---
    r(daysAgo: 1, hour: 8, minute: 15, value: 310, description: 'Scrambled eggs', product: eggs, weightGrams: 200, period: yesterdayWp);
    r(daysAgo: 1, hour: 8, minute: 30, value: 180, description: 'Toast with butter', period: yesterdayWp);
    r(daysAgo: 1, hour: 13, minute: 30, value: 520, description: 'Rice bowl with vegetables', product: rice, weightGrams: 400, period: yesterdayWp);
    r(daysAgo: 1, hour: 19, minute: 30, value: 500, description: 'Salmon dinner', product: salmon, weightGrams: 240, period: yesterdayWp);
    r(daysAgo: 1, hour: 22, minute: 0, value: 200, description: 'Late night cereal', period: yesterdayWp);

    // --- Day 0 (today) ---
    r(daysAgo: 0, hour: 8, minute: 0, value: 250, description: 'Oatmeal with berries', product: oats, weightGrams: 68, period: todayWp);
    r(daysAgo: 0, hour: 8, minute: 20, value: 50, description: 'Coffee with milk', period: todayWp);
    r(daysAgo: 0, hour: 13, minute: 0, value: 248, description: 'Grilled chicken breast', product: chicken, weightGrams: 150, period: todayWp);
    r(daysAgo: 0, hour: 13, minute: 10, value: 260, description: 'White rice', product: rice, weightGrams: 200, period: todayWp);
    r(daysAgo: 0, hour: 15, minute: 30, value: 94, description: 'Afternoon apple', product: apple, weightGrams: 180, period: todayWp);
    r(daysAgo: 0, hour: 19, minute: 0, value: 500, description: 'Planned — salmon dinner', product: salmon, weightGrams: 240, period: todayWp, eaten: false);
    r(daysAgo: 0, hour: 21, minute: 0, value: 150, description: 'Planned — evening snack', period: todayWp, eaten: false);

    return records;
  }
}
