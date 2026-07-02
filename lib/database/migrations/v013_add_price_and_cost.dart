import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

/// Increment B of docs/plans/master_plan.md: package price on products,
/// cost snapshot on calorie items, default currency on profiles.
/// All nullable — price/cost tracking is optional enrichment.
class V013AddPriceAndCost extends Migration {
  @override
  int get version => 13;

  @override
  Future<void> up(Database db) async {
    await addColumnIfNotExists(
        db, 'products', 'price_per_package', 'REAL NULL');
    await addColumnIfNotExists(db, 'products', 'price_currency', 'TEXT NULL');
    await addColumnIfNotExists(
        db, 'products', 'price_updated_at', 'INT NULL');

    await addColumnIfNotExists(db, 'calorie_items', 'cost_value', 'REAL NULL');
    await addColumnIfNotExists(
        db, 'calorie_items', 'cost_currency', 'TEXT NULL');
    await addColumnIfNotExists(
        db, 'calorie_items', 'cost_is_manual', 'INT NOT NULL DEFAULT 0');

    await addColumnIfNotExists(
        db, 'profiles', 'default_currency', 'TEXT NULL');
  }
}
