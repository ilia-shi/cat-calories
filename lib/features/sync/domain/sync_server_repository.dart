import 'package:cat_calories/features/sync/domain/sync_server.dart';

abstract class SyncServerRepositoryInterface {
  Future<SyncServer?> find(String id);
  Future<List<SyncServer>> findAll();
  Future<SyncServer> insert(SyncServer server);
  Future<SyncServer> update(SyncServer server);
  Future<int> delete(SyncServer server);
}
