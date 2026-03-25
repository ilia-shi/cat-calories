import 'package:cat_calories/features/calorie_tracking/domain/calorie_record.dart';
import '../../../sync/sync_adapter.dart';

final class CalorieRecordSyncAdapter extends SyncAdapter<CalorieRecord> {
  @override
  String get entityType => 'calorie_item';

  @override
  Map<String, dynamic> toSyncPayload(CalorieRecord entry) => entry.toJson();

  @override
  CalorieRecord fromSyncPayload(Map<String, dynamic> json) =>
      CalorieRecord.fromJson(json);

  String extractIdentifier(CalorieRecord entity) {
    if (null == entity.id) {
      throw Exception('No entity ID');
    }

    return entity.id ?? '';
  }

  @override
  String extractScope(CalorieRecord entity) {
    return entity.profileId;
  }
}
