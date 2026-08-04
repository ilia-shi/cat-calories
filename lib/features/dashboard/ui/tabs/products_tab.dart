import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';
import 'package:cat_calories_core/features/products/domain/product_repository_interface.dart';
import 'package:cat_calories/features/products/ui/add_edit_product_screen.dart';
import 'package:cat_calories/features/products/ui/categories_screen.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/error_state_widget.dart';
import 'package:cat_calories/common/widgets/floating_toolbar.dart';
import 'package:cat_calories/common/widgets/macro_chips.dart';
import 'package:cat_calories/common/widgets/calculator/product_weight_input_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cat_calories_core/features/products/domain/product_category.dart';

/// Enum for product tab display mode
enum ProductDisplayMode {
  list,
  grid,
}

/// Keys for SharedPreferences
class _ProductPrefsKeys {
  static const String sortOrder = 'products_sort_order';
  static const String displayMode = 'products_display_mode';
  static const String selectedCategory = 'products_selected_category';
}

class ProductsTab extends StatefulWidget {
  const ProductsTab({Key? key}) : super(key: key);

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const double _categoryBarHeight = 44;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  ProductSortOrder _sortOrder = ProductSortOrder.recentlyUsed;
  ProductDisplayMode _displayMode = ProductDisplayMode.list;
  String? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final sortOrderIndex = prefs.getInt(_ProductPrefsKeys.sortOrder);
      if (sortOrderIndex != null &&
          sortOrderIndex < ProductSortOrder.values.length) {
        _sortOrder = ProductSortOrder.values[sortOrderIndex];
      }

      final displayModeIndex = prefs.getInt(_ProductPrefsKeys.displayMode);
      if (displayModeIndex != null &&
          displayModeIndex < ProductDisplayMode.values.length) {
        _displayMode = ProductDisplayMode.values[displayModeIndex];
      }

