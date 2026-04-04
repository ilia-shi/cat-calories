import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V002AddNutritionColumns extends Migration {
  @override
  int get version => 2;

  @override
  Future<void> up(Database db) async {
    await addColumnIfNotExists(db, 'calorie_items', 'weight_grams', 'REAL NULL');
    await addColumnIfNotExists(
        db, 'calorie_items', 'protein_grams', 'REAL NULL');
    await addColumnIfNotExists(db, 'calorie_items', 'fat_grams', 'REAL NULL');
    await addColumnIfNotExists(db, 'calorie_items', 'carb_grams', 'REAL NULL');
  }
}
