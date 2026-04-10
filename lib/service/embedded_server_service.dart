import 'dart:io';

import 'package:cat_calories/service/screen_energy_service.dart';
import 'package:cat_calories/service/embedded_server/home_controller.dart';
import 'package:cat_calories/service/embedded_server/records_controller.dart';
import 'package:cat_calories_core/http/router.dart';
import 'package:flutter/services.dart';

class EmbeddedServerService {
  static const int defaultPort = 18080;

  HttpServer? _server;
  String? _address;
  final ScreenEnergyService screenEnergy = ScreenEnergyService();
  final Router _router = Router();
  final RecordsController _recordsController = RecordsController();
  final HomeController _homeController = HomeController();

  /// Cached asset files loaded from the Flutter asset bundle.
  final Map<String, _CachedAsset> _assetCache = {};

  bool get isRunning => _server != null;
  String? get address => _address;

  /// Called after a write operation so the mobile UI can refresh.
  void Function()? get onDataChanged => _recordsController.onDataChanged;
  set onDataChanged(void Function()? callback) {
    _recordsController.onDataChanged = callback;
  }

  EmbeddedServerService() {
    _router.register(_recordsController);
    _router.register(_homeController);
  }

  Future<String> start({int port = defaultPort}) async {
    if (_server != null) {
      return _address!;
    }

    await _loadAssets();

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleRequest);

    final ip = await _getLocalIp();
    _address = '$ip:$port';

    await screenEnergy.start();

    return _address!;
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _address = null;

    await screenEnergy.stop();
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
    // Only write requests (POST/PUT/DELETE) from the web count as user activity
    if (request.method == 'POST' || request.method == 'PUT' || request.method == 'DELETE') {
      screenEnergy.onUserActivity();
    }

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
      final match = _router.resolve(request.method, path);

      if (match != null) {
        final (handler, params) = match;
        if (request.method == 'GET') screenEnergy.onClientPoll();
        await handler(request, params);
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
}

class _CachedAsset {
  final List<int> bytes;
  final ContentType contentType;

  _CachedAsset({required this.bytes, required this.contentType});
}
