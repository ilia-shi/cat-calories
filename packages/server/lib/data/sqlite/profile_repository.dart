import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/profile/domain/profile_repository_interface.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

class ServerProfileRepository implements ProfileRepositoryInterface {
  final Database _db;

  ServerProfileRepository(this._db);

  @override
  Future<List<Profile>> fetchAll() async {
    final result = _db.select('SELECT * FROM profiles ORDER BY created_at ASC');
    return result.map(_rowToProfile).toList();
  }

  Future<List<Profile>> fetchByUser(String userId) async {
    final result = _db.select(
      'SELECT * FROM profiles WHERE user_id = ? ORDER BY created_at ASC',
      [userId],
    );
    return result.map(_rowToProfile).toList();
  }

  Future<Profile?> findById(String id) async {
    final result = _db.select('SELECT * FROM profiles WHERE id = ?', [id]);
    if (result.isEmpty) return null;
    return _rowToProfile(result.first);
  }

  @override
  Future<Profile> insert(Profile profile) async {
    profile.id ??= const Uuid().v4();
    final json = profile.toJson();
    _db.execute(
      'INSERT INTO profiles (id, user_id, name, waking_time_seconds, calories_limit_goal, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [json['id'], '', json['name'], json['waking_time_seconds'], json['calories_limit_goal'], json['created_at'], json['updated_at']],
    );
    return profile;
  }

  /// Insert a profile linked to a specific user.
  Future<Profile> insertForUser(Profile profile, String userId) async {
    profile.id ??= const Uuid().v4();
    final json = profile.toJson();
    _db.execute(
      'INSERT INTO profiles (id, user_id, name, waking_time_seconds, calories_limit_goal, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [json['id'], userId, json['name'], json['waking_time_seconds'], json['calories_limit_goal'], json['created_at'], json['updated_at']],
    );
    return profile;
  }

  @override
  Future<Profile> update(Profile profile) async {
    final json = profile.toJson();
    _db.execute(
      'UPDATE profiles SET name = ?, waking_time_seconds = ?, calories_limit_goal = ?, updated_at = ? WHERE id = ?',
      [json['name'], json['waking_time_seconds'], json['calories_limit_goal'], json['updated_at'], json['id']],
    );
    return profile;
  }

  @override
  Future<int> delete(Profile profile) async {
    _db.execute('DELETE FROM profiles WHERE id = ?', [profile.id]);
    return 1;
  }

  @override
  Future<int> deleteAll() async {
    _db.execute('DELETE FROM profiles');
    return _db.updatedRows;
  }

  Profile _rowToProfile(Row row) {
    return Profile(
      id: row['id']?.toString(),
      name: row['name'] as String,
      wakingTimeSeconds: row['waking_time_seconds'] as int,
      caloriesLimitGoal: (row['calories_limit_goal'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