      _selectedCategoryId = prefs.getString(_ProductPrefsKeys.selectedCategory);
    } catch (e) {
      debugPrint('Failed to load product preferences: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_ProductPrefsKeys.sortOrder, _sortOrder.index);
      await prefs.setInt(_ProductPrefsKeys.displayMode, _displayMode.index);
      if (_selectedCategoryId != null) {
        await prefs.setString(
            _ProductPrefsKeys.selectedCategory, _selectedCategoryId!);
      } else {
        await prefs.remove(_ProductPrefsKeys.selectedCategory);
      }
    } catch (e) {
      debugPrint('Failed to save product preferences: $e');
    }
  }

  void _setSortOrder(ProductSortOrder sortOrder) {
    setState(() => _sortOrder = sortOrder);
    _savePreferences();
  }

  void _setDisplayMode(ProductDisplayMode displayMode) {
    setState(() => _displayMode = displayMode);
    _savePreferences();
  }

  void _setSelectedCategory(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _savePreferences();
  }

  List<Product> _filterAndSortProducts(
    List<Product> products,
    List<ProductCategory> categories,
  ) {
    // Filter by search query
    var filtered = products.where((product) {
      if (_searchQuery.isEmpty) {
        return true;
      }
      return product.title.toLowerCase().contains(_searchQuery) ||
          (product.description?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    // Filter by category
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((product) => product.categoryId == _selectedCategoryId)
          .toList();
    }

    // Sort products
    switch (_sortOrder) {
      case ProductSortOrder.manual:
        filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
      case ProductSortOrder.mostUsed:
        filtered.sort((a, b) => b.usesCount.compareTo(a.usesCount));
        break;
      case ProductSortOrder.recentlyUsed:
        filtered.sort((a, b) {
          if (a.lastUsedAt == null && b.lastUsedAt == null) {
            return b.usesCount.compareTo(a.usesCount);
          }
          if (a.lastUsedAt == null) {
            return 1;
          }
          if (b.lastUsedAt == null) {
            return -1;
          }
          return b.lastUsedAt!.compareTo(a.lastUsedAt!);
        });
        break;
      case ProductSortOrder.alphabetical:
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  void _showProductSheet(
    BuildContext context,
    Product product,
    WakingPeriod wakingPeriod,
    List<CalorieRecord> calorieItems,
  ) {
    if (!product.hasNutrition) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product has no nutrition information'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductWeightInputSheet(
        product: product,
        onSubmit: (result) {
          Navigator.of(context).pop();
          context.read<HomeBloc>().add(
                EatProductEvent(
                  product,
                  result.weightGrams,
                  wakingPeriod,
                  calorieItems,
                  (calorieItem) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${result.weightGrams.toStringAsFixed(0)}g of ${product.title} • '
                          '${result.calories.toStringAsFixed(0)} kcal added',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              );
        },
      ),
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditProductScreen(),
      ),
    );
  }

  void _navigateToEditProduct(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: product),
      ),
    );
  }

  void _navigateToCategories(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductCategoriesScreen(),
      ),
    );
  }

  /// Show bottom sheet with product options (Edit, Eat, Remove)
  void _showProductOptionsSheet(
    BuildContext context,
    Product product,
    WakingPeriod? wakingPeriod,
    List<CalorieRecord> calorieItems,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasWakingPeriod = wakingPeriod != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Product title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              // Edit option
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _navigateToEditProduct(context, product);
                },
              ),
              // Eat option
              ListTile(
                leading: Icon(
                  Icons.restaurant,
                  color: hasWakingPeriod ? Colors.green : Colors.grey,
                ),
                title: Text(
                  'Eat',
                  style: TextStyle(
                    color: hasWakingPeriod ? null : Colors.grey,
                  ),
                ),
                subtitle: !hasWakingPeriod
                    ? const Text(
                        'No active waking period',
                        style: TextStyle(fontSize: 12),
                      )
                    : null,
                onTap: hasWakingPeriod
                    ? () {
                        Navigator.of(bottomSheetContext).pop();
                        _showProductSheet(
                          context,
                          product,
                          wakingPeriod,
                          calorieItems,
                        );
                      }
                    : null,
              ),
              // Remove option
              ListTile(
                leading: const Icon(Icons.delete_outlined, color: Colors.red),
                title: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _showDeleteConfirmationDialog(context, product);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Show confirmation dialog before deleting a product
  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<HomeBloc>().add(DeleteProductEvent(product));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${product.title}" deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Products'),
        content: RadioGroup<ProductSortOrder>(
          groupValue: _sortOrder,
          onChanged: (value) {
            if (value != null) {
              _setSortOrder(value);
              Navigator.of(context).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ProductSortOrder.values.map((sortOrder) {
              return RadioListTile<ProductSortOrder>(
                title: Text(_getSortOrderLabel(sortOrder)),
                value: sortOrder,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getSortOrderLabel(ProductSortOrder sortOrder) {
    switch (sortOrder) {
      case ProductSortOrder.manual:
        return 'Manual';
      case ProductSortOrder.mostUsed:
        return 'Most Used';
      case ProductSortOrder.recentlyUsed:
        return 'Recently Used';
      case ProductSortOrder.alphabetical:
        return 'Alphabetical';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        if (state is HomeFetchingInProgress) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HomeError) {
          return ErrorStateWidget(
            message: state.message,
            technicalDetails: state.technicalDetails,
            onRetry: state.canRetry
                ? () => context.read<HomeBloc>().add(
                      HomeErrorDismissedEvent(retry: true),
                    )
                : null,
            onDismiss: state.previousState != null
                ? () => context.read<HomeBloc>().add(
                      HomeErrorDismissedEvent(retry: false),
                    )
                : null,
          );
        }

        if (state is HomeFetched) {
          final filteredProducts = _filterAndSortProducts(
            state.products,
            state.productCategories,
          );

          return FloatingToolbarHost(
            topInset: FloatingToolbar.topMargin +
                FloatingToolbar.expandedHeight +
                _categoryBarHeight +
                FloatingToolbar.bottomGap,
            toolbars: (context, collapseProgress) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingToolbar(
                  collapseProgress: collapseProgress,
                  children: _toolbarChildren(context, filteredProducts.length),
                ),
                // Pinned below the action bar but NOT a floating toolbar: plain,
                // no border, no collapse. Opaque so the list doesn't show
                // through the transparent chips as it scrolls under.
                Container(
                  height: _categoryBarHeight,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _buildCategoryFilter(context, state),
                ),
              ],
            ),
            builder: (context, topInset) =>
                _buildBody(context, state, filteredProducts, topInset),
          );
        }

        return const Center(child: Text('Something went wrong'));
      },
    );
  }

  Widget _buildCategoryFilter(BuildContext context, HomeFetched state) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        _CategoryChip(
          label: 'All',
          isSelected: _selectedCategoryId == null,
          onTap: () => _setSelectedCategory(null),
        ),
        ...state.productCategories.map((category) {
          return _CategoryChip(
            label: category.name,
            isSelected: _selectedCategoryId == category.id,
            onTap: () => _setSelectedCategory(category.id),
            colorHex: category.colorHex,
          );
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ActionChip(
            avatar: const Icon(Icons.settings, size: 18),
            label: const Text('Manage'),
            onPressed: () => _navigateToCategories(context),
            backgroundColor: Colors.transparent,
            shape: AppCard.squircleBorder(radius: 12, side: BorderSide.none),
            side: BorderSide.none,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  List<Widget> _toolbarChildren(BuildContext context, int productCount) {
    return [
      Text(
        '$productCount products',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      const Spacer(),
      ToolbarActionButton(
        icon: Icons.sort,
        tooltip: 'Sort',
        onPressed: () => _showSortDialog(context),
      ),
      ToolbarActionButton(
        icon: _displayMode == ProductDisplayMode.list
            ? Icons.grid_view
            : Icons.list,
        tooltip: 'Toggle view',
        onPressed: () {
          _setDisplayMode(
            _displayMode == ProductDisplayMode.list
                ? ProductDisplayMode.grid
                : ProductDisplayMode.list,
          );
        },
      ),
      ToolbarActionButton(
        icon: Icons.add,
        tooltip: 'Add product',
        onPressed: () => _navigateToAddProduct(context),
      ),
    ];
  }

  /// Scrolls under the pinned toolbar + category bar: [topInset] clears both,
  /// then the products (or the empty state) follow.
  Widget _buildBody(
    BuildContext context,
    HomeFetched state,
    List<Product> products,
    double topInset,
  ) {
    return CustomScrollView(
      // Own controller (not the NestedScrollView's primary one) so the parent
      // doesn't translate the whole body — that would drag the pinned toolbar
      // overlay with it. AlwaysScrollable so a short (filtered) list still
      // claims the vertical drag instead of letting the parent scroll it.
      controller: _scrollController,
      primary: false,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topInset)),
        if (products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(context),
          )
        else ...[
          _buildProductsSliver(context, state, products),
          // Clears the floating bottom nav.
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No products found' : 'No products yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Add your first product to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddProduct(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsSliver(
    BuildContext context,
    HomeFetched state,
    List<Product> products,
  ) {
    // Check if there's an active waking period
    final wakingPeriod = state.currentWakingPeriod;
    final hasWakingPeriod = wakingPeriod != null;

    if (_displayMode == ProductDisplayMode.grid) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.95,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final category = state.getCategoryById(product.categoryId);
            return _ProductGridItem(
              product: product,
              category: category,
              onTap: hasWakingPeriod
                  ? () => _showProductSheet(
                        context,
                        product,
                        wakingPeriod,
                        state.periodCalorieItems,
                      )
                  : null,
              onLongPress: () => _showProductOptionsSheet(
                context,
                product,
                wakingPeriod,
                state.periodCalorieItems,
              ),
              onEdit: () => _navigateToEditProduct(context, product),
            );
          },
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      sliver: SliverList.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final category = state.getCategoryById(product.categoryId);
          return _ProductListItem(
            product: product,
            category: category,
            onTap: hasWakingPeriod
                ? () => _showProductSheet(
                      context,
                      product,
                      wakingPeriod,
                      state.periodCalorieItems,
                    )
                : null,
            onLongPress: () => _showProductOptionsSheet(
              context,
              product,
              wakingPeriod,
              state.periodCalorieItems,
            ),
            onEdit: () => _navigateToEditProduct(context, product),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? colorHex;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.colorHex,
  });

  Color? _parseColor() {
    if (colorHex == null) {
      return null;
    }
    try {
      final hex = colorHex!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor() ?? Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.transparent,
        selectedColor: color,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        shape: AppCard.squircleBorder(radius: 12, side: BorderSide.none),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final Product product;
  final ProductCategory? category;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;

  const _ProductListItem({
    required this.product,
    this.category,
    this.onTap,
    required this.onLongPress,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        product.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.hasNutrition) ...[
            const SizedBox(height: 4),
            MacroBadgesRow(
              calories: product.caloriesPer100g,
              protein: product.proteinsPer100g,
              fat: product.fatsPer100g,
              carbs: product.carbsPer100g,
            ),
          ],
          if (category != null)
            Text(
              category!.name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product.usesCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${product.usesCount}×',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: true,
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final Product product;
  final ProductCategory? category;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;

  const _ProductGridItem({
    required this.product,
    this.category,
    this.onTap,
    required this.onLongPress,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: Colors.orange[700],
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (product.hasNutrition) ...[
                Text(
                  '${product.caloriesPer100g?.toStringAsFixed(0) ?? '-'} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                MacroBadgesRow(
                  protein: product.proteinsPer100g,
                  fat: product.fatsPer100g,
                  carbs: product.carbsPer100g,
                ),
              ],
              if (product.usesCount > 0)
                Text(
                  '${product.usesCount} uses',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
