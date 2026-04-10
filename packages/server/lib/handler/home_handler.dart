import 'dart:io';

import 'package:cat_calories_core/http/controller.dart';
import 'package:cat_calories_core/http/router.dart';
import 'package:sqlite3/sqlite3.dart';

import '../auth/auth_middleware.dart';
import '../data/sqlite/profile_repository.dart';

class HomeHandler extends Controller {
  final Database db;
  final ServerProfileRepository profiles;
  final UserExtractor userExtractor;

  HomeHandler({
    required this.db,
    required this.profiles,
    required this.userExtractor,
  });

  @override
  void register(Router router) {
    router.get('/api/home', _home);
  }

  Future<void> _home(HttpRequest request, Map<String, String> params) async {
    final userId = await requireAuth(request, userExtractor);
    if (userId == null) return;

    final profile = await profiles.getOrCreateForUser(userId);
    final profileId = profile.id!;
    final now = DateTime.now();

    // Rolling 24h
    final ms24hAgo =
        now.subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
    final rolling24h = _sumWhere(profileId, 'COALESCE(eaten_at, created_at) >= ?', [ms24hAgo]);

    // Today
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayMs = todayStart.millisecondsSinceEpoch;
    final todaySum = _sumWhere(profileId, 'COALESCE(eaten_at, created_at) >= ?', [todayMs]);

    // Yesterday
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayMs = yesterdayStart.millisecondsSinceEpoch;
    final yesterdaySum = _sumWhere(
      profileId,
      'COALESCE(eaten_at, created_at) >= ? AND COALESCE(eaten_at, created_at) < ?',
      [yesterdayMs, todayMs],
    );

    // Average over last 7 days
    final ms7dAgo =
        todayStart.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final sum7d = _sumWhere(profileId, 'COALESCE(eaten_at, created_at) >= ?', [ms7dAgo]);
    final avg7d = sum7d / 7.0;

    // Current waking period (open period with no ended_at)
    Map<String, dynamic>? period;
    final wpResult = db.select(
      'SELECT started_at, calories_limit_goal FROM waking_periods '
      'WHERE profile_id = ? AND ended_at IS NULL '
      'ORDER BY started_at DESC LIMIT 1',
      [profileId],
    );
    if (wpResult.isNotEmpty) {
      final wp = wpResult.first;
      final wpStartedAt = wp['started_at'] as int;
      final wpGoal = (wp['calories_limit_goal'] as num).toDouble();
      final wpCalories = _sumWhere(
        profileId,
        'COALESCE(eaten_at, created_at) >= ?',
        [wpStartedAt],
      );
      period = {'calories': wpCalories, 'goal': wpGoal};
    }

    // Recent meals (last 10)
    final recentResult = db.select(
      'SELECT id, value, description, COALESCE(eaten_at, created_at) AS meal_time '
      'FROM calorie_items WHERE profile_id = ? '
      'ORDER BY COALESCE(eaten_at, created_at) DESC LIMIT 10',
      [profileId],
    );
    final recentMeals = recentResult
        .map((row) => {
              'id': row['id'] as String,
              'value': (row['value'] as num).toDouble(),
              'description': row['description'],
              'eaten_at': DateTime.fromMillisecondsSinceEpoch(
                      row['meal_time'] as int)
                  .toUtc()
                  .toIso8601String(),
            })
        .toList();

    respondJson(request, HttpStatus.ok, {
      'profile': {
        'name': profile.name,
        'calories_limit_goal': profile.caloriesLimitGoal,
      },
      'rolling_24h': rolling24h,
      'today': todaySum,
      'yesterday': yesterdaySum,
      'avg_7_days': avg7d,
      'period': period,
      'recent_meals': recentMeals,
    });
  }

  double _sumWhere(String profileId, String where, List<Object?> args) {
    final result = db.select(
      'SELECT COALESCE(SUM(value), 0) AS total '
      'FROM calorie_items WHERE profile_id = ? AND $where',
      [profileId, ...args],
    );
    return (result.first['total'] as num).toDouble();
  }
}
