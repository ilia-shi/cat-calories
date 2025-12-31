final class CalorieItemModel {
  int? id;
  double value;
  String? description;
  int sortOrder;
  DateTime? eatenAt;
  DateTime createdAt;
  int profileId;
  int? wakingPeriodId;

  CalorieItemModel({
    required this.id,
    required this.value,
    required this.description,
    required this.sortOrder,
    required this.eatenAt,
    required this.createdAt,
    required this.profileId,
    required this.wakingPeriodId,
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
      };

  bool isEaten() {
    return eatenAt != null;
  }
}
