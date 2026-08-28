import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

/// Increment 1 of the "planning a meal for a specific day" plan: the day a meal
/// is meant to be eaten, separate from the day it was entered. Nullable on both
/// tables — a meal grouped after the fact has no planned day, and every
/// existing row keeps NULL, so day grouping falls back to created_at as before.
class V016AddPlannedFor extends Migration {
  @override
  int get version => 16;

  @override
  Future<void> up(Database db) async {
    await addColumnIfNotExists(db, 'meals', 'planned_for', 'INT NULL');
    await addColumnIfNotExists(
        db, 'calorie_items', 'planned_for', 'INT NULL');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS calorie_items_planned_for_idx '
        'ON calorie_items(planned_for)');
  }
}
