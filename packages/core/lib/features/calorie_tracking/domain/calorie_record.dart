import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';

final class CalorieRecord {
  String? id;
  double value;
  String? description;
  int sortOrder;
  DateTime? eatenAt;
  DateTime createdAt;
  DateTime updatedAt;
  String profileId;
  String? wakingPeriodId;
  double? weightGrams;
  double? proteinGrams;
  double? fatGrams;
  double? carbGrams;
  String? productId;

  /// Optional meal grouping — null means the record is ungrouped (always ok).
  String? mealId;

  /// Cost snapshotted at logging time from the product's then-current price —
  /// the product price may change later without corrupting history.
  double? costValue;
  String? costCurrency;

  /// True after the user edits the cost by hand; auto-recompute on
  /// weight/product change must not clobber a manual correction.
  bool costIsManual;

  /// Optional user color tag — null means unlabelled (always ok).
  ColorLabel? colorLabel;

  CalorieRecord({
    required this.id,
    required this.value,
    required this.description,
    required this.sortOrder,
    required this.eatenAt,
    required this.createdAt,
    DateTime? updatedAt,
    required this.profileId,
    required this.wakingPeriodId,
    this.weightGrams = null,
    this.proteinGrams = null,
    this.fatGrams = null,
    this.carbGrams = null,
    this.productId = null,
    this.mealId = null,
    this.costValue = null,
    this.costCurrency = null,
    this.costIsManual = false,
    this.colorLabel = null,
  }) : updatedAt = updatedAt ?? createdAt;

  factory CalorieRecord.fromJson(Map<String, dynamic> json) =>
      CalorieRecord(
        id: json['id'],
        value: json['value'],
        description: json['description'],
        sortOrder: json['sort_order'],
        eatenAt: json['eaten_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json['eaten_at']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
        updatedAt: json['updated_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'])
            : null,
        profileId: json['profile_id']?.toString() ?? '',
        wakingPeriodId: json['waking_period_id']?.toString(),

        weightGrams: json['weight_grams'] ?? null,
        proteinGrams: json['protein_grams'] ?? null,
        fatGrams: json['fat_grams'] ?? null,
        carbGrams: json['carb_grams'] ?? null,
        productId: json['product_id'] ?? null,
        mealId: json['meal_id']?.toString(),
        costValue: json['cost_value'] ?? null,
        costCurrency: json['cost_currency'] ?? null,
        // sqlite stores booleans as 0/1
        costIsManual: json['cost_is_manual'] == true ||
            json['cost_is_manual'] == 1,
        colorLabel: ColorLabel.tryParse(json['color_label']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'description': description,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'created_at_day':
            (DateTime(createdAt.year, createdAt.month, createdAt.day)
                        .millisecondsSinceEpoch /
                    100000)
                .round(),
        'eaten_at': eatenAt == null ? null : eatenAt!.millisecondsSinceEpoch,
        'sort_order': sortOrder,
        'profile_id': profileId,
        'waking_period_id': wakingPeriodId,

        'weight_grams': weightGrams,
        'protein_grams': proteinGrams,
        'fat_grams': fatGrams,
        'carb_grams': carbGrams,
        'product_id': productId,
        'meal_id': mealId,
        'cost_value': costValue,
        'cost_currency': costCurrency,
        'cost_is_manual': costIsManual ? 1 : 0,
        'color_label': colorLabel?.hex,
      };

  bool isEaten() {
    return eatenAt != null;
  }

  /// A fresh planned copy of this record ("cook it again"): no id yet, not
  /// eaten, detached from any waking period and meal — the caller assigns a
  /// new meal. Nutrition, weight, cost and the color label carry over as the
  /// starting point to tweak while cooking; cost is no longer a manual override
  /// because it no longer describes an actual past purchase.
  CalorieRecord copyForPlanning(DateTime createdAt) {
    return CalorieRecord(
      id: null,
      value: value,
      description: description,
      sortOrder: 0,
      eatenAt: null,
      createdAt: createdAt,
      profileId: profileId,
      wakingPeriodId: null,
      weightGrams: weightGrams,
      proteinGrams: proteinGrams,
      fatGrams: fatGrams,
      carbGrams: carbGrams,
      productId: productId,
      mealId: null,
      costValue: costValue,
      costCurrency: costCurrency,
      costIsManual: false,
      colorLabel: colorLabel,
    );
  }
}
