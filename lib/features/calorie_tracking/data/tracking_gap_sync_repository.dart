import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap_repository_interface.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';

class TrackingGapSyncRepository extends SyncEntityRepository<TrackingGap> {
  final TrackingGapRepositoryInterface _repo;

  TrackingGapSyncRepository(this._repo);

  @override
  Future<List<TrackingGap>> findAllByScopes(Set<String> scopes) async {
    final all = await _repo.findAll();

    return all
        .where((gap) => gap.id != null && scopes.contains(gap.profileId))
        .toList();
  }

  @override
  Future<TrackingGap?> findById(String id) => _repo.find(id);

  @override
  Future<void> upsert(TrackingGap entity) async {
    final existing = await _repo.find(entity.id!);
    if (existing == null) {
      await _repo.insert(entity);
    } else {
      await _repo.update(entity);
    }
  }

  @override
  Future<void> deleteById(String id) => _repo.purge(id);
}
