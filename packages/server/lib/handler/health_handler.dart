import 'dart:io';
import 'package:cat_calories_core/http/controller.dart';
import 'package:cat_calories_core/http/router.dart';
import 'package:sqlite3/sqlite3.dart';

class HealthHandler extends Controller {
  final Database db;
  final String version;

  HealthHandler({required this.db, required this.version});

  @override
  void register(Router router) {
    router.get('/health', _health);
  }

  Future<void> _health(HttpRequest request, Map<String, String> params) async {
    bool dbOk = false;
    try {
      db.select('SELECT 1');
      dbOk = true;
    } catch (_) {}

    final status = dbOk ? HttpStatus.ok : HttpStatus.serviceUnavailable;
    respondJson(request, status, {
      'status': dbOk ? 'ok' : 'error',
      'database': dbOk,
      'version': version,
    });
  }
}
