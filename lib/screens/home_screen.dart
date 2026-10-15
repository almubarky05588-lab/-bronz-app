import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/catalog.dart';
import '../core/remote_config.dart';
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

  void _openLatest(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductListScreen(title: 'وصل حديثًا', loader: (p) => StoreApi.latest(page: p)),
      ));

  void _openOffers(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductListScreen(title: 'العروض', loader: (p) => StoreApi.offers(page: p)),
      ));

  StoreCategory _category(HomeItem item) =>
      findCategory(item.id!) ?? StoreCategory(item.id!, item.label, Icons.category_outlined);

  /// الترتيب الافتراضي لو ما وصلت إعدادات اللوحة بعد.
  static final _defaultCircles = <HomeItem>[
    const HomeItem(type: 'offers'),
    const HomeItem(type: 'latest'),
    for (final c in allCategories) HomeItem(type: 'category', id: c.id),
  ];

  static final _defaultRails = <HomeItem>[
    const HomeItem(type: 'latest'),
    const HomeItem(type: 'offers', label: 'أقوى العروض 🔥'),
    for (final c in homeSections) HomeItem(type: 'category', id: c.id),
  ];

  List<Widget> _circles(BuildContext context, AppConfig? cfg) {
    final items = (cfg == null || cfg.circles.isEmpty) ? _defaultCircles : cfg.circles;
    final out = <Widget>[];
    for (final it in items) {
      if (it.hidden || (it.type != 'offers' && it.type != 'latest' && it.id == null)) continue;
      switch (it.type) {
        case 'offers':
          out.add(_Circle(
            label: it.label.isEmpty ? 'العروض' : it.label,
            icon: PhosphorIcons.percent(PhosphorIconsStyle.bold),
            image: it.image,
            dark: true,
            onTap: () => _openOffers(context),
          ));
        case 'latest':
          out.add(_Circle(
            label: it.label.isEmpty ? 'وصل حديثًا' : it.label,
            icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
            image: it.image,
            onTap: () => _openLatest(context),
          ));
        default:
          final c = _category(it);
          out.add(_Circle(
            label: it.label.isEmpty ? c.name : it.label,
            categoryId: c.id,
            image: it.image,
            onTap: () => _open(context, c),
          ));
      }
    }
    return out;
  }

  List<Widget> _rails(BuildContext context, AppConfig? cfg) {
    final items = (cfg == null || cfg.rails.isEmpty) ? _defaultRails : cfg.rails;
    final out = <Widget>[];
    var order = 4;
    for (final it in items) {
      if (it.hidden || (it.type != 'offers' && it.type != 'latest' && it.id == null)) continue;
      Widget rail;
      switch (it.type) {
        case 'latest':
          rail = ProductRail(
            title: it.label.isEmpty ? 'وصل حديثًا' : it.label,
            loader: () => StoreApi.latest(),
            onMore: () => _openLatest(context),
          );
        case 'offers':
          rail = ProductRail(
            title: it.label.isEmpty ? 'أقوى العروض 🔥' : it.label,
            loader: () => StoreApi.offers(),
            onMore: () => _openOffers(context),
          );
        default:
          final c = _category(it);
          rail = ProductRail(
            title: it.label.isEmpty ? c.name : it.label,
            loader: () => StoreApi.byCategory(c.id),
            onMore: () => _open(context, c),
          );
      }
      out.add(FadeSlideIn(key: ValueKey('${it.type}-${it.id}'), order: order++, child: rail));
    }
    return out;
  }

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
            // ─── دوائر الأقسام + صفوف المنتجات (تُدار من لوحة برونز) ───
            ValueListenableBuilder<AppConfig?>(
              valueListenable: RemoteConfig.instance.config,
              builder: (context, cfg, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                    order: 3,
                    child: SizedBox(
                      height: 112,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: _circles(context, cfg),
                      ),
                    ),
                  ),
                  ..._rails(context, cfg),
                ],
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
  final String image;
  final bool dark;
  final VoidCallback onTap;
  const _Circle({
    required this.label,
    required this.onTap,
    this.categoryId,
    this.icon,
    this.image = '',
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
                  child: image.isNotEmpty
                      ? NetImage(image, padding: 10, background: Colors.white)
                      : categoryId != null
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
