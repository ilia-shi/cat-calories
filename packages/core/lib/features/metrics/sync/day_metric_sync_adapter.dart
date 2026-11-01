import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';

final class DayMetricSyncAdapter extends SyncAdapter<DayMetricEntry> {
  @override
  String get entityType => 'day_metric';

  @override
  Map<String, dynamic> toSyncPayload(DayMetricEntry entry) => entry.toJson();

  @override
  DayMetricEntry fromSyncPayload(Map<String, dynamic> json) =>
      DayMetricEntry.fromJson(json);

  @override
  String extractIdentifier(DayMetricEntry entity) => entity.id;

  @override
  String extractScope(DayMetricEntry entity) => entity.profileId;

  @override
  DateTime extractUpdatedAt(DayMetricEntry entity) => entity.updatedAt;
}
