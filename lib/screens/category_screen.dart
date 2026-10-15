import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/catalog.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
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
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
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
    final on = _selected == id;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: () {
          if (on) return;
          HapticFeedback.selectionClick();
          setState(() => _selected = id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? BronzColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? BronzColors.ink : BronzColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: on ? Colors.white : BronzColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// قائمة منتجات عامة بعنوان (العروض، وصل حديثًا…)
class ProductListScreen extends StatelessWidget {
  final String title;
  final PageLoader loader;
  const ProductListScreen({super.key, required this.title, required this.loader});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ProductGrid(loader: loader),
    );
  }
}
