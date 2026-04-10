import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V004AddCategorySupport extends Migration {
  @override
  int get version => 4;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_categories (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        icon_name TEXT NULL,
        color_hex TEXT NULL,
        sort_order INT DEFAULT 0,
        profile_id INT NOT NULL,
        created_at INT NOT NULL,
        updated_at INT NOT NULL,
        FOREIGN KEY(profile_id) REFERENCES profiles(id)
      )
    ''');

    await addColumnIfNotExists(db, 'products', 'category_id', 'TEXT NULL');
    await addColumnIfNotExists(db, 'products', 'last_used_at', 'INT NULL');
    await addColumnIfNotExists(
        db, 'products', 'calories_per_100g', 'REAL NULL');
    await addColumnIfNotExists(
        db, 'products', 'proteins_per_100g', 'REAL NULL');
    await addColumnIfNotExists(db, 'products', 'fats_per_100g', 'REAL NULL');
    await addColumnIfNotExists(db, 'products', 'carbs_per_100g', 'REAL NULL');

    await db.execute('''
      UPDATE products
      SET calories_per_100g = calorie_content,
          proteins_per_100g = proteins,
          fats_per_100g = fats,
          carbs_per_100g = carbohydrates
      WHERE calorie_content IS NOT NULL
        OR proteins IS NOT NULL
        OR fats IS NOT NULL
        OR carbohydrates IS NOT NULL
    ''');
  }
}
