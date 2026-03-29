import '../transport_config.dart';

final class RestTransportConfig extends TransportConfig {
  final String baseUrl;
  final Duration timeout;
  final bool compressBody;

  RestTransportConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.compressBody = false,
  });

  factory RestTransportConfig.fromJson(Map<String, dynamic> json) {
    return RestTransportConfig(
      baseUrl: json['base_url'] ?? '',
      timeout: Duration(milliseconds: json['timeout_ms'] ?? 30000),
      compressBody: json['compress_body'] ?? false,
    );
  }

  @override
  String get type => 'rest';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'base_url': baseUrl,
        'timeout_ms': timeout.inMilliseconds,
        'compress_body': compressBody,
      };
}
