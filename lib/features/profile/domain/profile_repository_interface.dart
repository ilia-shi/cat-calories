import './profile_model.dart';

abstract interface class ProfileRepositoryInterface {
  Future<List<ProfileModel>> fetchAll();
  Future<ProfileModel> insert(ProfileModel profile);
  Future<int> delete(ProfileModel profile);
  Future<int> deleteAll();
  Future<ProfileModel> update(ProfileModel profile);
}
