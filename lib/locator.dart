import 'package:cat_calories/database/database.dart';
import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories/features/calorie_tracking/data/sqlite/calorie_record_repository.dart';
import 'package:cat_calories/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories/features/products/data/sqlite/product_repository.dart';
import 'package:cat_calories/features/products/data/sqlite/product_category_repository.dart';
import 'package:cat_calories/features/products/domain/product_repository_interface.dart';
import 'package:cat_calories/features/products/domain/product_category_repository_interface.dart';
import 'package:cat_calories/features/profile/data/sqlite/profile_repository.dart';
import 'package:cat_calories/features/profile/domain/profile_repository_interface.dart';
import 'package:cat_calories/features/waking_periods/data/sqlite/waking_period_repository.dart';
import 'package:cat_calories/features/waking_periods/domain/waking_period_repository_interface.dart';
import 'package:cat_calories/service/sync_service.dart';
import 'package:cat_calories/service/web_server_service.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void registerServices() {
  locator.registerLazySingleton<DatabaseClient>(() => DBProvider.db);
  locator.registerLazySingleton<CalorieRecordRepositoryInterface>(() => CalorieRecordRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<ProfileRepositoryInterface>(() => ProfileRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<WakingPeriodRepositoryInterface>(() => WakingPeriodRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<ProductRepositoryInterface>(() => ProductRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<ProductCategoryRepositoryInterface>(() => ProductCategoryRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<WebServerService>(() => WebServerService());
  locator.registerLazySingleton<SyncService>(() => SyncService());
}