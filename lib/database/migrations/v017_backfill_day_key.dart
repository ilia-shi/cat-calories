import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

/// Increment 4 of the "planning a meal for a specific day" plan: `created_at_day`
/// now holds the day a record *belongs to* — eaten, else planned, else entered —
/// so every day query agrees with the history screen. Rows written under the old
/// rule still hold the day they were created, so recompute them here.
///
/// Only rows with an `eaten_at` or a `planned_for` can differ, and most of those
/// were eaten the moment they were entered, so the update touches few rows. The
/// key is recomputed in Dart rather than SQL because the stored value is local
/// midnight in milliseconds, and SQLite's date functions would have to be
/// talked into the device's timezone to reproduce it exactly.
class V017BackfillDayKey extends Migration {
  @override
  int get version => 17;

  @override
  Future<void> up(Database db) async {
    final rows = await db.query(
      'calorie_items',
      columns: ['id', 'eaten_at', 'planned_for', 'created_at', 'created_at_day'],
      where: 'eaten_at IS NOT NULL OR planned_for IS NOT NULL',
    );

    final batch = db.batch();
    var changed = 0;
    for (final row in rows) {
      final anchorMs =
          (row['eaten_at'] ?? row['planned_for'] ?? row['created_at']) as int?;
      if (anchorMs == null) {
        continue;
      }
      final anchor = DateTime.fromMillisecondsSinceEpoch(anchorMs);
      final dayKey =
          (DateTime(anchor.year, anchor.month, anchor.day).millisecondsSinceEpoch /
                  100000)
              .round();
      if (dayKey == row['created_at_day']) {
        continue;
      }
      batch.update(
        'calorie_items',
        {'created_at_day': dayKey},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      changed++;
    }

    if (changed > 0) {
      await batch.commit(noResult: true);
    }
  }
}
