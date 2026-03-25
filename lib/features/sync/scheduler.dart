import 'package:cat_calories/features/sync/transport/sync_transport.dart';

class SyncScheduler {
  final SyncEngine _engine;

  // Timer? _periodicTimer;
  // StreamSubscription? _connectivitySub;

  SyncScheduler(this._engine);

  /// Запустить периодическую синхронизацию
  void startPeriodic(Duration interval) {
    // _periodicTimer?.cancel();
    // _periodicTimer = Timer.periodic(interval, (_) => _engine.syncAll());
  }

  /// Вызвать вручную (кнопка Sync)
  Future<List<SyncSessionResult>> syncNow() => _engine.syncAll();

  /// Подписаться на изменения connectivity
  void watchConnectivity() {
    // _connectivitySub = Connectivity()
    //     .onConnectivityChanged
    //     .where((status) => status != ConnectivityResult.none)
    //     .listen((_) => _engine.syncAll());
  }

  void dispose() {
    // _periodicTimer?.cancel();
    // _connectivitySub?.cancel();
  }
}