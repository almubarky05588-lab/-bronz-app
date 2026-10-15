import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/product.dart';
import '../core/theme.dart';
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

  static const _delegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.58,
  );

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _error != null && !_loading) {
      return ErrorView(message: '$_error', onRetry: _load);
    }
    if (_items.isEmpty && _done) {
      return EmptyView(icon: PhosphorIcons.package(), message: 'لا توجد منتجات هنا حاليًا');
    }
    final skeleton = _items.isEmpty && _loading;
    return RefreshIndicator(
      color: BronzColors.ink,
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (c, i) => skeleton
                    ? Container(
                        decoration: BoxDecoration(
                          color: BronzColors.tile,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      )
                    : ProductCard(product: _items[i]),
                childCount: skeleton ? 6 : _items.length,
              ),
              gridDelegate: _delegate,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: _loading && !skeleton
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: BronzColors.ink),
                      )
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
