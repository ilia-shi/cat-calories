import 'package:cat_calories/database/app_database.dart';
import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories/features/calorie_tracking/data/calorie_record_sync_repository.dart';
import 'package:cat_calories/features/calorie_tracking/data/sqlite/calorie_record_repository.dart';
import 'package:cat_calories_core/features/calorie_tracking/sync/calorie_record_sync_adapter.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories/features/products/data/sqlite/product_repository.dart';
import 'package:cat_calories/features/products/data/sqlite/product_category_repository.dart';
import 'package:cat_calories_core/features/products/domain/product_repository_interface.dart';
import 'package:cat_calories_core/features/products/domain/product_category_repository_interface.dart';
import 'package:cat_calories/features/profile/data/sqlite/profile_repository.dart';
import 'package:cat_calories_core/features/profile/domain/profile_repository_interface.dart';
import 'package:cat_calories/features/waking_periods/data/sqlite/waking_period_repository.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period_repository_interface.dart';
import 'package:cat_calories/features/oauth/auth_client.dart';
import 'package:cat_calories/features/oauth/data/sqlite/auth_credentials_repository.dart';
import 'package:cat_calories_core/features/oauth/domain/auth_credentials_repository.dart';
import 'package:cat_calories/features/sync/data/sqlite/scoped_server_repository.dart';
import 'package:cat_calories/features/sync/data/sqlite/server_repository.dart';
import 'package:cat_calories_core/features/sync/domain/scoped_server_link_repository.dart';
import 'package:cat_calories_core/features/sync/domain/sync_server_repository.dart';
import 'package:cat_calories/features/sync/syncer.dart';
import 'package:cat_calories/service/sync_service.dart';
import 'package:cat_calories/service/embedded_server_service.dart';
import 'package:get_it/get_it.dart';

import 'package:cat_calories_core/features/sync/sync_adapter.dart';

final locator = GetIt.instance;

void registerServices() {
  locator.registerLazySingleton<DatabaseClient>(() => AppDatabase.instance);
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
  locator.registerLazySingleton<AuthCredentialsRepositoryInterface>(
    () => AuthCredentialsRepository(locator<DatabaseClient>()),
  );
  locator.registerLazySingleton<AuthClient>(() => AuthClient());
  locator.registerLazySingleton<EmbeddedServerService>(() => EmbeddedServerService());
  locator.registerLazySingleton<SyncService>(() => SyncService());
  locator.registerLazySingleton<SyncAdapterRegistry>(() {
    final registry = SyncAdapterRegistry();
    registry.register(
      CalorieRecordSyncAdapter(),
      CalorieRecordSyncRepository(locator<CalorieRecordRepositoryInterface>()),
    );
    // Register more entity types here:
    // registry.register(ProductSyncAdapter(), ProductSyncRepository(...));
    return registry;
  });
  locator.registerLazySingleton<Syncer>(() => Syncer(
    serverRepo: locator<SyncServerRepositoryInterface>(),
    credentialsRepo: locator<AuthCredentialsRepositoryInterface>(),
    linkRepo: locator<ScopedServerLinkRepositoryInterface>(),
    registry: locator<SyncAdapterRegistry>(),
  ));
}
