import 'dart:convert';
import 'dart:io';

/// Per-file read offsets for [FileSyncTransport.pull].
///
/// MUST live in local app storage, never inside the synced folder — synced
/// cursors would make devices clobber each other's read positions.
abstract interface class FileCursorStore {
  Future<int> getOffset(String key);
  Future<void> setOffset(String key, int offset);
}

final class InMemoryCursorStore implements FileCursorStore {
  final Map<String, int> _offsets = {};

  @override
  Future<int> getOffset(String key) async => _offsets[key] ?? 0;

  @override
  Future<void> setOffset(String key, int offset) async {
    _offsets[key] = offset;
  }
}

/// Cursors persisted as a single local JSON file, written through on every
/// update. Losing this file is safe: pull restarts from offset 0 and the
/// idempotent LWW upsert drops the re-read entries.
final class JsonFileCursorStore implements FileCursorStore {
  final File file;
  Map<String, int>? _cache;

  JsonFileCursorStore(this.file);

  Future<Map<String, int>> _load() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    Map<String, int> loaded = {};
    if (await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          loaded = decoded.map((key, value) => MapEntry(key, value as int));
        }
      } on FormatException {
        // Corrupt cursor file → start over; correctness is unaffected.
      }
    }
    _cache = loaded;
    return loaded;
  }

  @override
  Future<int> getOffset(String key) async => (await _load())[key] ?? 0;

  @override
  Future<void> setOffset(String key, int offset) async {
    final offsets = await _load();
    offsets[key] = offset;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(offsets), flush: true);
  }
}
