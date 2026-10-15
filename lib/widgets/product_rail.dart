import 'package:flutter/material.dart';

import '../core/product.dart';
import '../core/theme.dart';
import 'product_card.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
          child: Row(
            children: [
              Text(widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              if (widget.onMore != null)
                TextButton(onPressed: widget.onMore, child: const Text('عرض الكل')),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: FutureBuilder<List<Product>>(
            future: _future,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: BronzColors.soft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              }
              if (s.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: () => setState(() => _future = widget.loader()),
                    child: const Text('تعذّر التحميل — إعادة المحاولة'),
                  ),
                );
              }
              final list = s.data ?? const <Product>[];
              if (list.isEmpty) return const SizedBox.shrink();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => ProductCard(product: list[i], width: 160),
              );
            },
          ),
        ),
      ],
    );
  }
}
