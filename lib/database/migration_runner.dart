import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';
import 'package:cat_calories/database/migrations/v001_initial_schema.dart';
import 'package:cat_calories/database/migrations/v002_add_nutrition_columns.dart';
import 'package:cat_calories/database/migrations/v003_add_package_weight.dart';
import 'package:cat_calories/database/migrations/v004_add_category_support.dart';
import 'package:cat_calories/database/migrations/v005_add_product_id_and_indexes.dart';
import 'package:cat_calories/database/migrations/v006_migrate_calorie_items_to_uuid.dart';
import 'package:cat_calories/database/migrations/v007_add_calorie_items_updated_at.dart';
import 'package:cat_calories/database/migrations/v008_migrate_profiles_to_uuid.dart';
import 'package:cat_calories/database/migrations/v009_migrate_waking_periods_to_uuid.dart';
import 'package:cat_calories/database/migrations/v010_add_sync_servers.dart';
import 'package:cat_calories/database/migrations/v011_add_auth_credentials.dart';
import 'package:cat_calories/database/migrations/v012_add_server_urls.dart';

class MigrationRunner {
  static const currentVersion = 12;

  static final List<Migration> _migrations = [
    V002AddNutritionColumns(),
    V003AddPackageWeight(),
    V004AddCategorySupport(),
    V005AddProductIdAndIndexes(),
    V006MigrateCalorieItemsToUuid(),
    V007AddCalorieItemsUpdatedAt(),
    V008MigrateProfilesToUuid(),
    V009MigrateWakingPeriodsToUuid(),
    V010AddSyncServers(),
    V011AddAuthCredentials(),
    V012AddServerUrls(),
  ];

  Future<void> onCreate(Database db, int version) async {
    await V001InitialSchema().up(db);
  }

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (final migration in _migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        await migration.up(db);
      }
    }
  }

  Future<void> onDowngrade(Database db, int oldVersion, int newVersion) async {
    // Downgrades not supported
  }
}
