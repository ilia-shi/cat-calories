import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/profile/domain/profile_repository_interface.dart';
import 'package:uuid/uuid.dart';

final class ProfileRepository implements ProfileRepositoryInterface {
  static const _uuid = Uuid();
  final DatabaseClient _db;

  ProfileRepository(this._db);

  Future<List<Profile>> fetchAll() async {
    final profilesResult = await _db.query('profiles');

    return profilesResult
        .map((element) => Profile.fromJson(element))
        .toList();
  }

  Future<Profile> insert(Profile profile) async {
    if (profile.id == null || profile.id!.isEmpty) {
      profile.id = _uuid.v4();
    }
    await _db.insert('profiles', profile.toJson());

    return profile;
  }

  Future<int> delete(Profile profile) async {
    return await _db
        .delete('profiles', where: 'id = ?', whereArgs: [profile.id]);
  }

  Future<int> deleteAll() async {
    return await _db.delete('profiles');
  }

  Future<Profile> update(Profile profile) async {
    await _db.update('profiles', profile.toJson(),
        where: 'id = ?', whereArgs: [profile.id]);

    return profile;
  }
}
