import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:uuid/uuid.dart';

class TrackingGapRepository implements TrackingGapRepositoryInterface {
  static const String tableName = 'tracking_gaps';
  final DatabaseClient _db;

  TrackingGapRepository(this._db);

  @override
  Future<List<TrackingGap>> findAll() async {
    final result = await _db.query(tableName, orderBy: 'started_at DESC');

    return result.map(TrackingGap.fromJson).toList();
  }

  @override
  Future<List<TrackingGap>> fetchByProfile(Profile profile) async {
    final result = await _db.query(tableName,
        where: 'profile_id = ? AND deleted_at IS NULL',
        whereArgs: [profile.id],
        orderBy: 'started_at DESC');

    return result.map(TrackingGap.fromJson).toList();
  }

  @override
  Future<TrackingGap?> find(String id) async {
    final result =
        await _db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isEmpty) {
      return null;
    }

    return TrackingGap.fromJson(result.first);
  }

  @override
  Future<TrackingGap> insert(TrackingGap gap) async {
    gap.id ??= const Uuid().v4();
    await _db.insert(tableName, gap.toJson());

    return gap;
  }

  @override
  Future<TrackingGap> update(TrackingGap gap) async {
    await _db.update(tableName, gap.toJson(),
        where: 'id = ?', whereArgs: [gap.id]);

    return gap;
  }

  @override
  Future<TrackingGap> delete(TrackingGap gap) {
    final now = DateTime.now();

    return update(gap
      ..deletedAt = now
      ..updatedAt = now);
  }

  @override
  Future<void> purge(String id) async {
    await _db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
