import 'dart:io';

import 'package:cat_calories/service/web_server/controller.dart';

typedef RouteHandler = Future<void> Function(HttpRequest request, Map<String, String> params);

class Route {
  final String method;
  final RegExp _regex;
  final List<String> _paramNames;
  final RouteHandler handler;

  Route._(this.method, this._regex, this._paramNames, this.handler);

  factory Route(String method, String pattern, RouteHandler handler) {
    final paramNames = <String>[];
    final regexPattern = pattern.replaceAllMapped(RegExp(r':(\w+)'), (match) {
      paramNames.add(match.group(1)!);
      return r'([a-zA-Z0-9_-]+)';
    });
    final regex = RegExp('^$regexPattern\$');
    return Route._(method, regex, paramNames, handler);
  }

  Map<String, String>? match(String method, String path) {
    if (this.method != method) return null;
    final m = _regex.firstMatch(path);
    if (m == null) return null;

    final params = <String, String>{};
    for (var i = 0; i < _paramNames.length; i++) {
      params[_paramNames[i]] = m.group(i + 1)!;
    }
    return params;
  }
}

class Router {
  final List<Route> _routes = [];

  void get(String pattern, RouteHandler handler) =>
      _routes.add(Route('GET', pattern, handler));

  void post(String pattern, RouteHandler handler) =>
      _routes.add(Route('POST', pattern, handler));

  void put(String pattern, RouteHandler handler) =>
      _routes.add(Route('PUT', pattern, handler));

  void delete(String pattern, RouteHandler handler) =>
      _routes.add(Route('DELETE', pattern, handler));

  void register(Controller controller) {
    controller.register(this);
  }

  /// Returns the matched handler and params, or null if no route matches.
  (RouteHandler handler, Map<String, String> params)? resolve(String method, String path) {
    for (final route in _routes) {
      final params = route.match(method, path);
      if (params != null) return (route.handler, params);
    }
    return null;
  }
}
