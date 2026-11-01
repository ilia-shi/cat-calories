import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_repository_interface.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';

class DayMetricSyncRepository extends SyncEntityRepository<DayMetricEntry> {
  final DayMetricRepositoryInterface _repo;

  DayMetricSyncRepository(this._repo);

  @override
  Future<List<DayMetricEntry>> findAllByScopes(Set<String> scopes) async {
    final all = await _repo.findAll();

    return all.where((entry) => scopes.contains(entry.profileId)).toList();
  }

  @override
  Future<DayMetricEntry?> findById(String id) => _repo.find(id);

  @override
  Future<void> upsert(DayMetricEntry entity) => _repo.save(entity);

  @override
  Future<void> deleteById(String id) => _repo.purge(id);
}
