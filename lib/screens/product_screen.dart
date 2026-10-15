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

  @override
  Widget build(BuildContext context) {
    final desc = stripHtml(_p.description);
    final off = _p.discountPercent;
    final ready = _p.name.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: Center(
            child: RoundIcon(
              icon: PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              size: 40,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        leadingWidth: 64,
        actions: [
          FavButton(product: _p, size: 40),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: Cart.instance,
            builder: (context, _) => Badge(
              backgroundColor: BronzColors.ink,
              textColor: Colors.white,
              isLabelVisible: Cart.instance.count > 0,
              label: Text('${Cart.instance.count}'),
              child: RoundIcon(icon: PhosphorIcons.handbag(), size: 40, onTap: _openCart),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Container(
                color: Colors.white,
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: PageView.builder(
                        itemCount: _p.images.isEmpty ? 1 : _p.images.length,
                        onPageChanged: (i) => setState(() => _image = i),
                        itemBuilder: (_, i) => NetImage(
                          _p.images.isEmpty ? _p.image : _p.images[i],
                          padding: 26,
                        ),
                      ),
                    ),
                    if (off != null)
                      PositionedDirectional(
                        top: 16,
                        start: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: BronzColors.sale, borderRadius: BorderRadius.circular(20)),
                          child: Text('−$off%',
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    if (_p.images.length > 1)
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _p.images.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _image ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _image ? BronzColors.ink : const Color(0xFFD6D0C7),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_p.brand.isNotEmpty) ...[
                  Text(_p.brand,
                      style: const TextStyle(color: BronzColors.gold, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 4),
                ],
                if (ready)
                  Text(_p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.4))
                else
                  Container(
                    height: 22,
                    width: 220,
                    decoration: BoxDecoration(color: BronzColors.soft, borderRadius: BorderRadius.circular(6)),
                  ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _p.price > 0 ? formatPrice(_p.price) : '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: off != null ? BronzColors.sale : BronzColors.ink,
                      ),
                    ),
                    if (_p.oldPrice != null) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          formatPrice(_p.oldPrice!),
                          style: const TextStyle(
                            fontSize: 15,
                            color: BronzColors.muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Perk(PhosphorIcons.sealCheck(), 'أصلي 100%'),
                    _Perk(PhosphorIcons.truck(), 'شحن لكل المدن'),
                    _Perk(PhosphorIcons.lockSimple(), 'دفع آمن'),
                  ],
                ),
                const SizedBox(height: 26),
                const Text('الوصف', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (desc.isNotEmpty)
                  Text(desc, style: const TextStyle(fontSize: 14.5, height: 1.85, color: Color(0xFF3A3632)))
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
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BronzColors.line),
            boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 20, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              QtyStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
              const SizedBox(width: 10),
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
                                ? (_p.price > 0 ? 'أضف إلى السلة · ${formatPrice(_p.price * _qty)}' : 'أضف إلى السلة')
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
    );
  }
}

class _Perk extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Perk(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BronzColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: BronzColors.gold),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
