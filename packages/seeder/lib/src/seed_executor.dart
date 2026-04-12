import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/products/domain/product_category.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';

abstract interface class SeedExecutor {
  Future<Profile> saveProfile(Profile profile);
  Future<ProductCategory> saveProductCategory(ProductCategory category);
  Future<Product> saveProduct(Product product);
  Future<WakingPeriod> saveWakingPeriod(WakingPeriod period);
  Future<CalorieRecord> saveCalorieRecord(CalorieRecord record);
}
