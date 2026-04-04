import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';
import 'package:cat_calories/database/migrations/uuid_table_migrator.dart';

class V006MigrateCalorieItemsToUuid extends Migration {
  @override
  int get version => 6;

  @override
  Future<void> up(Database db) async {
    await UuidTableMigrator.migrate(
      db,
      table: 'calorie_items',
      createNewTableSql: '''
        CREATE TABLE calorie_items_new (
          id TEXT PRIMARY KEY NOT NULL,
          value REAL,
          title TEXT NULL,
          description TEXT NULL,
          sort_order INT,
          created_at INT,
          created_at_day INT,
          eaten_at INT NULL,
          profile_id TEXT,
          waking_period_id TEXT,
          weight_grams REAL NULL,
          protein_grams REAL NULL,
          fat_grams REAL NULL,
          carb_grams REAL NULL,
          product_id TEXT NULL,
          FOREIGN KEY(profile_id) REFERENCES profiles(id),
          FOREIGN KEY(waking_period_id) REFERENCES waking_periods(id),
          FOREIGN KEY(product_id) REFERENCES products(id)
        )
      ''',
      postMigrationSql: [
        'CREATE INDEX IF NOT EXISTS calorie_items_created_at_day_idx ON calorie_items(created_at_day)',
        'CREATE INDEX IF NOT EXISTS calorie_items_product_id_idx ON calorie_items(product_id)',
      ],
    );
  }
}
