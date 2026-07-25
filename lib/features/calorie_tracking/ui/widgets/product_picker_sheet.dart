import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/products/domain/product_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';

/// Searchable product list that pops the picked [Product], falling back to the
/// recently used ones while the query is empty.
class ProductPickerSheet extends StatefulWidget {
  final ProductRepositoryInterface productsRepo;
  final Profile profile;

  const ProductPickerSheet({
    Key? key,
    required this.productsRepo,
    required this.profile,
  }) : super(key: key);

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  List<Product> _products = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String query) async {
    _query = query;
    final results = query.trim().isEmpty
        ? await widget.productsRepo.fetchRecentlyUsed(widget.profile, limit: 20)
        : await widget.productsRepo.search(widget.profile, query.trim());
    // Out-of-order responses: drop results for a stale query.
    if (mounted && query == _query) {
      setState(() => _products = results);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search products…',
                  ),
                  onChanged: _search,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final parts = <String>[
                      if (product.caloriesPer100g != null)
                        '${product.caloriesPer100g!.toStringAsFixed(0)} kcal/100g',
                      if (product.hasPrice)
                        '${product.pricePerPackage!.toStringAsFixed(2)} '
                            '${product.priceCurrency ?? ''} / '
                            '${product.packageWeightGrams!.toStringAsFixed(0)}g',
                    ];
                    return ListTile(
                      title: Text(product.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: parts.isEmpty
                          ? null
                          : Text(
                              parts.join(' · '),
                              style: TextStyle(
                                fontSize: 12,
                                color: appColors.textSecondary,
                              ),
                            ),
                      onTap: () => Navigator.of(context).pop(product),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
