import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

/// Stable per-device id that names this device's log files forever.
///
/// The id itself lives in [localFile] (app-support dir, never synced); a
/// descriptive `meta/device-<id>.json` is dropped into the synced root so
/// other devices and humans can tell the logs apart.
final class DeviceIdentity {
  static const int formatVersion = 1;

  static Future<String> ensure({
    required File localFile,
    required Directory syncRoot,
    String? displayName,
  }) async {
    String? deviceId;
    if (await localFile.exists()) {
      final content = (await localFile.readAsString()).trim();
      if (content.isNotEmpty) {
        deviceId = content;
      }
    }
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await localFile.parent.create(recursive: true);
      await localFile.writeAsString(deviceId, flush: true);
    }

    final metaFile =
        File('${syncRoot.path}/v1/meta/device-$deviceId.json');
    if (!await metaFile.exists()) {
      await metaFile.parent.create(recursive: true);
      await metaFile.writeAsString(
        jsonEncode({
          'device_id': deviceId,
          'display_name': displayName ?? Platform.localHostname,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'format_version': formatVersion,
        }),
        flush: true,
      );
    }

    return deviceId;
  }
}
