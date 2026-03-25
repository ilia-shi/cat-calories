import 'package:cat_calories/database/database.dart';
import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories/features/calorie_tracking/data/sqlite/calorie_record_repository.dart';
import 'package:cat_calories/features/calorie_tracking/data/sync/calorie_record_sync_adapter.dart';
import 'package:cat_calories/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories/features/products/data/sqlite/product_repository.dart';
import 'package:cat_calories/features/products/data/sqlite/product_category_repository.dart';
import 'package:cat_calories/features/products/domain/product_repository_interface.dart';
import 'package:cat_calories/features/products/domain/product_category_repository_interface.dart';
import 'package:cat_calories/features/profile/data/sqlite/profile_repository.dart';
import 'package:cat_calories/features/profile/domain/profile_repository_interface.dart';
import 'package:cat_calories/features/waking_periods/data/sqlite/waking_period_repository.dart';
import 'package:cat_calories/features/waking_periods/domain/waking_period_repository_interface.dart';
import 'package:cat_calories/features/sync/data/sqlite/scoped_server_repository.dart';
import 'package:cat_calories/features/sync/data/sqlite/server_repository.dart';
import 'package:cat_calories/features/sync/domain/scoped_server_link_repository.dart';
import 'package:cat_calories/features/sync/domain/sync_server_repository.dart';
import 'package:cat_calories/service/sync_service.dart';
import 'package:cat_calories/service/web_server_service.dart';
import 'package:get_it/get_it.dart';

import 'features/sync/sync_adapter.dart';

final locator = GetIt.instance;

final syncRegistry = SyncAdapterRegistry()
  ..register(CalorieRecordSyncAdapter());

void registerServices() {
  locator.registerLazySingleton<DatabaseClient>(() => DBProvider.db);
  locator.registerLazySingleton<CalorieRecordRepositoryInterface>(
      () => CalorieRecordRepository(locator<DatabaseClient>()));
  locator.registerLazySingleton<ProfileRepositoryInterface>(
    () => ProfileRepository(locator<DatabaseClient>()),
  );
  locator.registerLazySingleton<WakingPeriodRepositoryInterface>(
    () => WakingPeriodRepository(locator<DatabaseClient>()),
  );
  locator.registerLazySingleton<ProductRepositoryInterface>(
    () => ProductRepository(locator<DatabaseClient>()),
  );
  locator.registerLazySingleton<ProductCategoryRepositoryInterface>(
    () => ProductCategoryRepository(locator<DatabaseClient>()),
  );
  locator.registerLazySingleton<SyncServerRepositoryInterface>(
    () => SyncServerRepository(locator<DatabaseClient>()),
  );
  locator.registerLazySingleton<ScopedServerLinkRepositoryInterface>(
    () => ScopedServerLinkRepository(locator<DatabaseClient>()),
  );
  locator.registerLazySingleton<WebServerService>(() => WebServerService());
  locator.registerLazySingleton<SyncService>(() => SyncService());
  locator.registerLazySingleton<SyncAdapterRegistry>(
    () => SyncAdapterRegistry()
      ..register(
        CalorieRecordSyncAdapter(),
      ),
  );
}
