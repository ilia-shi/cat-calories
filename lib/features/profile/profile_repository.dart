import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';

final class ProfileRepository {
  final DatabaseClient _db;

  ProfileRepository(this._db);

  Future<List<ProfileModel>> fetchAll() async {
    final profilesResult = await _db.query('profiles');

    return profilesResult
        .map((element) => ProfileModel.fromJson(element))
        .toList();
  }

  Future<ProfileModel> insert(ProfileModel profile) async {
    profile.id = await _db.insert('profiles', profile.toJson());

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
