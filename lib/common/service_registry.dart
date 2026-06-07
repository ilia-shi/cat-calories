import 'package:cat_calories/common/locator.dart';
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
import 'package:cat_calories/features/sync/sync_service.dart';
import 'package:cat_calories/features/embedded_server/embedded_server_service.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';

void registerServices() {
  locator.registerLazySingleton<DatabaseClient>(() => AppDatabase.instance);
  locator.registerLazySingleton<CalorieRecordRepositoryInterface>(
      () => CalorieRecordRepository(locator.get<DatabaseClient>()));
  locator.registerLazySingleton<ProfileRepositoryInterface>(
    () => ProfileRepository(locator.get<DatabaseClient>()),
  );
  locator.registerLazySingleton<WakingPeriodRepositoryInterface>(
    () => WakingPeriodRepository(locator.get<DatabaseClient>()),
  );
  locator.registerLazySingleton<ProductRepositoryInterface>(
    () => ProductRepository(locator.get<DatabaseClient>()),
  );
  locator.registerLazySingleton<ProductCategoryRepositoryInterface>(
    () => ProductCategoryRepository(locator.get<DatabaseClient>()),
  );
  locator.registerLazySingleton<SyncServerRepositoryInterface>(
    () => SyncServerRepository(locator.get<DatabaseClient>()),
  );
  locator.registerLazySingleton<ScopedServerLinkRepositoryInterface>(
    () => ScopedServerLinkRepository(locator.get<DatabaseClient>()),
  );
  locator.registerLazySingleton<AuthCredentialsRepositoryInterface>(
    () => AuthCredentialsRepository(locator.get<DatabaseClient>()),
  );
  locator.registerLazySingleton<AuthClient>(() => AuthClient());
  locator.registerLazySingleton<EmbeddedServerService>(() => EmbeddedServerService());
  locator.registerLazySingleton<SyncService>(() => SyncService());
  locator.registerLazySingleton<SyncAdapterRegistry>(() {
    final registry = SyncAdapterRegistry();
    registry.register(
      CalorieRecordSyncAdapter(),
      CalorieRecordSyncRepository(locator.get<CalorieRecordRepositoryInterface>()),
    );
    // Register more entity types here:
    // registry.register(ProductSyncAdapter(), ProductSyncRepository(...));
    return registry;
  });
  locator.registerLazySingleton<Syncer>(() => Syncer(
    serverRepo: locator.get<SyncServerRepositoryInterface>(),
    credentialsRepo: locator.get<AuthCredentialsRepositoryInterface>(),
    linkRepo: locator.get<ScopedServerLinkRepositoryInterface>(),
    registry: locator.get<SyncAdapterRegistry>(),
  ));
}
