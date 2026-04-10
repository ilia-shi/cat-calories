import 'dart:io';

import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/http/controller.dart';
import 'package:cat_calories_core/http/router.dart';
import 'package:uuid/uuid.dart';

import '../auth/auth_middleware.dart';
import '../data/sqlite/calorie_record_repository.dart';
import '../data/sqlite/profile_repository.dart';
import '../data/sqlite/sync_entry_repository.dart';

class RecordsHandler extends Controller {
  final ServerCalorieRecordRepository records;
  final ServerProfileRepository profiles;
  final SyncEntryRepository syncEntries;
  final UserExtractor userExtractor;

  RecordsHandler({
    required this.records,
    required this.profiles,
    required this.syncEntries,
    required this.userExtractor,
  });

  @override
  void register(Router router) {
    router.get('/api/records', _list);
    router.post('/api/records', _create);
    router.put('/api/records/:id', _update);
    router.delete('/api/records/:id', _delete);
  }

  Future<void> _list(HttpRequest request, Map<String, String> params) async {
    final userId = await requireAuth(request, userExtractor);
    if (userId == null) return;

    final profile = await profiles.getOrCreateForUser(userId);
    final allRecords = await records.fetchAllByProfile(
      profile,
      orderBy: 'created_at DESC',
    );

    respondJson(request, HttpStatus.ok, {
      'profile': {
        'name': profile.name,
        'calories_limit_goal': profile.caloriesLimitGoal,
      },
      'records': allRecords.map(_recordToJson).toList(),
    });
  }

  Future<void> _create(HttpRequest request, Map<String, String> params) async {
    final userId = await requireAuth(request, userExtractor);
    if (userId == null) return;

    final profile = await profiles.getOrCreateForUser(userId);
    final data = await parseJsonBody(request);
    final now = DateTime.now();

    DateTime? eatenAt;
    if (data['eaten_at'] != null) {
      eatenAt = DateTime.tryParse(data['eaten_at'] as String);
    }

    final record = CalorieRecord(
      id: const Uuid().v4(),
      value: (data['value'] as num).toDouble(),
      description: data['description'] as String?,
      sortOrder: 0,
      eatenAt: eatenAt,
      createdAt: now,
      profileId: profile.id!,
      wakingPeriodId: null,
      weightGrams: (data['weight_grams'] as num?)?.toDouble(),
      proteinGrams: (data['protein_grams'] as num?)?.toDouble(),
      fatGrams: (data['fat_grams'] as num?)?.toDouble(),
      carbGrams: (data['carb_grams'] as num?)?.toDouble(),
    );

    await records.insert(record);
    _writeSyncEntry(record, userId);
    respondJson(request, HttpStatus.ok, {'record': _recordToJson(record)});
  }

  Future<void> _update(HttpRequest request, Map<String, String> params) async {
    final userId = await requireAuth(request, userExtractor);
    if (userId == null) return;

    final id = params['id']!;
    final profile = await profiles.getOrCreateForUser(userId);

    final existing = await records.find(id);
    if (existing == null || existing.profileId != profile.id) {
      respondJson(request, HttpStatus.notFound, {'error': 'Not found'});
      return;
    }

    final data = await parseJsonBody(request);

    if (data.containsKey('value')) {
      existing.value = (data['value'] as num).toDouble();
    }
    if (data.containsKey('description')) {
      existing.description = data['description'] as String?;
    }
    if (data.containsKey('eaten_at')) {
      existing.eatenAt = data['eaten_at'] != null
          ? DateTime.tryParse(data['eaten_at'] as String)
          : null;
    }
    if (data.containsKey('created_at')) {
      final parsed = DateTime.tryParse(data['created_at'] as String);
      if (parsed != null) existing.createdAt = parsed;
    }
    if (data.containsKey('weight_grams')) {
      existing.weightGrams = (data['weight_grams'] as num?)?.toDouble();
    }
    if (data.containsKey('protein_grams')) {
      existing.proteinGrams = (data['protein_grams'] as num?)?.toDouble();
    }
    if (data.containsKey('fat_grams')) {
      existing.fatGrams = (data['fat_grams'] as num?)?.toDouble();
    }
    if (data.containsKey('carb_grams')) {
      existing.carbGrams = (data['carb_grams'] as num?)?.toDouble();
    }
    existing.updatedAt = DateTime.now();

    await records.update(existing);
    _writeSyncEntry(existing, userId);
    respondJson(request, HttpStatus.ok, {'record': _recordToJson(existing)});
  }

  Future<void> _delete(HttpRequest request, Map<String, String> params) async {
    final userId = await requireAuth(request, userExtractor);
    if (userId == null) return;

    final id = params['id']!;
    final profile = await profiles.getOrCreateForUser(userId);

    final existing = await records.find(id);
    if (existing == null || existing.profileId != profile.id) {
      respondJson(request, HttpStatus.notFound, {'error': 'Not found'});
      return;
    }

    await records.delete(existing);

    // Write a deletion sync entry
    final currentVersion =
        syncEntries.getCurrentVersion('calorie_item', id);
    syncEntries.upsert(
      entityType: 'calorie_item',
      entityId: id,
      scope: '',
      userId: userId,
      clientHlc: DateTime.now().toUtc().toIso8601String(),
      version: currentVersion + 1,
      isDeleted: true,
      payload: null,
    );

    respondJson(request, HttpStatus.ok, {'deleted': true});
  }

  /// Write a sync entry for a calorie record so the phone can pull it.
  /// Uses the phone's profile_id in the payload (not the server profile_id)
  /// so the phone recognizes the record when pulling.
  void _writeSyncEntry(CalorieRecord record, String userId) {
    final currentVersion =
        syncEntries.getCurrentVersion('calorie_item', record.id!);

    final payload = record.toJson();

    // Preserve the client's profile_id: check existing sync entry first,
    // then fall back to any known client profile_id for this user.
    final existing = syncEntries.findByEntityId('calorie_item', record.id!);
    if (existing?.payload != null && existing!.payload!['profile_id'] != null) {
      payload['profile_id'] = existing.payload!['profile_id'];
    } else {
      final clientProfileId = syncEntries.findClientProfileId(userId);
      if (clientProfileId != null) {
        payload['profile_id'] = clientProfileId;
      }
    }

    syncEntries.upsert(
      entityType: 'calorie_item',
      entityId: record.id!,
      scope: '',
      userId: userId,
      clientHlc: record.updatedAt.toUtc().toIso8601String(),
      version: currentVersion + 1,
      isDeleted: false,
      payload: payload,
    );
  }

  static Map<String, dynamic> _recordToJson(CalorieRecord r) => {
        'id': r.id,
        'value': r.value,
        'description': r.description,
        'created_at': r.createdAt.toUtc().toIso8601String(),
        'eaten_at': r.eatenAt?.toUtc().toIso8601String(),
        'weight_grams': r.weightGrams,
        'protein_grams': r.proteinGrams,
        'fat_grams': r.fatGrams,
        'carb_grams': r.carbGrams,
      };
}
