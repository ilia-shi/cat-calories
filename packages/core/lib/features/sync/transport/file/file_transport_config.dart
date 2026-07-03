import '../transport_config.dart';

final class FileTransportConfig implements TransportConfig {
  static const String transportType = 'file';

  /// The synced root (e.g. a Syncthing folder) holding `v1/logs/...`.
  final String rootPath;
  final String deviceId;

  const FileTransportConfig({
    required this.rootPath,
    required this.deviceId,
  });

  @override
  String get type => transportType;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'root_path': rootPath,
        'device_id': deviceId,
      };

  factory FileTransportConfig.fromJson(Map<String, dynamic> json) =>
      FileTransportConfig(
        rootPath: json['root_path'] as String,
        deviceId: json['device_id'] as String,
      );
}
