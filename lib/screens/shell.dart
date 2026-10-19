import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/cart.dart';
import '../core/demo.dart';
import '../core/theme.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';

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
    // جولة التصوير: الرئيسية ← الأقسام ← حسابي (توقيتها يطابق ci/screenshots.sh)
    if (kScreenshots) {
      Future.delayed(const Duration(seconds: 40), () {
        if (mounted) setState(() => _index = 1);
      });
      Future.delayed(const Duration(seconds: 55), () {
        if (mounted) setState(() => _index = 3);
      });
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
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), CategoriesScreen(), CartScreen(), AccountScreen()],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: BronzColors.bg,
          border: Border(top: BorderSide(color: BronzColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: ListenableBuilder(
              listenable: Cart.instance,
              builder: (context, _) => Row(
                children: [
                  _NavItem(
                    label: 'الرئيسية',
                    icon: PhosphorIcons.house(),
                    activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                    selected: _index == 0,
                    onTap: () => _go(0),
                  ),
                  _NavItem(
                    label: 'الأقسام',
                    icon: PhosphorIcons.squaresFour(),
                    activeIcon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                    selected: _index == 1,
                    onTap: () => _go(1),
                  ),
                  _NavItem(
                    label: 'السلة',
                    icon: PhosphorIcons.handbag(),
                    activeIcon: PhosphorIcons.handbag(PhosphorIconsStyle.fill),
                    selected: _index == 2,
                    badge: Cart.instance.count,
                    onTap: () => _go(2),
                  ),
                  _NavItem(
                    label: 'حسابي',
                    icon: PhosphorIcons.user(),
                    activeIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
                    selected: _index == 3,
                    onTap: () => _go(3),
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

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
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
    final color = selected ? BronzColors.ink : BronzColors.faint;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              backgroundColor: BronzColors.ink,
              textColor: Colors.white,
              label: Text('$badge', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(selected ? activeIcon : icon, key: ValueKey(selected), size: 24, color: color),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: color),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: selected ? 4 : 0,
              height: 4,
              decoration: const BoxDecoration(color: BronzColors.ink, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}
