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
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Row(
                children: [
                  const Text('عرض الكل',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BronzColors.muted)),
                  const SizedBox(width: 2),
                  Icon(PhosphorIcons.caretLeft(), size: 15, color: BronzColors.muted),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// صف منتجات — أفقي أو شبكة عمودين — يختفي كاملًا (مع عنوانه) إذا لم يكن فيه منتجات.
class ProductRail extends StatefulWidget {
  final String title;
  final Future<List<Product>> Function() loader;
  final VoidCallback? onMore;
  final bool grid;
  final int? limit;
  const ProductRail({
    super.key,
    required this.title,
    required this.loader,
    this.onMore,
    this.grid = false,
    this.limit,
  });

  @override
  State<ProductRail> createState() => _ProductRailState();
}

class _ProductRailState extends State<ProductRail> {
  late Future<List<Product>> _future = widget.loader();

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 22,
    crossAxisSpacing: 14,
    childAspectRatio: 0.56,
  );

  Widget _placeholder() => Container(
        width: 164,
        decoration: BoxDecoration(color: BronzColors.tile, borderRadius: BorderRadius.circular(BronzRadius.tile)),
      );

  Widget _retry() => Center(
        child: TextButton(
          onPressed: () => setState(() => _future = widget.loader()),
          child: const Text('تعذّر التحميل — إعادة المحاولة'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, s) {
        final loading = s.connectionState != ConnectionState.done;
        var list = s.data ?? const <Product>[];
        if (widget.limit != null && list.length > widget.limit!) list = list.sublist(0, widget.limit!);
        if (!loading && !s.hasError && list.isEmpty) return const SizedBox.shrink();

        final Widget body;
        if (widget.grid) {
          body = s.hasError && !loading
              ? SizedBox(height: 120, child: _retry())
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: _gridDelegate,
                  itemCount: loading ? 4 : list.length,
                  itemBuilder: (_, i) => loading ? _placeholder() : ProductCard(product: list[i]),
                );
        } else {
          body = SizedBox(
            height: 316,
            child: loading
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, __) => _placeholder(),
                  )
                : s.hasError
                    ? _retry()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (_, i) => ProductCard(product: list[i], width: 164),
                      ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [SectionHeader(title: widget.title, onMore: widget.onMore), body],
        );
      },
    );
  }
}
