import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/catalog.dart';
import '../core/push.dart';
import '../core/product.dart';
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

  void _openList(BuildContext context, String title, Future<List<Product>> Function({int page}) source) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductListScreen(title: title, loader: (p) => source(page: p)),
      ));

  static const _specialName = {
    'offers': 'العروض',
    'latest': 'وصل حديثًا',
    'best': 'الأكثر مبيعًا',
    'rated': 'الأعلى تقييمًا',
  };

  /// الترتيب الافتراضي لو ما وصلت إعدادات اللوحة بعد.
  static final _defaultBlocks = <HomeBlock>[
    const HomeBlock(type: 'banners'),
    const HomeBlock(type: 'features'),
    HomeBlock(type: 'circles', items: [
      const IconItem(link: LinkTarget('offers')),
      const IconItem(link: LinkTarget('latest')),
      for (final c in allCategories) IconItem(link: LinkTarget('category', '${c.id}')),
    ]),
    const HomeBlock(type: 'products', source: 'latest'),
    const HomeBlock(type: 'products', source: 'best', title: 'الأكثر مبيعًا ⭐'),
    const HomeBlock(type: 'products', source: 'offers', title: 'أقوى العروض 🔥', style: 'grid', limit: 6),
    for (final c in homeSections) HomeBlock(type: 'products', source: 'category', id: c.id),
  ];

  List<Widget> _blocks(BuildContext context, AppConfig? cfg) {
    final blocks = (cfg == null || cfg.blocks.isEmpty) ? _defaultBlocks : cfg.blocks;
    final out = <Widget>[];
    var order = 2;
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      if (b.hidden) continue;
      final Widget? w = switch (b.type) {
        'banners' => const Padding(padding: EdgeInsets.only(bottom: 18), child: BannerCarousel()),
        'features' => const Padding(padding: EdgeInsets.only(bottom: 18), child: _Features()),
        'circles' => _iconsBlock(context, b),
        'products' => _productsBlock(context, b),
        _ => null,
      };
      if (w == null) continue;
      out.add(FadeSlideIn(key: ValueKey('blk-$i-${b.type}'), order: order++, child: w));
    }
    return out;
  }

  // ───────── قطعة الأيقونات ─────────

  String _iconLabel(IconItem it) {
    if (it.label.isNotEmpty) return it.label;
    if (it.link.to == 'category') {
      final id = it.link.categoryId;
      return (id == null ? null : findCategory(id)?.name) ?? '';
    }
    return _specialName[it.link.to] ?? '';
  }

  Widget _circle(IconItem it) {
    final label = _iconLabel(it);
    final to = it.link.to;
    return _Circle(
      label: label,
      image: it.image,
      categoryId: to == 'category' ? it.link.categoryId : null,
      icon: switch (to) {
        'offers' => PhosphorIcons.percent(PhosphorIconsStyle.bold),
        'latest' => PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
        'best' => PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
        'rated' => PhosphorIcons.heart(PhosphorIconsStyle.fill),
        'product' => PhosphorIcons.handbag(PhosphorIconsStyle.fill),
        _ => PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
      },
      dark: to == 'offers',
      onTap: () {
        final d = it.link.data(title: label);
        if (d != null) Push.open(d);
      },
    );
  }

  Widget? _iconsBlock(BuildContext context, HomeBlock b) {
    if (b.items.isEmpty) return null;
    final tiles = [for (final it in b.items) _circle(it)];
    final Widget body;
    if (b.rows >= 3) {
      body = GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        childAspectRatio: 86 / 112,
        children: tiles,
      );
    } else if (b.rows == 2) {
      body = SizedBox(
        height: 226,
        child: GridView.count(
          crossAxisCount: 2,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          mainAxisSpacing: 0,
          crossAxisSpacing: 2,
          childAspectRatio: 112 / 86,
          children: tiles,
        ),
      );
    } else {
      body = SizedBox(
        height: 112,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          children: tiles,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (b.title.isNotEmpty) SectionHeader(title: b.title),
          body,
        ],
      ),
    );
  }

  // ───────── قطعة المنتجات ─────────

  Widget? _productsBlock(BuildContext context, HomeBlock b) {
    final String title;
    final Future<List<Product>> Function({int page}) source;
    switch (b.source) {
      case 'offers':
        title = b.title.isEmpty ? 'أقوى العروض 🔥' : b.title;
        source = StoreApi.offers;
      case 'best':
        title = b.title.isEmpty ? 'الأكثر مبيعًا ⭐' : b.title;
        source = StoreApi.bestSellers;
      case 'rated':
        title = b.title.isEmpty ? 'الأعلى تقييمًا' : b.title;
        source = StoreApi.topRated;
      case 'category':
        if (b.id == null) return null;
        final c = findCategory(b.id!) ?? StoreCategory(b.id!, b.title, Icons.category_outlined);
        title = b.title.isEmpty ? c.name : b.title;
        source = ({int page = 1}) => StoreApi.byCategory(c.id, page: page);
        return _rail(title, source, () => _open(context, c), b);
      default:
        title = b.title.isEmpty ? 'وصل حديثًا' : b.title;
        source = StoreApi.latest;
    }
    return _rail(title, source, () => _openList(context, title, source), b);
  }

  Widget _rail(String title, Future<List<Product>> Function({int page}) source, VoidCallback onMore, HomeBlock b) =>
      ProductRail(
        key: ValueKey('rail-${b.source}-${b.id}-${b.style}-${b.limit}'),
        title: title,
        grid: b.style == 'grid',
        limit: b.limit,
        loader: () => StoreApi.take((p) => source(page: p), b.limit),
        onMore: onMore,
      );

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
            // ─── قطع الرئيسية (تُدار من لوحة برونز) ───
            ValueListenableBuilder<AppConfig?>(
              valueListenable: RemoteConfig.instance.config,
              builder: (context, cfg, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _blocks(context, cfg),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    return Container(
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
