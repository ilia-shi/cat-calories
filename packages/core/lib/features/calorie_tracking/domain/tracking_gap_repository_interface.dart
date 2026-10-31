import 'package:cat_calories_core/features/profile/domain/profile.dart';

import './tracking_gap.dart';

abstract interface class TrackingGapRepositoryInterface {
  /// Includes soft-deleted gaps, which sync must keep sending.
  Future<List<TrackingGap>> findAll();

  /// Excludes soft-deleted gaps; newest first.
  Future<List<TrackingGap>> fetchByProfile(Profile profile);

  /// Includes soft-deleted gaps.
  Future<TrackingGap?> find(String id);
  Future<TrackingGap> insert(TrackingGap gap);
  Future<TrackingGap> update(TrackingGap gap);

  /// Marks [gap] as deleted and leaves the row for sync to carry.
  Future<TrackingGap> delete(TrackingGap gap);

  /// Removes the row. Only for applying a deletion pulled from sync.
  Future<void> purge(String id);
}
