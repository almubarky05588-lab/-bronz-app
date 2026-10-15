import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/catalog.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_cover.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/product_rail.dart';
import 'category_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, StoreCategory c) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryScreen(category: c)));
  }

  void _openList(BuildContext context, String title, Future<List<dynamic>> Function(int) _) {}

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 12) return 'صباح الخير ☀️';
    return 'مساء الخير ✨';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ─── الرأس: الشعار + التحية + الإشعارات ───
            FadeSlideIn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BronzLogo(width: 118),
                        Text(
                          '${_greeting()}  وش عطرك اليوم؟',
                          style: const TextStyle(fontSize: 13, color: BronzColors.muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Spacer(),
                    RoundIcon(
                      icon: PhosphorIcons.bell(),
                      onTap: () => showBronzToast(
                        context,
                        'لا توجد إشعارات جديدة',
                        icon: PhosphorIcons.bellSimple(PhosphorIconsStyle.fill),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ─── شريط البحث ───
            FadeSlideIn(
              order: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Pressable(
                  scale: 0.98,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen(autofocus: true)),
                  ),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: BronzColors.line),
                      boxShadow: const [
                        BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.magnifyingGlass(), size: 21, color: BronzColors.muted),
                        const SizedBox(width: 10),
                        const Text('ابحث عن عطر، ماركة، أو منتج…',
                            style: TextStyle(color: BronzColors.muted, fontSize: 14.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ─── البانرات ───
            const FadeSlideIn(order: 2, child: BannerCarousel()),
            const SizedBox(height: 18),
            // ─── شريط الميزات المتحرك ───
            Container(
              color: BronzColors.ink,
              child: Marquee(
                height: 38,
                children: [
                  _MarqueeItem(PhosphorIcons.sealCheck(), 'أصلي 100% بضمان برونز'),
                  _MarqueeItem(PhosphorIcons.truck(), 'شحن سريع لكل مدن المملكة'),
                  _MarqueeItem(PhosphorIcons.lock(), 'دفع آمن وموثوق'),
                  _MarqueeItem(PhosphorIcons.sparkle(), 'أشهر الماركات العالمية'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // ─── دوائر الأقسام ───
            FadeSlideIn(
              order: 3,
              child: SizedBox(
                height: 112,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _Circle(
                      label: 'العروض',
                      icon: PhosphorIcons.percent(PhosphorIconsStyle.bold),
                      dark: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProductListScreen(
                          title: 'العروض',
                          loader: (p) => StoreApi.offers(page: p),
                        ),
                      )),
                    ),
                    _Circle(
                      label: 'وصل حديثًا',
                      icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProductListScreen(
                          title: 'وصل حديثًا',
                          loader: (p) => StoreApi.latest(page: p),
                        ),
                      )),
                    ),
                    for (final c in allCategories)
                      _Circle(label: c.name, categoryId: c.id, onTap: () => _open(context, c)),
                  ],
                ),
              ),
            ),
            // ─── صفوف المنتجات ───
            FadeSlideIn(
              order: 4,
              child: ProductRail(
                title: 'وصل حديثًا',
                loader: () => StoreApi.latest(),
                onMore: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProductListScreen(
                    title: 'وصل حديثًا',
                    loader: (p) => StoreApi.latest(page: p),
                  ),
                )),
              ),
            ),
            FadeSlideIn(
              order: 5,
              child: ProductRail(
                title: 'أقوى العروض 🔥',
                loader: () => StoreApi.offers(),
                onMore: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProductListScreen(
                    title: 'العروض',
                    loader: (p) => StoreApi.offers(page: p),
                  ),
                )),
              ),
            ),
            for (var i = 0; i < homeSections.length; i++)
              FadeSlideIn(
                order: 6 + i,
                child: ProductRail(
                  title: homeSections[i].name,
                  loader: () => StoreApi.byCategory(homeSections[i].id),
                  onMore: () => _open(context, homeSections[i]),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MarqueeItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MarqueeItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: BronzColors.gold),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 18),
          const Text('✦', style: TextStyle(color: BronzColors.gold, fontSize: 10)),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final String label;
  final int? categoryId;
  final IconData? icon;
  final bool dark;
  final VoidCallback onTap;
  const _Circle({
    required this.label,
    required this.onTap,
    this.categoryId,
    this.icon,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 86,
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE9DCC6), Color(0xFFB08D57)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ClipOval(
                  child: categoryId != null
                      ? CategoryCover(categoryId: categoryId!, padding: 10)
                      : Container(
                          color: dark ? BronzColors.ink : Colors.white,
                          alignment: Alignment.center,
                          child: Icon(icon, size: 28, color: dark ? BronzColors.gold : BronzColors.ink),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
