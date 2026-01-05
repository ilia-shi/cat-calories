final class CalorieItemModel {
  int? id;
  double value;
  String? description;
  int sortOrder;
  DateTime? eatenAt;
  DateTime createdAt;
  int profileId;
  int? wakingPeriodId;

  // TODO: New fields
  double? weightGrams;
  double? proteinGrams;
  double? fatGrams;
  double? carbGrams;

  CalorieItemModel({
    required this.id,
    required this.value,
    required this.description,
    required this.sortOrder,
    required this.eatenAt,
    required this.createdAt,
    required this.profileId,
    required this.wakingPeriodId,

    this.weightGrams = null,
    this.proteinGrams = null,
    this.fatGrams = null,
    this.carbGrams = null,
  });

  factory CalorieItemModel.fromJson(Map<String, dynamic> json) =>
      CalorieItemModel(
        id: json['id'],
        value: json['value'],
        description: json['description'],
        sortOrder: json['sort_order'],
        eatenAt: json['eaten_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json['eaten_at']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
        profileId: json['profile_id'],
        wakingPeriodId: json['waking_period_id'],

        weightGrams: json['weight_grams'] ?? null,
        proteinGrams: json['protein_grams'] ?? null,
        fatGrams: json['fat_grams'] ?? null,
        carbGrams: json['carb_grams'] ?? null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'description': description,
        'created_at': createdAt.millisecondsSinceEpoch,
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
      };

  bool isEaten() {
    return eatenAt != null;
  }
}
