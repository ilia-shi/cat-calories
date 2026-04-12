import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/products/domain/product_category.dart';
import 'package:cat_calories_core/features/products/domain/product_category_repository_interface.dart';
import 'package:cat_calories_core/features/products/domain/product_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/profile/domain/profile_repository_interface.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period_repository_interface.dart';
import 'package:cat_calories_seeds/cat_calories_seeds.dart';
import 'package:get_it/get_it.dart';

final class CalorieItemSeedExecutor implements SeedExecutor {
  final CalorieRecordRepositoryInterface calorieRepo;
  final ProfileRepositoryInterface profileRepo;
  final ProductCategoryRepositoryInterface categoryRepo;
  final ProductRepositoryInterface productRepo;
  final WakingPeriodRepositoryInterface wakingPeriodRepo;

  CalorieItemSeedExecutor({
    required this.calorieRepo,
    required this.profileRepo,
    required this.categoryRepo,
    required this.productRepo,
    required this.wakingPeriodRepo,
  });

  static CalorieItemSeedExecutor fromLocator() {
    final locator = GetIt.instance;
    return CalorieItemSeedExecutor(
      calorieRepo: locator.get<CalorieRecordRepositoryInterface>(),
      profileRepo: locator.get<ProfileRepositoryInterface>(),
      categoryRepo: locator.get<ProductCategoryRepositoryInterface>(),
      productRepo: locator.get<ProductRepositoryInterface>(),
      wakingPeriodRepo: locator.get<WakingPeriodRepositoryInterface>(),
    );
  }

  @override
  Future<Profile> saveProfile(Profile profile) {
    return profileRepo.insert(profile);
  }

  @override
  Future<ProductCategory> saveProductCategory(ProductCategory category) {
    return categoryRepo.insert(category);
  }

  @override
  Future<Product> saveProduct(Product product) {
    return productRepo.insert(product);
  }

  @override
  Future<WakingPeriod> saveWakingPeriod(WakingPeriod period) {
    return wakingPeriodRepo.insert(period);
  }

  @override
  Future<CalorieRecord> saveCalorieRecord(CalorieRecord record) {
    return calorieRepo.insert(record);
  }

  static Future<void> seedIfNeeded({required String profileId}) async {
    final executor = CalorieItemSeedExecutor.fromLocator();
    final runner = SeedRunner(executor);
    await runner.run(profileId: profileId);
  }
}
