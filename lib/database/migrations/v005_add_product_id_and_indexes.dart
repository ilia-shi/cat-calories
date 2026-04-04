import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V005AddProductIdAndIndexes extends Migration {
  @override
  int get version => 5;

  @override
  Future<void> up(Database db) async {
    await addColumnIfNotExists(db, 'calorie_items', 'product_id', 'TEXT NULL');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS calorie_items_product_id_idx ON calorie_items(product_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS products_category_id_idx ON products(category_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS products_last_used_at_idx ON products(last_used_at)');
  }
}
