import './scoped_server_link.dart';

abstract class ScopedServerLinkRepositoryInterface {
  Future<ScopedServerLink?> find(String id);
  Future<List<ScopedServerLink>> findAll();
  Future<List<ScopedServerLink>> findByServer(String serverId);
  Future<List<ScopedServerLink>> findByScope(String scope);
  Future<ScopedServerLink> insert(ScopedServerLink link);
  Future<int> delete(ScopedServerLink link);
}
