import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

/// `created_at_day` had held the day a record was created; since the planned-day
/// work it holds the day a record *belongs to* — eaten, else planned, else
/// entered — which is what `recordDay` in core computes. The name outlived its
/// meaning, so the column becomes `record_day`.
///
/// Migrations before this one keep the old name on purpose: v001 as it was at
/// the time, v006 rebuilding the v6-era table, v017 back-filling values while
/// the column was still called `created_at_day`. Each runs against the schema
/// of its own moment, and rewriting them would break the upgrade path from any
/// database old enough to need them.
class V018RenameRecordDay extends Migration {
  @override
  int get version => 18;

  @override
  Future<void> up(Database db) async {
    if (await columnExists(db, 'calorie_items', 'record_day')) {
      return;
    }
    await db.execute(
        'ALTER TABLE calorie_items RENAME COLUMN created_at_day TO record_day');
    // The index follows the column: SQLite keeps it working under the old name,
    // but a stale name is what this migration exists to get rid of.
    await db.execute('DROP INDEX IF EXISTS calorie_items_created_at_day_idx');
    await db.execute('CREATE INDEX IF NOT EXISTS calorie_items_record_day_idx '
        'ON calorie_items(record_day)');
  }
}
