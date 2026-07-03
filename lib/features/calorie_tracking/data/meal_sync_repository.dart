import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';

class MealSyncRepository extends SyncEntityRepository<Meal> {
  final MealRepositoryInterface _repo;

  MealSyncRepository(this._repo);

  @override
  Future<List<Meal>> findAllByScopes(Set<String> scopes) async {
    final all = await _repo.findAll();
    return all
        .where((meal) => meal.id != null && scopes.contains(meal.profileId))
        .toList();
  }

  @override
  Future<Meal?> findById(String id) => _repo.find(id);

  @override
  Future<void> upsert(Meal entity) async {
    final existing = await _repo.find(entity.id!);
    if (existing == null) {
      await _repo.insert(entity);
    } else {
      await _repo.update(entity);
    }
  }

  @override
  Future<void> deleteById(String id) async {
    final existing = await _repo.find(id);
    if (existing != null) {
      await _repo.delete(existing);
    }
  }
}
