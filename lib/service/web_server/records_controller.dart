import 'dart:io';

import 'package:cat_calories/features/calorie_tracking/domain/calorie_item_model.dart';
import 'package:cat_calories/features/calorie_tracking/calorie_item_repository.dart';
import 'package:cat_calories/service/profile_resolver.dart';
import 'package:cat_calories/service/web_server/controller.dart';
import 'package:cat_calories/service/web_server/router.dart';
import 'package:get_it/get_it.dart';

class RecordsController extends Controller {
  final _locator = GetIt.instance;

  /// Called after a write operation so the mobile UI can refresh.
  void Function()? onDataChanged;

  @override
  void register(Router router) {
    router.get('/api/records', _index);
    router.post('/api/records', _create);
    router.put('/api/records/:id', _update);
    router.delete('/api/records/:id', _destroy);
  }

  Future<void> _index(HttpRequest request, Map<String, String> params) async {
    final repo = _locator.get<CalorieItemRepository>();
    final profile = await ProfileResolver().resolve();
    final items = await repo.fetchAllByProfile(profile, orderBy: 'created_at DESC');

    final jsonItems = items.map((item) => _itemToJson(item)).toList();

    respondJson(request, HttpStatus.ok, {
      'profile': {
        'name': profile.name,
        'calories_limit_goal': profile.caloriesLimitGoal,
      },
      'records': jsonItems,
    });
  }

  Future<void> _create(HttpRequest request, Map<String, String> params) async {
    final repo = _locator.get<CalorieItemRepository>();
    final profile = await ProfileResolver().resolve();

    final data = await parseJsonBody(request);

    final value = (data['value'] as num?)?.toDouble();
    if (value == null) {
      respondJson(request, HttpStatus.badRequest, {'error': 'value is required'});
      return;
    }

    final now = DateTime.now();
    final item = CalorieItemModel(
      id: null,
      value: value,
      description: data['description'] as String?,
      sortOrder: 0,
      eatenAt: now,
      createdAt: now,
      profileId: profile.id!,
      wakingPeriodId: null,
      weightGrams: (data['weight_grams'] as num?)?.toDouble(),
      proteinGrams: (data['protein_grams'] as num?)?.toDouble(),
      fatGrams: (data['fat_grams'] as num?)?.toDouble(),
      carbGrams: (data['carb_grams'] as num?)?.toDouble(),
    );

    await repo.offsetSortOrder();
    final inserted = await repo.insert(item);
    onDataChanged?.call();

    respondJson(request, HttpStatus.created, {'record': _itemToJson(inserted)});
  }

  Future<void> _update(HttpRequest request, Map<String, String> params) async {
    final repo = _locator.get<CalorieItemRepository>();
    final id = params['id']!;
    final item = await repo.find(id);

    if (item == null) {
      respondJson(request, HttpStatus.notFound, {'error': 'Record not found'});
      return;
    }

    final data = await parseJsonBody(request);

    if (data.containsKey('value')) item.value = (data['value'] as num).toDouble();
    if (data.containsKey('description')) item.description = data['description'] as String?;
    if (data.containsKey('weight_grams')) item.weightGrams = (data['weight_grams'] as num?)?.toDouble();
    if (data.containsKey('protein_grams')) item.proteinGrams = (data['protein_grams'] as num?)?.toDouble();
    if (data.containsKey('fat_grams')) item.fatGrams = (data['fat_grams'] as num?)?.toDouble();
    if (data.containsKey('carb_grams')) item.carbGrams = (data['carb_grams'] as num?)?.toDouble();
    if (data.containsKey('eaten_at')) {
      final raw = data['eaten_at'] as String?;
      item.eatenAt = raw != null ? DateTime.parse(raw) : null;
    }
    if (data.containsKey('created_at')) {
      final raw = data['created_at'] as String?;
      if (raw != null) item.createdAt = DateTime.parse(raw);
    }

    item.updatedAt = DateTime.now();
    await repo.update(item);
    onDataChanged?.call();

    respondJson(request, HttpStatus.ok, {'record': _itemToJson(item)});
  }

  Future<void> _destroy(HttpRequest request, Map<String, String> params) async {
    final repo = _locator.get<CalorieItemRepository>();
    final id = params['id']!;
    final item = await repo.find(id);

    if (item == null) {
      respondJson(request, HttpStatus.notFound, {'error': 'Record not found'});
      return;
    }

    await repo.delete(item);
    onDataChanged?.call();

    respondJson(request, HttpStatus.ok, {'deleted': true});
  }

  Map<String, dynamic> _itemToJson(CalorieItemModel item) => {
    'id': item.id,
    'value': item.value,
    'description': item.description,
    'created_at': item.createdAt.toIso8601String(),
    'eaten_at': item.eatenAt?.toIso8601String(),
    'weight_grams': item.weightGrams,
    'protein_grams': item.proteinGrams,
    'fat_grams': item.fatGrams,
    'carb_grams': item.carbGrams,
  };
}
