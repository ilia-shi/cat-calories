import 'dart:io';

import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/common/synced_folder.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/llm_export_formatter.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';
import 'package:cat_calories_core/features/products/domain/product_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings and file output for the LLM markdown export (master plan
/// increment A): a user-chosen export directory (typically a folder synced by
/// Syncthing), an auto-export-on-background toggle, and an editable preamble.
///
/// Every setting is optional — with nothing configured the export is only
/// available through the share sheet.
final class LlmExportService {
  /// Stable name so repeated exports overwrite one file instead of piling up
  /// timestamped copies in the synced folder.
  static const String exportFileName = 'cat_calories_llm_log.md';

  static const String _autoExportKey = 'llm_export_auto_enabled';
  static const String _preambleKey = 'llm_export_preamble';

  final CalorieRecordRepositoryInterface _records;
  final ProductRepositoryInterface _products;
  final MealRepositoryInterface _meals;

  LlmExportService(this._records, this._products, this._meals);

  /// The export directory is the shared synced root — the same folder file
  /// sync uses (see SyncedFolder).
  Future<String?> getDirectory() => SyncedFolder.getPath();

  Future<void> setDirectory(String? path) => SyncedFolder.setPath(path);

  Future<bool> isAutoExportEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoExportKey) ?? false;
  }

  Future<void> setAutoExportEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoExportKey, enabled);
  }

  /// Returns null when the user has not customized the preamble; callers pass
  /// null through to [LlmExportFormatter] which falls back to its default.
  Future<String?> getPreamble() async {
    final prefs = await SharedPreferences.getInstance();
    final preamble = prefs.getString(_preambleKey);
    if (preamble == null || preamble.trim().isEmpty) {
      return null;
    }
    return preamble;
  }

  Future<void> setPreamble(String? preamble) async {
    final prefs = await SharedPreferences.getInstance();
    if (preamble == null || preamble.trim().isEmpty) {
      await prefs.remove(_preambleKey);
      return;
    }
    await prefs.setString(_preambleKey, preamble);
  }

  /// Probe-writes into [path]; returns an error message, or null when the
  /// directory is writable.
  Future<String?> testDirectory(String path) async {
    try {
      final directory = Directory(path.trim());
      if (!await directory.exists()) {
        return 'Directory does not exist';
      }
      final probe = File('${directory.path}/.cat_calories_write_test');
      await probe.writeAsString('ok');
      await probe.delete();
      return null;
    } catch (e) {
      return 'Not writable: $e';
    }
  }

  Future<String> buildMarkdown(Profile profile) async {
    final records = await _records.fetchAllByProfile(profile);
    final products = await _products.fetchByProfile(profile);
    final meals = await _meals.fetchByProfile(profile);
    final preamble = await getPreamble();

    return const LlmExportFormatter().format(
      profile: profile,
      records: records,
      products: products,
      meals: meals,
      preamble: preamble,
    );
  }

  /// Writes already-formatted markdown into the configured directory.
  /// Returns the written file path, or null when no directory is configured.
  Future<String?> writeToDirectory(String markdown) async {
    final directory = await getDirectory();
    if (directory == null) {
      return null;
    }

    final filePath = '$directory/$exportFileName';
    await File(filePath).writeAsString(markdown);

    return filePath;
  }

  /// Builds and writes the log into the configured directory. Returns the
  /// written file path, or null when no directory is configured.
  Future<String?> exportToDirectory(Profile profile) async {
    if (await getDirectory() == null) {
      return null;
    }
    return writeToDirectory(await buildMarkdown(profile));
  }

  /// Lifecycle hook (app goes to background). Never throws: auto-export is
  /// best-effort and must not disturb the app shutting down.
  Future<void> autoExportIfEnabled() async {
    try {
      if (!await isAutoExportEnabled()) {
        return;
      }
      final profile = await ProfileResolver().resolve();
      await exportToDirectory(profile);
    } catch (e) {
      print('LLM auto-export failed: $e');
    }
  }
}
