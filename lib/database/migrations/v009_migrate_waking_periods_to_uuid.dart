import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';
import 'package:cat_calories/database/migrations/uuid_table_migrator.dart';

class V009MigrateWakingPeriodsToUuid extends Migration {
  @override
  int get version => 9;

  @override
  Future<void> up(Database db) async {
    await UuidTableMigrator.migrate(
      db,
      table: 'waking_periods',
      createNewTableSql: '''
        CREATE TABLE waking_periods_new (
          id TEXT PRIMARY KEY NOT NULL,
          description TEXT NULL,
          created_at INT,
          updated_at INT,
          started_at INT,
          ended_at INT NULL,
          calories_value REAL,
          profile_id TEXT,
          expected_waking_time_seconds INT,
          calories_limit_goal REAL,
          FOREIGN KEY(profile_id) REFERENCES profiles(id)
        )
      ''',
      foreignKeyUpdates: [
        ForeignKeyUpdate('calorie_items', 'waking_period_id'),
      ],
    );
  }
}
