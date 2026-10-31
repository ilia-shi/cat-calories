import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';

final class TrackingGapSyncAdapter extends SyncAdapter<TrackingGap> {
  @override
  String get entityType => 'tracking_gap';

  @override
  Map<String, dynamic> toSyncPayload(TrackingGap entry) => entry.toJson();

  @override
  TrackingGap fromSyncPayload(Map<String, dynamic> json) =>
      TrackingGap.fromJson(json);

  @override
  String extractIdentifier(TrackingGap entity) {
    final id = entity.id;
    if (id == null) {
      throw Exception('No entity ID');
    }

    return id;
  }

  @override
  String extractScope(TrackingGap entity) => entity.profileId;

  @override
  DateTime extractUpdatedAt(TrackingGap entity) => entity.updatedAt;
}
