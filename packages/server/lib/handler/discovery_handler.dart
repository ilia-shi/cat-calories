import 'dart:io';
import 'package:cat_calories_core/http/controller.dart';
import 'package:cat_calories_core/http/router.dart';
import '../config/config.dart';

class DiscoveryHandler extends Controller {
  final ServerConfig config;

  DiscoveryHandler({required this.config});

  @override
  void register(Router router) {
    router.get('/.well-known/sync-config', _syncConfig);
  }

  Future<void> _syncConfig(HttpRequest request, Map<String, String> params) async {
    final auth = <String, dynamic>{
      'type': config.hasOAuth ? 'oauth' : 'token',
    };

    if (config.hasOAuth) {
      auth['issuer'] = config.oauthEndpoint;
      auth['auth_url'] = '${config.oauthEndpoint}/login/oauth/authorize';
      auth['token_url'] = '${config.oauthEndpoint}/api/login/oauth/access_token';
      auth['client_id'] = config.oauthClientId;
    }

    respondJson(request, HttpStatus.ok, {
      'server_name': config.serverName,
      'server_version': config.serverVersion,
      'protocol_version': 2,
      'auth': auth,
      'transports': {
        'rest': {
          'base_url': config.serverBaseUrl,
        },
      },
    });
  }
}
