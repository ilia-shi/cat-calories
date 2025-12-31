import 'package:cat_calories/screens/products/_products_view.dart';
import 'package:flutter/material.dart';

class ProductsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() =>
      _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: Container(
        child: ProductsView(),
      ),
    );
  }
}
