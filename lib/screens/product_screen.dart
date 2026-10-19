import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/cart.dart';
import '../core/product.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../core/util.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

class ProductScreen extends StatefulWidget {
  final Product product;
  const ProductScreen({super.key, required this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Product _p = widget.product;
  bool _loadingDetails = true;
  int _image = 0;
  int _qty = 1;
  bool _justAdded = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final d = await StoreApi.details(_p.id);
      if (!mounted) return;
      setState(() => _p = d.mergedWith(_p));
    } catch (_) {
      // نكتفي ببيانات القائمة
    }
    if (mounted) setState(() => _loadingDetails = false);
  }

  void _openCart() {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  Future<void> _add() async {
    Cart.instance.add(_p, qty: _qty);
    showBronzToast(context, 'أُضيف إلى السلة', actionLabel: 'السلة', onAction: _openCart);
    setState(() => _justAdded = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _justAdded = false);
  }

  Widget _floating(Widget child) => Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(child: child),
      );

  @override
  Widget build(BuildContext context) {
    final desc = stripHtml(_p.description);
    final off = _p.discountPercent;
    final ready = _p.name.isNotEmpty;
    final top = MediaQuery.of(context).padding.top;
    final images = _p.images.isEmpty ? [_p.image] : _p.images;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ─── معرض الصور بعرض الشاشة على خلفية رمادية فاتحة (تصميم v2)
          Container(
            color: BronzColors.tile,
            height: top + 380,
            child: Stack(
              children: [
                Positioned.fill(
                  top: top + 50,
                  bottom: 30,
                  child: PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _image = i),
                    itemBuilder: (_, i) => NetImage(images[i], padding: 24, background: BronzColors.tile),
                  ),
                ),
                PositionedDirectional(
                  top: top + 8,
                  start: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: _floating(Icon(PhosphorIcons.caretRight(), size: 20, color: BronzColors.ink)),
                  ),
                ),
                PositionedDirectional(
                  top: top + 8,
                  end: 20,
                  child: Row(
                    children: [
                      ListenableBuilder(
                        listenable: Cart.instance,
                        builder: (context, _) => Badge(
                          backgroundColor: BronzColors.ink,
                          textColor: Colors.white,
                          isLabelVisible: Cart.instance.count > 0,
                          label: Text('${Cart.instance.count}'),
                          child: GestureDetector(
                            onTap: _openCart,
                            child: _floating(Icon(PhosphorIcons.handbag(), size: 20, color: BronzColors.ink)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FavButton(product: _p, size: 42),
                    ],
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < images.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _image ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _image ? BronzColors.ink : const Color(0x33000000),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_p.brand.isNotEmpty) ...[
                  Text(
                    _p.brand.toUpperCase(),
                    style: const TextStyle(
                      color: BronzColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (ready)
                  Text(_p.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.5))
                else
                  Container(
                    height: 22,
                    width: 220,
                    decoration: BoxDecoration(color: BronzColors.soft, borderRadius: BorderRadius.circular(6)),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _p.price > 0 ? formatPrice(_p.price) : '',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    if (_p.oldPrice != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        formatPrice(_p.oldPrice!),
                        style: const TextStyle(
                          fontSize: 15,
                          color: BronzColors.faint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    if (off != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(color: BronzColors.ink, borderRadius: BorderRadius.circular(20)),
                        child: Text('-$off%',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: BronzColors.line),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _Perk(PhosphorIcons.sealCheck(), 'أصلي 100%')),
                    Expanded(child: _Perk(PhosphorIcons.truck(), 'شحن سريع')),
                    Expanded(child: _Perk(PhosphorIcons.lock(), 'دفع آمن')),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: BronzColors.line),
                const SizedBox(height: 22),
                const Text('الوصف', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (desc.isNotEmpty)
                  Text(desc, style: const TextStyle(fontSize: 14.5, height: 1.85, color: BronzColors.muted))
                else if (_loadingDetails)
                  Column(
                    children: List.generate(
                      4,
                      (i) => Container(
                        height: 12,
                        margin: const EdgeInsets.only(bottom: 10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: BronzColors.soft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  )
                else
                  const Text('لا يوجد وصف لهذا المنتج', style: TextStyle(color: BronzColors.muted)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      // ─── شريط الشراء الثابت
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: BronzColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                QtyStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton(
                    onPressed: _p.available && _p.price > 0 ? _add : null,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _justAdded
                          ? Row(
                              key: const ValueKey('added'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 18),
                                const SizedBox(width: 6),
                                const Text('تمت الإضافة'),
                              ],
                            )
                          : Text(
                              _p.available
                                  ? (_p.price > 0 ? 'أضف للسلة · ${formatPrice(_p.price * _qty)}' : 'أضف للسلة')
                                  : 'نفدت الكمية',
                              key: const ValueKey('add'),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Perk(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: BronzColors.ink),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
