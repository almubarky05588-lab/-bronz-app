import 'package:flutter/material.dart';

import '../core/cart.dart';
import '../core/product.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../core/util.dart';
import '../widgets/common.dart';
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
    final t = Theme.of(context).textTheme;
    final desc = stripHtml(_p.description);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          ListenableBuilder(
            listenable: Cart.instance,
            builder: (context, _) => IconButton(
              onPressed: _openCart,
              icon: Badge(
                backgroundColor: BronzColors.ink,
                textColor: Colors.white,
                isLabelVisible: Cart.instance.count > 0,
                label: Text('${Cart.instance.count}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        children: [
          Container(
            color: Colors.white,
            child: AspectRatio(
              aspectRatio: 1,
              child: PageView.builder(
                itemCount: _p.images.isEmpty ? 1 : _p.images.length,
                onPageChanged: (i) => setState(() => _image = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: NetImage(_p.images.isEmpty ? _p.image : _p.images[i]),
                ),
              ),
            ),
          ),
          if (_p.images.length > 1)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 14),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_p.name, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatPrice(_p.price),
                        style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    if (_p.oldPrice != null) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          formatPrice(_p.oldPrice!),
                          style: t.bodyLarge?.copyWith(
                            color: BronzColors.muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Perk(Icons.verified_outlined, 'أصلي 100%'),
                    _Perk(Icons.local_shipping_outlined, 'شحن لكل المدن'),
                    _Perk(Icons.lock_outline_rounded, 'دفع آمن'),
                  ],
                ),
                const SizedBox(height: 24),
                Text('الوصف', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (desc.isNotEmpty)
                  Text(desc, style: t.bodyMedium?.copyWith(height: 1.8, color: const Color(0xFF3A3632)))
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: BronzColors.bg,
          border: Border(top: BorderSide(color: Color(0xFFECE7DF))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                QtyStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _p.available ? _add : null,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _justAdded
                          ? const Row(
                              key: ValueKey('added'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 20),
                                SizedBox(width: 6),
                                Text('تمت الإضافة', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              ],
                            )
                          : Text(
                              _p.available ? 'أضف إلى السلة · ${formatPrice(_p.price * _qty)}' : 'نفدت الكمية',
                              key: const ValueKey('add'),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE7DF)),
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
