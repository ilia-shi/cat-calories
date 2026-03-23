import 'package:cat_calories/features/products/domain/product_category_model.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';

abstract interface class ProductCategoryRepositoryInterface {
  Future<List<ProductCategoryModel>> fetchByProfile(ProfileModel profile);
  Future<ProductCategoryModel?> find(String id);
  Future<ProductCategoryModel> insert(ProductCategoryModel category);
  Future<ProductCategoryModel> update(ProductCategoryModel category);
  Future<int> delete(ProductCategoryModel category);
  Future<void> resort(List<ProductCategoryModel> categories);
  Future<int> getProductCount(ProductCategoryModel category);
  Future<void> createDefaultCategoriesIfNeeded(ProfileModel profile);
}
