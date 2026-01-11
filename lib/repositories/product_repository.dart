import 'package:cat_calories/database/database.dart';
import 'package:cat_calories/models/product_model.dart';
import 'package:cat_calories/models/profile_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Enum for product sorting options
enum ProductSortOrder {
  /// Sort by manual sort order
  manual,
  /// Sort by most used (uses_count descending)
  mostUsed,
  /// Sort by most recently used
  recentlyUsed,
  /// Sort alphabetically by title
  alphabetical,
}

class ProductRepository {
  static const String tableName = 'products';
  static const _uuid = Uuid();

  /// Fetch all products with default sorting
  Future<List<ProductModel>> fetchAll() async {
    final productsResult = await DBProvider.db.query(
      tableName,
      orderBy: 'sort_order ASC',
    );

    return productsResult
        .map((element) => ProductModel.fromJson(element))
        .toList();
  }

  /// Fetch products by profile with specified sorting
  Future<List<ProductModel>> fetchByProfile(
      ProfileModel profile, {
        ProductSortOrder sortOrder = ProductSortOrder.manual,
        String? categoryId,
        String? searchQuery,
        int? limit,
      }) async {
    String orderBy;
    switch (sortOrder) {
      case ProductSortOrder.manual:
        orderBy = 'sort_order ASC';
        break;
      case ProductSortOrder.mostUsed:
        orderBy = 'uses_count DESC, title ASC';
        break;
      case ProductSortOrder.recentlyUsed:
        orderBy = 'last_used_at DESC NULLS LAST, uses_count DESC, title ASC';
        break;
      case ProductSortOrder.alphabetical:
        orderBy = 'title ASC';
        break;
    }

    // Build where clause
    final whereParts = <String>['profile_id = ?'];
    final whereArgs = <dynamic>[profile.id!];

    if (categoryId != null) {
      whereParts.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereParts.add('(title LIKE ? OR description LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final productsResult = await DBProvider.db.query(
      tableName,
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );

    return productsResult
        .map((element) => ProductModel.fromJson(element))
        .toList();
  }

  /// Fetch products by category
  Future<List<ProductModel>> fetchByCategory(
      ProfileModel profile,
      String categoryId, {
        ProductSortOrder sortOrder = ProductSortOrder.manual,
      }) async {
    return fetchByProfile(
      profile,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  }

  /// Fetch uncategorized products
  Future<List<ProductModel>> fetchUncategorized(
      ProfileModel profile, {
        ProductSortOrder sortOrder = ProductSortOrder.manual,
      }) async {
    String orderBy;
    switch (sortOrder) {
      case ProductSortOrder.manual:
        orderBy = 'sort_order ASC';
        break;
      case ProductSortOrder.mostUsed:
        orderBy = 'uses_count DESC, title ASC';
        break;
      case ProductSortOrder.recentlyUsed:
        orderBy = 'last_used_at DESC NULLS LAST, uses_count DESC, title ASC';
        break;
      case ProductSortOrder.alphabetical:
        orderBy = 'title ASC';
        break;
    }

    final productsResult = await DBProvider.db.query(
      tableName,
      where: 'profile_id = ? AND category_id IS NULL',
      whereArgs: [profile.id!],
      orderBy: orderBy,
    );

    return productsResult
        .map((element) => ProductModel.fromJson(element))
        .toList();
  }

  /// Search products by title or description
  Future<List<ProductModel>> search(
      ProfileModel profile,
      String query, {
        int limit = 20,
      }) async {
    if (query.isEmpty) {
      return fetchByProfile(
        profile,
        sortOrder: ProductSortOrder.recentlyUsed,
        limit: limit,
      );
    }

    return fetchByProfile(
      profile,
      searchQuery: query,
      sortOrder: ProductSortOrder.mostUsed,
      limit: limit,
    );
  }

  /// Fetch recently used products
  Future<List<ProductModel>> fetchRecentlyUsed(
      ProfileModel profile, {
        int limit = 10,
      }) async {
    final productsResult = await DBProvider.db.query(
      tableName,
      where: 'profile_id = ? AND last_used_at IS NOT NULL',
      whereArgs: [profile.id!],
      orderBy: 'last_used_at DESC',
      limit: limit,
    );

    return productsResult
        .map((element) => ProductModel.fromJson(element))
        .toList();
  }

  /// Fetch most used products
  Future<List<ProductModel>> fetchMostUsed(
      ProfileModel profile, {
        int limit = 10,
      }) async {
    final productsResult = await DBProvider.db.query(
      tableName,
      where: 'profile_id = ? AND uses_count > 0',
      whereArgs: [profile.id!],
      orderBy: 'uses_count DESC',
      limit: limit,
    );

    return productsResult
        .map((element) => ProductModel.fromJson(element))
        .toList();
  }

  /// Find a product by UUID
  Future<ProductModel?> find(String id) async {
    final result = await DBProvider.db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ProductModel.fromJson(result.first);
  }

  /// Find a product by barcode
  Future<ProductModel?> findByBarcode(ProfileModel profile, String barcode) async {
    final result = await DBProvider.db.query(
      tableName,
      where: 'profile_id = ? AND barcode = ?',
      whereArgs: [profile.id!, barcode],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ProductModel.fromJson(result.first);
  }

  /// Insert a new product (generates UUID if not provided)
  Future<ProductModel> insert(ProductModel product) async {
    if (product.id == null || product.id!.isEmpty) {
      product.id = _uuid.v4();
    }
    await DBProvider.db.insert(tableName, product.toJson());
    return product;
  }

  /// Delete a product
  Future<int> delete(ProductModel product) async {
    return await DBProvider.db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Update a product
  Future<ProductModel> update(ProductModel product) async {
    product.updatedAt = DateTime.now();
    await DBProvider.db.update(
      tableName,
      product.toJson(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    return product;
  }

  /// Increment uses count and update last used timestamp
  Future<ProductModel> recordUsage(ProductModel product) async {
    product.usesCount = product.usesCount + 1;
    product.lastUsedAt = DateTime.now();
    product.updatedAt = DateTime.now();

    await DBProvider.db.update(
      tableName,
      {
        'uses_count': product.usesCount,
        'last_used_at': product.lastUsedAt!.millisecondsSinceEpoch,
        'updated_at': product.updatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );

    return product;
  }

  /// Resort products
  Future<void> resort(List<ProductModel> products) async {
    final Batch batch = await DBProvider.db.batch();

    for (int i = 0; i < products.length; i++) {
      final ProductModel product = products[i];
      batch.update(
        tableName,
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [product.id],
      );
    }

    await batch.commit();
  }

  /// Offset sort order for inserting at the beginning
  Future<void> offsetSortOrder() async {
    await DBProvider.db.rawQuery(
      'UPDATE $tableName SET sort_order = sort_order + 1',
    );
  }

  /// Get count of products by category
  Future<Map<String?, int>> getCountByCategory(ProfileModel profile) async {
    final result = await DBProvider.db.rawQuery('''
      SELECT category_id, COUNT(*) as count 
      FROM $tableName 
      WHERE profile_id = ? 
      GROUP BY category_id
    ''', [profile.id!]);

    final counts = <String?, int>{};
    for (final row in result) {
      final categoryId = row['category_id']?.toString();
      final count = row['count'] as int;
      counts[categoryId] = count;
    }
    return counts;
  }
}