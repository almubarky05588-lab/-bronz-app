import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/product.dart';
import '../core/theme.dart';
import 'product_card.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  const SectionHeader({super.key, required this.title, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Row(
                children: [
                  const Text('عرض الكل', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 2),
                  Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold), size: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// صف منتجات أفقي — يختفي كاملًا (مع عنوانه) إذا لم يكن فيه منتجات.
class ProductRail extends StatefulWidget {
  final String title;
  final Future<List<Product>> Function() loader;
  final VoidCallback? onMore;
  const ProductRail({super.key, required this.title, required this.loader, this.onMore});

  @override
  State<ProductRail> createState() => _ProductRailState();
}

class _ProductRailState extends State<ProductRail> {
  late Future<List<Product>> _future = widget.loader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, s) {
        final loading = s.connectionState != ConnectionState.done;
        final list = s.data ?? const <Product>[];
        if (!loading && !s.hasError && list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: widget.title, onMore: widget.onMore),
            SizedBox(
              height: 304,
              child: loading
                  ? ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, __) => Container(
                        width: 170,
                        decoration: BoxDecoration(
                          color: BronzColors.tile,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                  : s.hasError
                      ? Center(
                          child: TextButton(
                            onPressed: () => setState(() => _future = widget.loader()),
                            child: const Text('تعذّر التحميل — إعادة المحاولة'),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => ProductCard(product: list[i], width: 170),
                        ),
            ),
          ],
        );
      },
    );
  }
}
