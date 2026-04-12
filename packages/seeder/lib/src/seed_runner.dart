import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/products/domain/product_category.dart';

import 'seed_executor.dart';
import 'seed_generators.dart';

final class SeedRunner {
  final SeedExecutor executor;

  SeedRunner(this.executor);

  Future<void> run({required String profileId}) async {
    final now = DateTime.now();

    final categories = SeedGenerators.generateDefaultCategories(profileId, now);
    final categoriesByName = <String, ProductCategory>{};
    for (final cat in categories) {
      categoriesByName[cat.name] = await executor.saveProductCategory(cat);
    }

    final products = SeedGenerators.generateProducts(
      profileId,
      now,
      categoriesByName,
    );
    final productsByTitle = <String, Product>{};
    for (final prod in products) {
      productsByTitle[prod.title] = await executor.saveProduct(prod);
    }

    final yesterdayWp = SeedGenerators.generateYesterdayWakingPeriod(
      profileId,
      now,
    );
    final todayWp = SeedGenerators.generateTodayWakingPeriod(profileId, now);

    final savedYesterdayWp = await executor.saveWakingPeriod(yesterdayWp);
    final savedTodayWp = await executor.saveWakingPeriod(todayWp);

    final records = SeedGenerators.generateCalorieRecords(
      profileId,
      now,
      [savedTodayWp, savedYesterdayWp],
      productsByTitle,
    );

    for (final record in records) {
      await executor.saveCalorieRecord(record);
    }
  }
}
