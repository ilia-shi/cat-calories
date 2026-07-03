import 'package:shared_preferences/shared_preferences.dart';

/// The one folder setting shared by the LLM export and file-based sync
/// (docs/plans/master_plan.md, "How the two halves fit together"): a synced
/// root (e.g. a Syncthing folder) that holds both the markdown export and
/// the v1/logs sync entries.
///
/// Lives in common/ so the calorie_tracking and sync features can share it
/// without importing each other. The prefs key predates file sync — it is
/// the original LLM-export directory, deliberately reused.
final class SyncedFolder {
  static const String pathKey = 'llm_export_directory';
  static const String fileSyncEnabledKey = 'file_sync_enabled';

  static Future<String?> getPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(pathKey);
    if (path == null || path.trim().isEmpty) {
      return null;
    }
    return path;
  }

  static Future<void> setPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.trim().isEmpty) {
      await prefs.remove(pathKey);
      return;
    }
    await prefs.setString(pathKey, path.trim());
  }

  static Future<bool> isFileSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(fileSyncEnabledKey) ?? false;
  }

  static Future<void> setFileSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(fileSyncEnabledKey, enabled);
  }
}
