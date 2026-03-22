import 'package:cat_calories/database/database.dart';
import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories/features/calorie_tracking/calorie_record_repository.dart';
import 'package:cat_calories/features/products/product_repository.dart';
import 'package:cat_calories/features/products/product_category_repository.dart';
import 'package:cat_calories/features/profile/profile_repository.dart';
import 'package:cat_calories/features/waking_periods/waking_period_repository.dart';
import 'package:cat_calories/service/sync_service.dart';
import 'package:cat_calories/service/web_server_service.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void registerServices() {
  locator.registerLazySingleton<DatabaseClient>(() => DBProvider.db);
  locator.registerLazySingleton<CalorieRecordRepository>(() => CalorieRecordRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<ProfileRepository>(() => ProfileRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<WakingPeriodRepository>(() => WakingPeriodRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<ProductRepository>(() => ProductRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<ProductCategoryRepository>(() => ProductCategoryRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<WebServerService>(() => WebServerService());
  locator.registerLazySingleton<SyncService>(() => SyncService());
}