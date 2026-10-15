import 'package:flutter/material.dart';

import '../core/catalog.dart';
import '../core/store_api.dart';
import '../widgets/product_grid.dart';

class CategoryScreen extends StatefulWidget {
  final StoreCategory category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late int _selected = widget.category.id;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return Scaffold(
      appBar: AppBar(title: Text(c.name)),
      body: Column(
        children: [
          if (c.children.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _chip('الكل', c.id),
                  for (final s in c.children) _chip(s.name, s.id),
                ],
              ),
            ),
          Expanded(
            child: ProductGrid(
              key: ValueKey(_selected),
              loader: (p) => StoreApi.byCategory(_selected, page: p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int id) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _selected == id,
        onSelected: (_) => setState(() => _selected = id),
      ),
    );
  }
}
