/// Model representing a food product with nutritional information per 100g
final class ProductModel {
  /// UUID identifier for the product
  String? id;
  String title;
  String? description;
  int usesCount;
  DateTime createdAt;
  DateTime updatedAt;
  int profileId;
  String? barcode;
  int sortOrder;

  /// Nutritional values per 100g
  double? caloriesPer100g;
  double? proteinsPer100g;
  double? fatsPer100g;
  double? carbsPer100g;

  /// Optional package weight in grams for "eat entire package" feature
  double? packageWeightGrams;

  /// Category UUID for custom product categorization
  String? categoryId;

  /// Last used timestamp for sorting by recency
  DateTime? lastUsedAt;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.usesCount,
    required this.createdAt,
    required this.updatedAt,
    required this.profileId,
    required this.barcode,
    required this.sortOrder,
    this.caloriesPer100g,
    this.proteinsPer100g,
    this.fatsPer100g,
    this.carbsPer100g,
    this.packageWeightGrams,
    this.categoryId,
    this.lastUsedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id']?.toString(),
    title: json['title'] ?? '',
    description: json['description']?.toString(),
    usesCount: _parseInt(json['uses_count']) ?? 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
        _parseInt(json['created_at']) ?? 0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
        _parseInt(json['updated_at']) ?? 0),
    profileId: _parseInt(json['profile_id']) ?? 1,
    barcode: json['barcode']?.toString(),
    sortOrder: _parseInt(json['sort_order']) ?? 0,
    // Support both old field names (for migration) and new field names
    caloriesPer100g: _parseDouble(json['calories_per_100g']) ??
        _parseDouble(json['calorie_content']),
    proteinsPer100g: _parseDouble(json['proteins_per_100g']) ??
        _parseDouble(json['proteins']),
    fatsPer100g: _parseDouble(json['fats_per_100g']) ??
        _parseDouble(json['fats']),
    carbsPer100g: _parseDouble(json['carbs_per_100g']) ??
        _parseDouble(json['carbohydrates']),
    packageWeightGrams: _parseDouble(json['package_weight_grams']),
    categoryId: json['category_id']?.toString(),
    lastUsedAt: json['last_used_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
        _parseInt(json['last_used_at']) ?? 0)
        : null,
  );

  /// Helper to parse int from various types
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();

    return null;
  }

  /// Helper to parse double from various types
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);

    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'uses_count': usesCount,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
    'profile_id': profileId,
    'barcode': barcode,
    'sort_order': sortOrder,
    'calories_per_100g': caloriesPer100g,
    'proteins_per_100g': proteinsPer100g,
    'fats_per_100g': fatsPer100g,
    'carbs_per_100g': carbsPer100g,
    'package_weight_grams': packageWeightGrams,
    'category_id': categoryId,
    'last_used_at': lastUsedAt?.millisecondsSinceEpoch,
  };

  /// Calculate calories for a given weight in grams
  double? calculateCalories(double weightGrams) {
    if (caloriesPer100g == null) return null;

    return (caloriesPer100g! / 100) * weightGrams;
  }

  /// Calculate protein for a given weight in grams
  double? calculateProtein(double weightGrams) {
    if (proteinsPer100g == null) return null;
    return (proteinsPer100g! / 100) * weightGrams;
  }

  /// Calculate fat for a given weight in grams
  double? calculateFat(double weightGrams) {
    if (fatsPer100g == null) return null;
    return (fatsPer100g! / 100) * weightGrams;
  }

  /// Calculate carbs for a given weight in grams
  double? calculateCarbs(double weightGrams) {
    if (carbsPer100g == null) return null;
    return (carbsPer100g! / 100) * weightGrams;
  }

  /// Check if the product has nutritional information
  bool get hasNutrition => caloriesPer100g != null;

  /// Check if the product has full macro information
  bool get hasFullMacros =>
      proteinsPer100g != null && fatsPer100g != null && carbsPer100g != null;

  /// Check if the product has package weight defined
  bool get hasPackageWeight =>
      packageWeightGrams != null && packageWeightGrams! > 0;

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    int? usesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? profileId,
    String? barcode,
    int? sortOrder,
    double? caloriesPer100g,
    double? proteinsPer100g,
    double? fatsPer100g,
    double? carbsPer100g,
    double? packageWeightGrams,
    String? categoryId,
    DateTime? lastUsedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      usesCount: usesCount ?? this.usesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileId: profileId ?? this.profileId,
      barcode: barcode ?? this.barcode,
      sortOrder: sortOrder ?? this.sortOrder,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinsPer100g: proteinsPer100g ?? this.proteinsPer100g,
      fatsPer100g: fatsPer100g ?? this.fatsPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      packageWeightGrams: packageWeightGrams ?? this.packageWeightGrams,
      categoryId: categoryId ?? this.categoryId,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}