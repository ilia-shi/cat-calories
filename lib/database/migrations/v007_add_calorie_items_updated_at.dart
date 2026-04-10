import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V007AddCalorieItemsUpdatedAt extends Migration {
  @override
  int get version => 7;

  @override
  Future<void> up(Database db) async {
    await addColumnIfNotExists(db, 'calorie_items', 'updated_at', 'INT');
    await db.execute(
        'UPDATE calorie_items SET updated_at = created_at WHERE updated_at IS NULL');
  }
}
