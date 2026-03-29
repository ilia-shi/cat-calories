import 'dart:convert';
import 'package:http/http.dart' as http;

class SyncConfigResponse {
  final String serverName;
  final String serverVersion;
  final int protocolVersion;
  final Map<String, dynamic> auth;
  final Map<String, dynamic> transports;

  const SyncConfigResponse({
    required this.serverName,
    required this.serverVersion,
    required this.protocolVersion,
    required this.auth,
    required this.transports,
  });

  factory SyncConfigResponse.fromJson(Map<String, dynamic> json) {
    return SyncConfigResponse(
      serverName: json['server_name'] ?? 'Unknown Server',
      serverVersion: json['server_version'] ?? '0.0.0',
      protocolVersion: json['protocol_version'] ?? 1,
      auth: (json['auth'] as Map<String, dynamic>?) ?? {},
      transports: (json['transports'] as Map<String, dynamic>?) ?? {},
    );
  }
}

String normalizeServerUrl(String input) {
  String url = input.trim();
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    // Use http for IP addresses (likely local/dev), https for hostnames
    final hostPart = url.split(':').first;
    final isIp = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(hostPart);
    final isLocalhost = hostPart == 'localhost' || hostPart.endsWith('.localhost');
    url = (isIp || isLocalhost) ? 'http://$url' : 'https://$url';
  }
  if (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}

Future<SyncConfigResponse> discoverServer(String serverUrl) async {
  final url = normalizeServerUrl(serverUrl);

  final response = await http
      .get(Uri.parse('$url/.well-known/sync-config'))
      .timeout(const Duration(seconds: 10));

  if (response.statusCode != 200) {
    throw Exception('Server returned status ${response.statusCode}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return SyncConfigResponse.fromJson(json);
}
