import 'dart:convert';
import 'dart:io';

final class NdjsonReadResult {
  final List<Map<String, dynamic>> lines;

  /// Byte offset just past the last fully consumed line — the next cursor.
  final int endOffset;

  /// True when complete, unread lines remain past [endOffset] (a torn tail
  /// alone does not count: it may still be mid-write by Syncthing).
  final bool hasMore;

  const NdjsonReadResult({
    required this.lines,
    required this.endOffset,
    required this.hasMore,
  });
}

/// Append-only newline-delimited JSON file. Single writer per file (the
/// owning device); readers advance a byte cursor and never modify the file.
final class NdjsonLog {
  static Future<void> append(
      File file, List<Map<String, dynamic>> jsonLines) async {
    if (jsonLines.isEmpty) {
      return;
    }
    await file.parent.create(recursive: true);
    final sink = file.openWrite(mode: FileMode.append);
    for (final line in jsonLines) {
      sink.writeln(jsonEncode(line));
    }
    await sink.flush();
    await sink.close();
  }

  /// Reads up to [maxLines] complete lines starting at byte [fromOffset].
  ///
  /// - A trailing line without '\n' is a torn write — left unconsumed.
  /// - A malformed interior line (crash artifact) is skipped but consumed,
  ///   so it can never wedge the cursor.
  static Future<NdjsonReadResult> read(
    File file, {
    required int fromOffset,
    required int maxLines,
  }) async {
    if (!await file.exists()) {
      return NdjsonReadResult(
          lines: const [], endOffset: fromOffset, hasMore: false);
    }
    final bytes = await file.readAsBytes();
    // A shrunk file means it was replaced wholesale (not our writer) —
    // restart from the beginning rather than reading garbage.
    var position = fromOffset > bytes.length ? 0 : fromOffset;

    final lines = <Map<String, dynamic>>[];
    var consumedTo = position;
    while (position < bytes.length && lines.length < maxLines) {
      final newline = bytes.indexOf(0x0A, position);
      if (newline == -1) {
        break;
      }
      final raw = utf8.decode(bytes.sublist(position, newline),
          allowMalformed: true);
      position = newline + 1;
      consumedTo = position;
      if (raw.trim().isEmpty) {
        continue;
      }
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          lines.add(decoded);
        }
      } on FormatException {
        // Skip but keep the cursor moving.
      }
    }

    final hasMore = bytes.indexOf(0x0A, consumedTo) != -1;
    return NdjsonReadResult(
        lines: lines, endOffset: consumedTo, hasMore: hasMore);
  }
}
