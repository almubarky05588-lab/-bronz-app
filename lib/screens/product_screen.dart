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

  void _add() {
    Cart.instance.add(_p, qty: _qty);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('أُضيف إلى السلة'),
        action: SnackBarAction(
          label: 'السلة',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final desc = stripHtml(_p.description);
    return Scaffold(
      appBar: AppBar(
        actions: [
          ListenableBuilder(
            listenable: Cart.instance,
            builder: (context, _) => IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
              icon: Badge(
                isLabelVisible: Cart.instance.count > 0,
                label: Text('${Cart.instance.count}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: PageView.builder(
              itemCount: _p.images.isEmpty ? 1 : _p.images.length,
              onPageChanged: (i) => setState(() => _image = i),
              itemBuilder: (_, i) => NetImage(_p.images.isEmpty ? _p.image : _p.images[i]),
            ),
          ),
          if (_p.images.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_p.name, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.35)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(formatPrice(_p.price),
                        style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    if (_p.oldPrice != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        formatPrice(_p.oldPrice!),
                        style: t.bodyLarge?.copyWith(
                          color: BronzColors.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: BronzColors.gold),
                    SizedBox(width: 6),
                    Text('أصلي 100% بضمان متجر برونز'),
                  ],
                ),
                const Divider(height: 32),
                Text('الوصف', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (desc.isNotEmpty)
                  Text(desc, style: t.bodyMedium?.copyWith(height: 1.7))
                else if (_loadingDetails)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  const Text('لا يوجد وصف', style: TextStyle(color: BronzColors.muted)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              QtyStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _p.available ? _add : null,
                  child: Text(_p.available ? 'أضف إلى السلة' : 'نفدت الكمية'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
