import 'package:cat_calories/repositories/calorie_item_repository.dart';
import 'package:cat_calories/repositories/product_repository.dart';
import 'package:cat_calories/repositories/product_category_repository.dart';
import 'package:cat_calories/repositories/profile_repository.dart';
import 'package:cat_calories/repositories/waking_period_repository.dart';
import 'package:cat_calories/service/web_server_service.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void registerServices() {
  locator.registerLazySingleton<CalorieItemRepository>(() => CalorieItemRepository());
  locator.registerLazySingleton<ProfileRepository>(() => ProfileRepository());
  locator.registerLazySingleton<WakingPeriodRepository>(() => WakingPeriodRepository());
  locator.registerLazySingleton<ProductRepository>(() => ProductRepository());
  locator.registerLazySingleton<ProductCategoryRepository>(() => ProductCategoryRepository());
  locator.registerLazySingleton<WebServerService>(() => WebServerService());
}