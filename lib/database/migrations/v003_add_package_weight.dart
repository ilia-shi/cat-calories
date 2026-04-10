import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V003AddPackageWeight extends Migration {
  @override
  int get version => 3;

  @override
  Future<void> up(Database db) async {
    await addColumnIfNotExists(
        db, 'products', 'package_weight_grams', 'REAL NULL');
  }
}
