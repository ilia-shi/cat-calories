import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';

abstract interface class DayMetricRepositoryInterface {
  /// Includes soft-deleted entries, which sync must keep sending.
  Future<List<DayMetricEntry>> findAll();

  /// Excludes soft-deleted entries.
  Future<List<DayMetricEntry>> fetchByProfile(Profile profile);

  /// Includes soft-deleted entries.
  Future<DayMetricEntry?> find(String id);

  /// Inserts or overwrites by id and keeps the row's original `created_at`. An
  /// id is reused after clearing a value, so this also revives a deleted row.
  Future<void> save(DayMetricEntry entry);

  /// Marks [entry] as deleted and leaves the row for sync to carry.
  Future<void> delete(DayMetricEntry entry);

  /// Removes the row. Only for applying a deletion pulled from sync.
  Future<void> purge(String id);
}
