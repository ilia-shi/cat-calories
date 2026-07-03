import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

/// Increment C of docs/plans/master_plan.md: meal grouping. A meal groups
/// calorie records (ingredients) and carries LLM context (notes, cook time,
/// ratings). meal_id on calorie_items is nullable — grouping is optional.
class V014AddMeals extends Migration {
  @override
  int get version => 14;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE meals(
        id TEXT PRIMARY KEY NOT NULL,
        profile_id TEXT NOT NULL,
        title TEXT NOT NULL,
        notes TEXT NULL,
        created_at INT NOT NULL,
        updated_at INT NOT NULL,
        eaten_at INT NULL,
        cooking_minutes INT NULL,
        taste_rating INT NULL,
        satiety_rating INT NULL,
        total_cooked_weight_grams REAL NULL,
        FOREIGN KEY(profile_id) REFERENCES profiles(id)
      )
    ''');

    await addColumnIfNotExists(db, 'calorie_items', 'meal_id', 'TEXT NULL');
    await db.execute(
        'CREATE INDEX calorie_items_meal_id_idx ON calorie_items(meal_id)');
  }
}
