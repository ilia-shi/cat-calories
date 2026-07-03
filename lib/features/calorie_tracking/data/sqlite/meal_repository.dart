import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:uuid/uuid.dart';

class MealRepository implements MealRepositoryInterface {
  static const String tableName = 'meals';
  final DatabaseClient _db;

  MealRepository(this._db);

  @override
  Future<List<Meal>> findAll() async {
    final result = await _db.query(tableName, orderBy: 'created_at DESC');

    return result.map((element) => Meal.fromJson(element)).toList();
  }

  @override
  Future<List<Meal>> fetchByProfile(Profile profile) async {
    final result = await _db.query(tableName,
        where: 'profile_id = ?',
        whereArgs: [profile.id],
        orderBy: 'created_at DESC');

    return result.map((element) => Meal.fromJson(element)).toList();
  }

  @override
  Future<Meal?> find(String id) async {
    final result =
        await _db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isEmpty) {
      return null;
    }

    return Meal.fromJson(result.first);
  }

  @override
  Future<Meal> insert(Meal meal) async {
    meal.id ??= const Uuid().v4();
    await _db.insert(tableName, meal.toJson());

    return meal;
  }

  @override
  Future<Meal> update(Meal meal) async {
    await _db.update(tableName, meal.toJson(),
        where: 'id = ?', whereArgs: [meal.id]);

    return meal;
  }

  @override
  Future<int> delete(Meal meal) async {
    return await _db.delete(tableName, where: 'id = ?', whereArgs: [meal.id]);
  }
}
