import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/cart.dart';
import '../core/catalog.dart';
import '../core/demo.dart';
import '../core/push.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/tab_icons.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'category_screen.dart';
import 'home_screen.dart';
import 'product_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (kScreenshots) {
      _tour();
    }
  }

  /// جولة تصوير المتجر — يقودها سكربت التصوير (ci/screenshots.sh) بملف خطوة
  /// داخل مجلد tmp للتطبيق: 1 الأقسام · 2 صفحة قسم · 3 صفحة منتج · 4 حسابي.
  /// كذا كل لقطة تنأخذ بعد ما تجهز شاشتها، مهما تأخر المحاكي.
  Future<void> _tour() async {
    final file = File('${Directory.systemTemp.path}/bronz_step');
    var done = 0;
    while (mounted && done < 4) {
      await Future.delayed(const Duration(seconds: 1));
      int step;
      try {
        step = int.tryParse((await file.readAsString()).trim()) ?? 0;
      } catch (_) {
        continue;
      }
      while (done < step && mounted) {
        done++;
        await _tourStep(done);
      }
    }
  }

  Future<void> _tourStep(int step) async {
    final nav = navigatorKey.currentState;
    if (nav == null || allCategories.isEmpty) return;
    final c = allCategories.first;
    switch (step) {
      case 1:
        setState(() => _index = 1);
      case 2:
        nav.push(MaterialPageRoute(builder: (_) => CategoryScreen(category: c)));
      case 3:
        try {
          final list = await StoreApi.byCategory(c.id);
          final p = list.where((x) => x.image.isNotEmpty).toList();
          if (p.isNotEmpty) nav.push(MaterialPageRoute(builder: (_) => ProductScreen(product: p.first)));
        } catch (_) {}
      case 4:
        nav.popUntil((r) => r.isFirst);
        setState(() => _index = 4);
    }
  }

  void _go(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // المحتوى يمرّ تحت الشريط العائم
      body: Builder(builder: (context) {
        // الشريط عائم فوق المحتوى: الرئيسية تمرّ تحته، وبقية التبويبات تنتهي فوقه
        final pad = EdgeInsets.only(bottom: 78 + MediaQuery.paddingOf(context).bottom);
        return IndexedStack(
          index: _index,
          children: [
            const HomeScreen(),
            const CategoriesScreen(), // تمر تحت الشريط وتضيف مسافتها بنفسها
            Padding(padding: pad, child: const _OffersTab()),
            Padding(padding: pad, child: const CartScreen()),
            Padding(padding: pad, child: const AccountScreen()),
          ],
        );
      }),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: SizedBox(
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: BronzColors.line),
                    boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8))],
                  ),
                ),
              ),
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: Cart.instance,
                  builder: (context, _) => Row(
                    children: [
                      _NavItem(label: 'الرئيسية', icon: TabIcons.home, activeIcon: TabIcons.homeOn, selected: _index == 0, onTap: () => _go(0)),
                      _NavItem(label: 'الأقسام', icon: TabIcons.cats, activeIcon: TabIcons.catsOn, selected: _index == 1, onTap: () => _go(1)),
                      _OffersItem(selected: _index == 2, onTap: () => _go(2)),
                      _NavItem(
                        label: 'سلة التسوق',
                        icon: TabIcons.bag,
                        activeIcon: TabIcons.bagOn,
                        selected: _index == 3,
                        badge: Cart.instance.count,
                        onTap: () => _go(3),
                      ),
                      _NavItem(label: 'حسابي', icon: TabIcons.user, activeIcon: TabIcons.userOn, selected: _index == 4, onTap: () => _go(4)),
                    ],
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

/// تبويب العروض — نفس قائمة المنتجات بدون زر رجوع.
class _OffersTab extends StatelessWidget {
  const _OffersTab();

  @override
  Widget build(BuildContext context) {
    return ProductListScreen(title: 'أقوى العروض 🔥', loader: (p) => StoreApi.offers(page: p));
  }
}

/// تبويب بأيقونة ملوّنة خاصة — النشط داخل خلفية كريمية ناعمة، بدون كتابة.
class _NavItem extends StatelessWidget {
  final String label;
  final String icon;
  final String activeIcon;
  final bool selected;
  final int badge;
  final VoidCallback onTap;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 58,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF6ECD6) : Colors.transparent,
                borderRadius: BorderRadius.circular(23),
              ),
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: SvgPicture.string(selected ? activeIcon : icon, key: ValueKey(selected), width: 28, height: 28),
                  ),
                  if (badge > 0)
                    PositionedDirectional(
                      top: -6,
                      start: -8,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5484D),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, height: 1)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// العروض — ختم متدرّج يطلع فوق الشريط، يكبر شوي لما يكون نشط.
class _OffersItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _OffersItem({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: 'أقوى العروض',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -30,
                child: AnimatedScale(
                  scale: selected ? 1.08 : 1,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: SvgPicture.string(TabIcons.offers, width: 66, height: 66),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
