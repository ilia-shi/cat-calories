import 'dart:convert';
import 'dart:io';

import 'package:cat_calories_core/http/router.dart';

abstract class Controller {
  void register(Router router);

  void respondJson(HttpRequest request, int statusCode, Map<String, dynamic> body) {
    _addCorsHeaders(request.response);
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body))
      ..close();
  }

  Future<Map<String, dynamic>> parseJsonBody(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  void _addCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
  }
}
