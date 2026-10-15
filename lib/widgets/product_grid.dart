import 'package:flutter/material.dart';

import '../core/product.dart';
import 'common.dart';
import 'product_card.dart';

typedef PageLoader = Future<List<Product>> Function(int page);

class ProductGrid extends StatefulWidget {
  final PageLoader loader;
  final Widget? header;
  const ProductGrid({super.key, required this.loader, this.header});

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  final _items = <Product>[];
  final _ids = <int>{};
  final _scroll = ScrollController();
  int _page = 1;
  bool _loading = false;
  bool _done = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading || _done) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.loader(_page);
      var added = 0;
      for (final p in list) {
        if (_ids.add(p.id)) {
          _items.add(p);
          added++;
        }
      }
      _page++;
      if (added == 0) _done = true;
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    _items.clear();
    _ids.clear();
    _page = 1;
    _done = false;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return ErrorView(message: '$_error', onRetry: _load);
    }
    if (_items.isEmpty && _done) {
      return const EmptyView(icon: Icons.inventory_2_outlined, message: 'لا توجد منتجات');
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (c, i) => ProductCard(product: _items[i]),
                childCount: _items.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : _error != null
                        ? TextButton(onPressed: _load, child: const Text('إعادة المحاولة'))
                        : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
