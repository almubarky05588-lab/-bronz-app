import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/cart.dart';
import '../core/theme.dart';
import '../core/util.dart';
import '../widgets/common.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('السلة')),
      body: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.items.isEmpty) {
            return EmptyView(icon: PhosphorIcons.handbag(), message: 'سلتك فاضية — أضف عطرك المفضل');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final it = cart.items[i];
              return Dismissible(
                key: ValueKey(it.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => cart.remove(it.id),
                background: Container(
                  alignment: AlignmentDirectional.centerEnd,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: BronzColors.sale,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(PhosphorIcons.trash(), color: Colors.white),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: BronzColors.line),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: NetImage(it.image, padding: 8, background: BronzColors.tile),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatPrice(it.price * it.qty),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      QtyStepper(
                        value: it.qty,
                        min: 0,
                        onChanged: (v) => cart.setQty(it.id, v),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.items.isEmpty) return const SizedBox.shrink();
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: BronzColors.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('المجموع (${cart.count} منتج)', style: const TextStyle(color: BronzColors.muted)),
                      const Spacer(),
                      Text(formatPrice(cart.total), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(PhosphorIcons.truck(), size: 15, color: BronzColors.muted),
                      const SizedBox(width: 6),
                      const Text('رسوم الشحن تظهر في الخطوة التالية',
                          style: TextStyle(color: BronzColors.muted, fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.lockSimple(), size: 18),
                        const SizedBox(width: 8),
                        const Text('إتمام الطلب'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
