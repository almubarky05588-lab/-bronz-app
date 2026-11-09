import 'dart:async';

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
                    else if (p.saleEnd != null && p.saleEnd!.isAfter(DateTime.now()))
                      PositionedDirectional(top: 10, start: 10, child: _Countdown(end: p.saleEnd!)),
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
                      Text(
                        formatPrice(p.price),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: off != null ? _saleRed : BronzColors.ink,
                        ),
                      ),
                      if (p.oldPrice != null)
                        Text(
                          formatPrice(p.oldPrice!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: BronzColors.faint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (off != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: _saleRedSoft, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            '-$off%',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(color: _saleRed, fontSize: 11.5, fontWeight: FontWeight.w800),
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

/// أحمر العروض (مثل بطاقات المتاجر الكبيرة)
const _saleRed = Color(0xFFE5484D);
const _saleRedSoft = Color(0xFFFDE8E9);

/// عدّاد «ينتهي بعد: 12:05:56» يتحدّث كل ثانية.
class _Countdown extends StatefulWidget {
  final DateTime end;
  const _Countdown({required this.end});

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    if (d.isNegative) return 'انتهى';
    if (d.inDays >= 1) return '${d.inDays} يوم و ${(d.inHours % 24).toString().padLeft(2, '0')} ساعة';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.end.difference(DateTime.now());
    if (left.isNegative) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: _saleRed, borderRadius: BorderRadius.circular(8)),
      child: Text(
        'ينتهي بعد: ${_fmt(left)}',
        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
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
