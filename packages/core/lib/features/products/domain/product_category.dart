final class ProductCategory {
  String? id;
  String name;
  String? iconName;
  String? colorHex;
  int sortOrder;
  String profileId;
  DateTime createdAt;
  DateTime updatedAt;

  ProductCategory({
    required this.id,
    required this.name,
    this.iconName,
    this.colorHex,
    required this.sortOrder,
    required this.profileId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: json['id']?.toString(),
        name: json['name'] ?? '',
        iconName: json['icon_name']?.toString(),
        colorHex: json['color_hex']?.toString(),
        sortOrder: _parseInt(json['sort_order']) ?? 0,
        profileId: json['profile_id']?.toString() ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            _parseInt(json['created_at']) ?? 0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            _parseInt(json['updated_at']) ?? 0),
      );

  /// Helper to parse int from various types
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon_name': iconName,
    'color_hex': colorHex,
    'sort_order': sortOrder,
    'profile_id': profileId,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  ProductCategory copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    int? sortOrder,
    String? profileId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      profileId: profileId ?? this.profileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}