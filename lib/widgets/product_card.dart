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
import 'motion.dart';

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
      child: Pressable(
        scale: 0.97,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductScreen(product: p)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── الصورة على خلفية رمادية فاتحة (تصميم v2)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(BronzRadius.tile),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(p.image, padding: 18, background: BronzColors.tile),
                    if (!p.available)
                      const PositionedDirectional(top: 10, start: 10, child: _Pill('نفدت', BronzColors.faint))
                    else if (off != null)
                      PositionedDirectional(top: 10, start: 10, child: _Pill('-$off%', BronzColors.ink)),
                    PositionedDirectional(top: 8, end: 8, child: FavButton(product: p, size: 32)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (p.brand.isNotEmpty)
              Text(
                p.brand.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: BronzColors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            SizedBox(
              height: 38,
              child: Text(
                p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(formatPrice(p.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      if (p.oldPrice != null)
                        Text(
                          formatPrice(p.oldPrice!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: BronzColors.faint,
                            decoration: TextDecoration.lineThrough,
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
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// زر المفضلة (قلب) — ينبض عند الضغط.
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
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (c, a) => ScaleTransition(
                scale: Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.elasticOut)),
                child: c,
              ),
              child: Icon(
                on ? PhosphorIcons.heart(PhosphorIconsStyle.fill) : PhosphorIcons.heart(),
                key: ValueKey(on),
                size: size * 0.5,
                color: BronzColors.ink,
              ),
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
    return Pressable(
      scale: 0.85,
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? BronzColors.ink : const Color(0xFFD6D6D3),
          shape: BoxShape.circle,
        ),
        child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18, color: Colors.white),
      ),
    );
  }
}
