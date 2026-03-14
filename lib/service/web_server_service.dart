import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/repositories/calorie_item_repository.dart';
import 'package:cat_calories/service/profile_resolver.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebServerService {
  static const int defaultPort = 18080;
  static const _wakelockChannel = MethodChannel('com.sywer.cat_calories/wakelock');
  static const String screenTimeoutKey = 'web_server_screen_timeout_minutes';
  static const int defaultTimeoutMinutes = 5;

  /// Available timeout options in minutes. 0 means never (always on).
  static const List<int> timeoutOptions = [0, 1, 2, 5, 10, 15, 30];

  HttpServer? _server;
  String? _address;
  final _locator = GetIt.instance;
  Timer? _inactivityTimer;
  bool _wakelockEnabled = false;

  /// Called after a write operation so the mobile UI can refresh.
  void Function()? onDataChanged;

  /// Cached asset files loaded from the Flutter asset bundle.
  final Map<String, _CachedAsset> _assetCache = {};

  bool get isRunning => _server != null;
  String? get address => _address;

  Future<String> start({int port = defaultPort}) async {
    if (_server != null) {
      return _address!;
    }

    await _loadAssets();

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleRequest);

    final ip = await _getLocalIp();
    _address = '$ip:$port';

    await _enableWakelock();
    _resetInactivityTimer();

    return _address!;
  }

  Future<void> stop() async {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    await _server?.close();
    _server = null;
    _address = null;

    await _disableWakelock();
  }

  Future<int> getTimeoutMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(screenTimeoutKey) ?? defaultTimeoutMinutes;
  }

  Future<void> setTimeoutMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(screenTimeoutKey, minutes);
    if (isRunning) _resetInactivityTimer();
  }

  void _resetInactivityTimer() async {
    _inactivityTimer?.cancel();
    final minutes = await getTimeoutMinutes();
    if (minutes == 0) return; // 0 = never turn off
    _inactivityTimer = Timer(Duration(minutes: minutes), () async {
      await _disableWakelock();
    });
  }

  Future<void> _enableWakelock() async {
    if (_wakelockEnabled) return;
    try {
      await _wakelockChannel.invokeMethod('enable');
      _wakelockEnabled = true;
    } catch (_) {}
  }

  Future<void> _disableWakelock() async {
    if (!_wakelockEnabled) return;
    try {
      await _wakelockChannel.invokeMethod('disable');
      _wakelockEnabled = false;
    } catch (_) {}
  }

  Future<void> _loadAssets() async {
    if (_assetCache.isNotEmpty) return;

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = manifest.listAssets();

    for (final assetKey in allAssets) {
      if (!assetKey.startsWith('web/dist/')) continue;

      // Map asset key to URL path: "web/dist/index.html" -> "/"
      // "web/dist/assets/index-HASH.js" -> "/assets/index-HASH.js"
      var urlPath = assetKey.substring('web/dist'.length);
      if (urlPath == '/index.html') urlPath = '/';

      final data = await rootBundle.load(assetKey);
      _assetCache[urlPath] = _CachedAsset(
        bytes: data.buffer.asUint8List(),
        contentType: _contentTypeForPath(assetKey),
      );
    }
  }

  ContentType _contentTypeForPath(String path) {
    if (path.endsWith('.html')) return ContentType.html;
    if (path.endsWith('.js')) return ContentType('application', 'javascript', charset: 'utf-8');
    if (path.endsWith('.css')) return ContentType('text', 'css', charset: 'utf-8');
    if (path.endsWith('.json')) return ContentType.json;
    if (path.endsWith('.svg')) return ContentType('image', 'svg+xml');
    if (path.endsWith('.png')) return ContentType('image', 'png');
    return ContentType.binary;
  }

  Future<String> _getLocalIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (!addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  Future<void> _handleRequest(HttpRequest request) async {
    _enableWakelock();
    _resetInactivityTimer();

    // Handle CORS preflight
    if (request.method == 'OPTIONS') {
      _addCorsHeaders(request.response);
      request.response
        ..statusCode = HttpStatus.ok
        ..close();
      return;
    }

    try {
      final path = request.uri.path;

      // Match /api/records/:id
      final recordMatch = RegExp(r'^/api/records/(\d+)$').firstMatch(path);

      if (path == '/api/records' && request.method == 'GET') {
        await _handleGetRecords(request);
      } else if (path == '/api/records' && request.method == 'POST') {
        await _handleCreateRecord(request);
      } else if (recordMatch != null && request.method == 'PUT') {
        final id = int.parse(recordMatch.group(1)!);
        await _handleUpdateRecord(request, id);
      } else if (recordMatch != null && request.method == 'DELETE') {
        final id = int.parse(recordMatch.group(1)!);
        await _handleDeleteRecord(request, id);
      } else {
        _handleStaticFile(request);
      }
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.text
        ..write('Error: $e')
        ..close();
    }
  }

  void _handleStaticFile(HttpRequest request) {
    final path = request.uri.path;

    // Try exact path, then fall back to index.html (SPA routing)
    final asset = _assetCache[path] ?? _assetCache['/'];

    if (asset != null) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = asset.contentType
        ..add(asset.bytes)
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not found')
        ..close();
    }
  }

  void _addCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
  }

  void _respondJson(HttpRequest request, int statusCode, Map<String, dynamic> body) {
    _addCorsHeaders(request.response);
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body))
      ..close();
  }

  Future<void> _handleGetRecords(HttpRequest request) async {
    final repo = _locator.get<CalorieItemRepository>();
    final profile = await ProfileResolver().resolve();
    final items = await repo.fetchAllByProfile(profile, orderBy: 'created_at DESC');

    final jsonItems = items.map((item) => _itemToJson(item)).toList();

    _respondJson(request, HttpStatus.ok, {
      'profile': {
        'name': profile.name,
        'calories_limit_goal': profile.caloriesLimitGoal,
      },
      'records': jsonItems,
    });
  }

  Future<void> _handleCreateRecord(HttpRequest request) async {
    final repo = _locator.get<CalorieItemRepository>();
    final profile = await ProfileResolver().resolve();

    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final value = (data['value'] as num?)?.toDouble();
    if (value == null) {
      _respondJson(request, HttpStatus.badRequest, {'error': 'value is required'});
      return;
    }

    final now = DateTime.now();
    final item = CalorieItemModel(
      id: null,
      value: value,
      description: data['description'] as String?,
      sortOrder: 0,
      eatenAt: now,
      createdAt: now,
      profileId: profile.id!,
      wakingPeriodId: null,
      weightGrams: (data['weight_grams'] as num?)?.toDouble(),
      proteinGrams: (data['protein_grams'] as num?)?.toDouble(),
      fatGrams: (data['fat_grams'] as num?)?.toDouble(),
      carbGrams: (data['carb_grams'] as num?)?.toDouble(),
    );

    await repo.offsetSortOrder();
    final inserted = await repo.insert(item);
    onDataChanged?.call();

    _respondJson(request, HttpStatus.created, {'record': _itemToJson(inserted)});
  }

  Future<void> _handleUpdateRecord(HttpRequest request, int id) async {
    final repo = _locator.get<CalorieItemRepository>();
    final item = await repo.find(id);

    if (item == null) {
      _respondJson(request, HttpStatus.notFound, {'error': 'Record not found'});
      return;
    }

    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data.containsKey('value')) item.value = (data['value'] as num).toDouble();
    if (data.containsKey('description')) item.description = data['description'] as String?;
    if (data.containsKey('weight_grams')) item.weightGrams = (data['weight_grams'] as num?)?.toDouble();
    if (data.containsKey('protein_grams')) item.proteinGrams = (data['protein_grams'] as num?)?.toDouble();
    if (data.containsKey('fat_grams')) item.fatGrams = (data['fat_grams'] as num?)?.toDouble();
    if (data.containsKey('carb_grams')) item.carbGrams = (data['carb_grams'] as num?)?.toDouble();

    await repo.update(item);
    onDataChanged?.call();

    _respondJson(request, HttpStatus.ok, {'record': _itemToJson(item)});
  }

  Future<void> _handleDeleteRecord(HttpRequest request, int id) async {
    final repo = _locator.get<CalorieItemRepository>();
    final item = await repo.find(id);

    if (item == null) {
      _respondJson(request, HttpStatus.notFound, {'error': 'Record not found'});
      return;
    }

    await repo.delete(item);
    onDataChanged?.call();

    _respondJson(request, HttpStatus.ok, {'deleted': true});
  }

  Map<String, dynamic> _itemToJson(CalorieItemModel item) => {
    'id': item.id,
    'value': item.value,
    'description': item.description,
    'created_at': item.createdAt.toIso8601String(),
    'eaten_at': item.eatenAt?.toIso8601String(),
    'weight_grams': item.weightGrams,
    'protein_grams': item.proteinGrams,
    'fat_grams': item.fatGrams,
    'carb_grams': item.carbGrams,
  };
}

class _CachedAsset {
  final List<int> bytes;
  final ContentType contentType;

  _CachedAsset({required this.bytes, required this.contentType});
}
