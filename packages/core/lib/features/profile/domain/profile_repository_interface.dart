import './profile.dart';

abstract interface class ProfileRepositoryInterface {
  Future<List<Profile>> fetchAll();
  Future<Profile> insert(Profile profile);
  Future<int> delete(Profile profile);
  Future<int> deleteAll();
  Future<Profile> update(Profile profile);
}
