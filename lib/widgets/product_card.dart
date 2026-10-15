import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/cart.dart';
import '../core/favorites.dart';
import '../core/product.dart';
import '../core/theme.dart';
import '../core/util.dart';
import '../screens/cart_screen.dart';
import '../screens/product_screen.dart';
import 'common.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final double? width;
  const ProductCard({super.key, required this.product, this.width});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final off = p.discountPercent;
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductScreen(product: p)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BronzColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: NetImage(p.image, padding: 12, background: BronzColors.tile),
                      ),
                    ),
                    if (!p.available)
                      const PositionedDirectional(top: 14, start: 14, child: _Pill('نفدت', BronzColors.muted))
                    else if (off != null)
                      PositionedDirectional(top: 14, start: 14, child: _Pill('−$off%', BronzColors.sale)),
                    PositionedDirectional(top: 12, end: 12, child: FavButton(product: p, size: 34)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.brand.isEmpty ? ' ' : p.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: BronzColors.gold, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 36,
                      child: Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.oldPrice != null)
                                Text(
                                  formatPrice(p.oldPrice!),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: BronzColors.muted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                formatPrice(p.price),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: off != null ? BronzColors.sale : BronzColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _QuickAdd(product: p),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        textDirection: TextDirection.ltr,
        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// زر المفضلة (قلب) — يُستخدم في البطاقات وصفحة المنتج.
class FavButton extends StatelessWidget {
  final Product product;
  final double size;
  const FavButton({super.key, required this.product, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Favorites.instance,
      builder: (context, _) {
        final on = Favorites.instance.contains(product.id);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Favorites.instance.toggle(product);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Icon(
              on ? PhosphorIcons.heart(PhosphorIconsStyle.fill) : PhosphorIcons.heart(),
              size: size * 0.52,
              color: on ? BronzColors.sale : BronzColors.ink,
            ),
          ),
        );
      },
    );
  }
}

class _QuickAdd extends StatelessWidget {
  final Product product;
  const _QuickAdd({required this.product});

  @override
  Widget build(BuildContext context) {
    final enabled = product.available;
    return GestureDetector(
      onTap: !enabled
          ? null
          : () {
              Cart.instance.add(product);
              showBronzToast(
                context,
                'أُضيف إلى السلة',
                actionLabel: 'السلة',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              );
            },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? BronzColors.ink : const Color(0xFFD9D4CC),
          shape: BoxShape.circle,
        ),
        child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18, color: Colors.white),
      ),
    );
  }
}
