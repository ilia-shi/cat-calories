import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/calculator/product_weight_input_sheet.dart';
import 'package:cat_calories/common/widgets/macro_chips.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductSearchField extends StatelessWidget {
  const ProductSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        final fetched = state is HomeFetched ? state : null;
        return _SearchPill(
          onTap: fetched != null ? () => _openSearch(context, fetched) : null,
        );
      },
    );
  }

  Future<void> _openSearch(BuildContext context, HomeFetched state) async {
    final product = await showSearch<Product?>(
      context: context,
      delegate: ProductSearchDelegate(state.products),
    );
    if (product == null || !context.mounted) {
      return;
    }
    _eatProduct(context, product);
  }

  void _eatProduct(BuildContext context, Product product) {
    // Waking period may have ended while the search page was open; use fresh state.
    final state = context.read<HomeBloc>().state;
    if (state is! HomeFetched) {
      return;
    }

    if (!product.hasNutrition) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product has no nutrition information'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final wakingPeriod = state.currentWakingPeriod;
    if (wakingPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active waking period'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ProductWeightInputSheet(
        product: product,
        onSubmit: (result) {
          Navigator.of(sheetContext).pop();
          context.read<HomeBloc>().add(
                EatProductEvent(
                  product,
                  result.weightGrams,
                  wakingPeriod,
                  state.periodCalorieItems,
                  (_) {
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
}

/// The tappable pill rendered in the app bar toolbar.
class _SearchPill extends StatelessWidget {
  final VoidCallback? onTap;

  const _SearchPill({this.onTap});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final shape = AppCard.squircleBorder(radius: 10);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: ShapeDecoration(
            color: appColors.surfaceSubtle,
            shape: shape,
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: appColors.textTertiary),
              const SizedBox(width: 8),
              Text(
                'Search products',
                style: TextStyle(fontSize: 14, color: appColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen search over the in-memory product list (loaded from the
/// database), matching on title and description. Returns the chosen product.
class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;

  ProductSearchDelegate(this.products)
      : super(searchFieldLabel: 'Search products');

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'Clear',
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  List<Product> _filtered() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return products;
    }
    return products.where((product) {
      return product.title.toLowerCase().contains(q) ||
          (product.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Widget _buildList(BuildContext context) {
    final results = _filtered();
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No products found',
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return _ProductResultTile(
          product: product,
          onTap: () => close(context, product),
        );
      },
    );
  }
}

class _ProductResultTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductResultTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.restaurant, color: Colors.orange[700]),
      ),
      title: Text(
        product.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: product.hasNutrition
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: MacroBadgesRow(
                calories: product.caloriesPer100g,
                protein: product.proteinsPer100g,
                fat: product.fatsPer100g,
                carbs: product.carbsPer100g,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
