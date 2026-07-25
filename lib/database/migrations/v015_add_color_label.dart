import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

/// Optional color tag on a calorie item, stored as a `#RRGGBB` string
/// (see ColorLabel in cat_calories_core). Nullable — unlabelled is the norm.
class V015AddColorLabel extends Migration {
  @override
  int get version => 15;

  @override
  Future<void> up(Database db) async {
    await addColumnIfNotExists(db, 'calorie_items', 'color_label', 'TEXT NULL');
  }
}
