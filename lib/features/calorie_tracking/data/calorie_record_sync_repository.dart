import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';

class CalorieRecordSyncRepository extends SyncEntityRepository<CalorieRecord> {
  final CalorieRecordRepositoryInterface _repo;

  CalorieRecordSyncRepository(this._repo);

  @override
  Future<List<CalorieRecord>> findAllByScopes(Set<String> scopes) async {
    final all = await _repo.findAll();
    return all
        .where((r) => r.id != null && scopes.contains(r.profileId))
        .toList();
  }

  @override
  Future<CalorieRecord?> findById(String id) => _repo.find(id);

  @override
  Future<void> upsert(CalorieRecord entity) async {
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
