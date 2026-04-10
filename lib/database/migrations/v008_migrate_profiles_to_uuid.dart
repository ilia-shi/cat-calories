import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';
import 'package:cat_calories/database/migrations/uuid_table_migrator.dart';

class V008MigrateProfilesToUuid extends Migration {
  @override
  int get version => 8;

  @override
  Future<void> up(Database db) async {
    await UuidTableMigrator.migrate(
      db,
      table: 'profiles',
      createNewTableSql: '''
        CREATE TABLE profiles_new (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT,
          created_at INT,
          updated_at INT,
          waking_time_seconds INT,
          calories_limit_goal REAL
        )
      ''',
      foreignKeyUpdates: [
        ForeignKeyUpdate('waking_periods', 'profile_id'),
        ForeignKeyUpdate('calorie_items', 'profile_id'),
        ForeignKeyUpdate('products', 'profile_id'),
        ForeignKeyUpdate('product_categories', 'profile_id'),
      ],
    );
  }
}
