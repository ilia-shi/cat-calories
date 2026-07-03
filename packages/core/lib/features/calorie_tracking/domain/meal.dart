/// A group of calorie records (ingredients) eaten together, carrying the
/// context an LLM needs: title, notes, cook time, taste/satiety ratings.
///
/// Grouping is always optional — records without a meal stay first-class.
/// A meal whose records all have `eatenAt == null` is planned, not eaten;
/// `eatenAt` here mirrors the moment the meal was marked eaten.
final class Meal {
  String? id;
  String profileId;
  String title;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? eatenAt;

  /// Signal fields (increment E fills their UI; nullable from day one).
  int? cookingMinutes;
  int? tasteRating;
  int? satietyRating;

  /// Total cooked dish weight — enables "save meal as product" (per-100g).
  double? totalCookedWeightGrams;

  Meal({
    required this.id,
    required this.profileId,
    required this.title,
    this.notes,
    required this.createdAt,
    DateTime? updatedAt,
    this.eatenAt,
    this.cookingMinutes,
    this.tasteRating,
    this.satietyRating,
    this.totalCookedWeightGrams,
  }) : updatedAt = updatedAt ?? createdAt;

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id']?.toString(),
        profileId: json['profile_id']?.toString() ?? '',
        title: json['title'] ?? '',
        notes: json['notes']?.toString(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
        updatedAt: json['updated_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'])
            : null,
        eatenAt: json['eaten_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['eaten_at'])
            : null,
        cookingMinutes: json['cooking_minutes'],
        tasteRating: json['taste_rating'],
        satietyRating: json['satiety_rating'],
        totalCookedWeightGrams:
            (json['total_cooked_weight_grams'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'title': title,
        'notes': notes,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'eaten_at': eatenAt?.millisecondsSinceEpoch,
        'cooking_minutes': cookingMinutes,
        'taste_rating': tasteRating,
        'satiety_rating': satietyRating,
        'total_cooked_weight_grams': totalCookedWeightGrams,
      };

  bool isEaten() {
    return eatenAt != null;
  }
}
