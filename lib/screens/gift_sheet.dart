import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/cart.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../core/util.dart';
import '../widgets/common.dart';

/// شاشة «أرسله كهدية»: يختار العميل باقة التغليف (الورد والشوكولاتة للرياض فقط)
/// ويكتب بيانات المستلم ورسالته، وتتضاف الخدمة للسلة بسعرها.
class GiftSheet extends StatefulWidget {
  const GiftSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const GiftSheet(),
      );

  @override
  State<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends State<GiftSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _msg = TextEditingController();
  bool _riyadh = true;
  int _choice = giftWrapId;
  bool _saving = false;

  // الأسعار الافتراضية — تُحدَّث من المتجر عند الفتح
  final _packs = <int, _PackInfo>{
    giftWrapId: _PackInfo(giftWrapId, 'تغليف هدية فاخر', 70, ''),
    giftFlowersId: _PackInfo(giftFlowersId, 'تغليف هدية + ورد وشوكولاتة', 150, ''),
  };

  @override
  void initState() {
    super.initState();
    final cart = Cart.instance;
    final g = cart.gift;
    if (g != null) _choice = g.id;
    // استرجاع البيانات المحفوظة
    final parts = cart.giftNote.split('\n');
    for (final p in parts) {
      if (p.startsWith('المستلم: ')) _name.text = p.substring(9);
      if (p.startsWith('جوال المستلم: ')) _phone.text = p.substring(14);
      if (p.startsWith('رسالة الإهداء: ')) _msg.text = p.substring(15);
      if (p.contains('خارج الرياض')) _riyadh = false;
    }
    for (final id in giftProductIds) {
      StoreApi.details(id).then((p) {
        if (mounted && p.price > 0) setState(() => _packs[id] = _PackInfo(id, p.name, p.price, p.image));
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _msg.dispose();
    super.dispose();
  }

  String get _note => [
        '🎁 طلب هدية — ${_packs[_choice]?.name ?? ''}',
        'التوصيل: ${_riyadh ? 'داخل الرياض' : 'خارج الرياض'}',
        'المستلم: ${_name.text.trim()}',
        'جوال المستلم: ${_phone.text.trim()}',
        if (_msg.text.trim().isNotEmpty) 'رسالة الإهداء: ${_msg.text.trim()}',
      ].join('\n');

  void _save() {
    if (_name.text.trim().isEmpty || StoreApi.normalizePhone(_phone.text).length < 9) {
      showBronzToast(context, 'اكتب اسم المستلم ورقم جواله', icon: Icons.info_outline_rounded);
      return;
    }
    setState(() => _saving = true);
    final p = _packs[_choice]!;
    Cart.instance.setGift(CartItem(id: p.id, name: '🎁 ${p.name}', image: p.image, price: p.price, qty: 1), _note);
    Navigator.of(context).pop();
  }

  void _removeGift() {
    Cart.instance.setGift(null, '');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_riyadh && _choice == giftFlowersId) _choice = giftWrapId;
    final hasGift = Cart.instance.hasGift;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: BronzColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: BronzColors.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  const Text('أرسله كهدية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (hasGift)
                    TextButton(
                      onPressed: _removeGift,
                      child: const Text('إلغاء الهدية', style: TextStyle(color: BronzColors.sale, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('نغلّف طلبك بشكل فاخر ونوصّله للمستلم مع رسالتك',
                  style: TextStyle(color: BronzColors.muted, fontSize: 13)),
              const SizedBox(height: 18),

              // ─── التوصيل داخل الرياض؟ ───
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: BronzColors.tile, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.mapPin(), size: 20, color: BronzColors.ink),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('التوصيل داخل الرياض؟', style: TextStyle(fontWeight: FontWeight.w700))),
                    Switch.adaptive(
                      value: _riyadh,
                      activeColor: BronzColors.ink,
                      onChanged: (v) => setState(() => _riyadh = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ─── الباقات ───
              _Pack(
                title: _packs[giftWrapId]!.name,
                sub: 'علبة فاخرة وشريط برونز',
                price: _packs[giftWrapId]!.price,
                icon: PhosphorIcons.gift(),
                selected: _choice == giftWrapId,
                onTap: () => setState(() => _choice = giftWrapId),
              ),
              const SizedBox(height: 10),
              if (_riyadh)
                _Pack(
                  title: _packs[giftFlowersId]!.name,
                  sub: 'تغليف فاخر + باقة ورد + شوكولاتة',
                  price: _packs[giftFlowersId]!.price,
                  icon: PhosphorIcons.flower(),
                  selected: _choice == giftFlowersId,
                  onTap: () => setState(() => _choice = giftFlowersId),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('باقة الورد والشوكولاتة متاحة للتوصيل داخل الرياض فقط',
                      style: TextStyle(color: BronzColors.muted, fontSize: 12.5)),
                ),
              const SizedBox(height: 18),

              // ─── المستلم ───
              const Text('بيانات المستلم', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: _field('اسم المستلم'),
              ),
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(14)],
                  decoration: _field('5XXXXXXXX').copyWith(prefixText: '+966  '),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _msg,
                maxLines: 3,
                maxLength: 200,
                decoration: _field('رسالة الإهداء (اختياري) — تُكتب في البطاقة'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  '${hasGift ? 'تحديث الهدية' : 'إضافة الهدية'} · ${formatPrice(_packs[_choice]!.price)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BronzColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BronzColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BronzColors.ink, width: 1.4)),
      );
}

class _PackInfo {
  final int id;
  final String name;
  final double price;
  final String image;
  const _PackInfo(this.id, this.name, this.price, this.image);
}

class _Pack extends StatelessWidget {
  final String title;
  final String sub;
  final double price;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _Pack({
    required this.title,
    required this.sub,
    required this.price,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? BronzColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? BronzColors.ink : BronzColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.14) : BronzColors.tile,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: selected ? Colors.white : BronzColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800, color: selected ? Colors.white : BronzColors.ink)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 12, color: selected ? Colors.white70 : BronzColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(formatPrice(price),
                style: TextStyle(fontWeight: FontWeight.w800, color: selected ? BronzColors.goldSoft : BronzColors.ink)),
          ],
        ),
      ),
    );
  }
}
