import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:uuid/uuid.dart';

final class ProfileRepository {
  static const _uuid = Uuid();
  final DatabaseClient _db;

  ProfileRepository(this._db);

  Future<List<ProfileModel>> fetchAll() async {
    final profilesResult = await _db.query('profiles');

    return profilesResult
        .map((element) => ProfileModel.fromJson(element))
        .toList();
  }

  Future<ProfileModel> insert(ProfileModel profile) async {
    if (profile.id == null || profile.id!.isEmpty) {
      profile.id = _uuid.v4();
    }
    await _db.insert('profiles', profile.toJson());

    return profile;
  }

  Future<int> delete(ProfileModel profile) async {
    return await _db
        .delete('profiles', where: 'id = ?', whereArgs: [profile.id]);
  }

  Future<int> deleteAll() async {
    return await _db.delete('profiles');
  }

  Future<ProfileModel> update(ProfileModel profile) async {
    await _db.update('profiles', profile.toJson(),
        where: 'id = ?', whereArgs: [profile.id]);

    return profile;
  }
}
