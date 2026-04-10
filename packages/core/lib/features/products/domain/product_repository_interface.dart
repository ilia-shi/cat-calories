import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';

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

abstract interface class ProductRepositoryInterface {
  Future<List<Product>> fetchAll();
  Future<List<Product>> fetchByProfile(
      Profile profile, {
        ProductSortOrder sortOrder,
        String? categoryId,
        String? searchQuery,
        int? limit,
      });
  Future<List<Product>> fetchByCategory(
      Profile profile,
      String categoryId, {
        ProductSortOrder sortOrder,
      });
  Future<List<Product>> fetchUncategorized(
      Profile profile, {
        ProductSortOrder sortOrder,
      });
  Future<List<Product>> search(
      Profile profile,
      String query, {
        int limit,
      });
  Future<List<Product>> fetchRecentlyUsed(
      Profile profile, {
        int limit,
      });
  Future<List<Product>> fetchMostUsed(
      Profile profile, {
        int limit,
      });
  Future<Product?> find(String id);
  Future<Product?> findByBarcode(Profile profile, String barcode);
  Future<Product> insert(Product product);
  Future<int> delete(Product product);
  Future<Product> update(Product product);
  Future<Product> recordUsage(Product product);
  Future<void> resort(List<Product> products);
  Future<void> offsetSortOrder();
  Future<Map<String?, int>> getCountByCategory(Profile profile);
}
