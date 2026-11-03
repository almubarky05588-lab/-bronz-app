import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/catalog.dart';
import '../core/demo.dart';
import '../core/product.dart';
import '../core/push.dart';
import '../core/remote_config.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_cover.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/product_rail.dart';
import 'categories_screen.dart';
import 'category_screen.dart';
import 'search_screen.dart';

/// الرئيسية — بانر بعرض الشاشة يبدأ من أعلى الشاشة، وفوقه شريط البحث والأيقونات
/// بشكل شفاف، ثم القطع اللي تُدار من «لوحة برونز».
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
    HomeBlock(type: 'circles', rows: 2, items: [
      const IconItem(link: LinkTarget('offers')),
      const IconItem(link: LinkTarget('latest')),
      for (final c in allCategories) IconItem(link: LinkTarget('category', '${c.id}')),
    ]),
    const HomeBlock(type: 'installments'),
    const HomeBlock(type: 'products', source: 'offers', title: 'أقوى العروض 🔥'),
    const HomeBlock(type: 'products', source: 'best', title: 'الأكثر مبيعًا ⭐'),
    const HomeBlock(type: 'products', source: 'latest'),
    for (final c in homeSections) HomeBlock(type: 'products', source: 'category', id: c.id),
  ];

  List<HomeBlock> _visible(AppConfig? cfg) {
    final blocks = (cfg == null || cfg.blocks.isEmpty) ? _defaultBlocks : cfg.blocks;
    return blocks.where((b) => !b.hidden).toList();
  }

  /// القطعة اللي تطلع فوق (تحت شريط البحث مباشرة): البانر الذكي أو بانرات سلة.
  static bool _isTop(HomeBlock b) => b.type == 'hero' || b.type == 'banners';

  List<Widget> _blocks(BuildContext context, List<HomeBlock> blocks) {
    final out = <Widget>[];
    var order = 1;
    var installments = false;
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final Widget? w = switch (b.type) {
        'hero' => _HeroCarousel(slides: b.slides, embedded: true),
        'banners' => const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 16), child: BannerCarousel()),
        'features' => const Padding(padding: EdgeInsets.only(bottom: 14), child: _Features()),
        'circles' => _iconsBlock(context, b),
        'installments' => const _Installments(),
        'products' => _productsBlock(context, b),
        _ => null,
      };
      if (w == null) continue;
      out.add(FadeSlideIn(key: ValueKey('blk-$i-${b.type}'), order: order++, child: w));
      // شريط التقسيط يطلع مرة وحدة بعد أول قطعة أيقونات (لو ما أضافه من اللوحة)
      if (b.type == 'installments') installments = true;
      if (b.type == 'circles' && !installments && !blocks.any((x) => x.type == 'installments')) {
        installments = true;
        out.add(FadeSlideIn(key: const ValueKey('blk-installments'), order: order++, child: const _Installments()));
      }
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
      text: switch (to) {
        'offers' => '%',
        'latest' => 'وصــل\nحديثًا',
        'best' => 'الأكثر\nمبيعًا',
        'rated' => 'الأعلى\nتقييمًا',
        _ => null,
      },
      onTap: () {
        final d = it.link.data(title: label);
        if (d != null) Push.open(d);
      },
    );
  }

  Widget? _iconsBlock(BuildContext context, HomeBlock b) {
    if (b.items.isEmpty) return null;
    final tiles = [for (final it in b.items) _circle(it)];
    final rows = b.rows == 1 && tiles.length > 5 ? 2 : b.rows;
    final Widget body;
    if (rows >= 3) {
      body = GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        childAspectRatio: 96 / 134,
        children: tiles,
      );
    } else if (rows == 2) {
      body = SizedBox(
        height: 270,
        child: GridView.count(
          crossAxisCount: 2,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          childAspectRatio: 134 / 100,
          children: tiles,
        ),
      );
    } else {
      body = SizedBox(
        height: 134,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          children: tiles,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<AppConfig?>(
        valueListenable: RemoteConfig.instance.config,
        builder: (context, cfg, _) {
          final blocks = _visible(cfg);
          final topIndex = blocks.indexWhere(_isTop);
          final top = topIndex == -1 ? null : blocks[topIndex];
          final rest = topIndex == -1 ? blocks : ([...blocks]..removeAt(topIndex));
          return ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              // ─── البانر بعرض الشاشة + شريط البحث فوقه ───
              Stack(
                children: [
                  if (top == null)
                    const SizedBox(height: 120)
                  else if (top.type == 'hero')
                    _HeroCarousel(slides: top.slides)
                  else
                    const _StoreBannersHero(),
                  const Positioned(left: 0, right: 0, top: 0, child: _HomeHeader()),
                ],
              ),
              const SizedBox(height: 10),
              ..._blocks(context, rest),
            ],
          );
        },
      ),
    );
  }
}

// ───────── شريط البحث والأيقونات (فوق البانر) ─────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Pressable(
                scale: 0.98,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen(autofocus: true)),
                ),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.magnifyingGlass(), size: 20, color: BronzColors.muted),
                      const SizedBox(width: 10),
                      const Text('بحث', style: TextStyle(color: BronzColors.muted, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _GlassIcon(
              icon: PhosphorIcons.squaresFour(),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
            ),
            const SizedBox(width: 10),
            _GlassIcon(
              icon: PhosphorIcons.bell(),
              onTap: () => showBronzToast(context, 'لا توجد إشعارات جديدة', icon: PhosphorIcons.bellSimple(PhosphorIconsStyle.fill)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: Icon(icon, size: 22, color: BronzColors.ink),
      ),
    );
  }
}

// ───────── البانر الذكي (يُركّب من نصوص اللوحة + صورة المنتج) ─────────

class _HeroCarousel extends StatefulWidget {
  final List<HeroSlide> slides;
  final bool embedded; // داخل القائمة (مو فوق) — أصغر وبزوايا
  const _HeroCarousel({required this.slides, this.embedded = false});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _pc = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.slides.length > 1 && !kScreenshots) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_pc.hasClients) return;
        _pc.animateToPage((_index + 1) % widget.slides.length,
            duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = widget.embedded ? w * 0.78 : w * 1.08;
    final slides = widget.slides.isEmpty ? const [HeroSlide(title: 'عطور أصلية 100%', sub: 'أشهر الماركات العالمية', big: 'برونز')] : widget.slides;
    final body = SizedBox(
      height: h,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _HeroSlideView(slide: slides[i], embedded: widget.embedded),
          ),
          if (slides.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _index ? BronzColors.ink.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
    if (!widget.embedded) return body;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ClipRRect(borderRadius: BorderRadius.circular(BronzRadius.hero), child: body),
    );
  }
}

class _HeroSlideView extends StatelessWidget {
  final HeroSlide slide;
  final bool embedded;
  const _HeroSlideView({required this.slide, required this.embedded});

  Color _bg() {
    final hex = slide.bg.replaceAll('#', '');
    if (hex.length == 6) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return const Color(0xFFEDEFF2);
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bg();
    final dark = bg.computeLuminance() < 0.4;
    final ink = dark ? Colors.white : BronzColors.ink;
    final soft = dark ? Colors.white.withValues(alpha: 0.78) : BronzColors.muted;
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: () {
        final d = slide.link.data(title: slide.title);
        if (d != null) Push.open(d);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.lerp(bg, Colors.white, dark ? 0.0 : 0.35)!, bg],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Stack(
          children: [
            // صورة المنتج — تملأ النصف الأيسر وتنزل للأسفل
            if (slide.image.isNotEmpty)
              Positioned(
                left: -w * 0.04,
                bottom: 0,
                width: w * 0.56,
                height: embedded ? w * 0.6 : w * 0.78,
                child: CachedNetworkImage(
                  imageUrl: slide.image,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  fadeInDuration: const Duration(milliseconds: 250),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            // النصوص — يمين
            Positioned(
              right: 20,
              top: embedded ? 26 : w * 0.34,
              width: w * 0.52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (slide.title.isNotEmpty)
                    Text(
                      slide.title,
                      maxLines: 3,
                      style: TextStyle(fontSize: embedded ? 24 : 30, height: 1.25, fontWeight: FontWeight.w800, color: ink),
                    ),
                  if (slide.sub.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(slide.sub, maxLines: 2, style: TextStyle(fontSize: embedded ? 14 : 17, fontWeight: FontWeight.w600, color: soft)),
                  ],
                  if (slide.big.isNotEmpty)
                    Text(
                      slide.big,
                      maxLines: 1,
                      style: TextStyle(fontSize: embedded ? 54 : 78, height: 1.1, fontWeight: FontWeight.w900, color: ink, letterSpacing: -1),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بانرات سلة بعرض الشاشة (لما يكون أول قطعة «البانرات» بدل البانر الذكي).
class _StoreBannersHero extends StatefulWidget {
  const _StoreBannersHero();

  @override
  State<_StoreBannersHero> createState() => _StoreBannersHeroState();
}

class _StoreBannersHeroState extends State<_StoreBannersHero> {
  final _pc = PageController();
  Timer? _timer;
  int _index = 0;
  List<StoreBanner> _items = const [];

  @override
  void initState() {
    super.initState();
    StoreApi.banners().then((l) {
      if (!mounted) return;
      setState(() => _items = l);
      if (l.length > 1 && !kScreenshots) {
        _timer = Timer.periodic(const Duration(seconds: 5), (_) {
          if (!mounted || !_pc.hasClients) return;
          _pc.animateToPage((_index + 1) % l.length,
              duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
        });
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = w * 1.0;
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          if (_items.isEmpty)
            const _HeroSlideView(slide: HeroSlide(title: 'عطور أصلية 100%', sub: 'أشهر الماركات العالمية بضمان برونز', big: 'برونز'), embedded: false)
          else
            PageView.builder(
              controller: _pc,
              itemCount: _items.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => openStoreLink(context, _items[i].link),
                child: CachedNetworkImage(
                  imageUrl: _items[i].image,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (_, __) => const ColoredBox(color: BronzColors.tile),
                  errorWidget: (_, __, ___) => const ColoredBox(color: BronzColors.tile),
                ),
              ),
            ),
          if (_items.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _index ? BronzColors.ink.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ───────── شريط التقسيط ─────────

class _Installments extends StatelessWidget {
  const _Installments();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'قسّم قيمة طلبك\nعلى دفعات مع',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.35),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PayPill('tabby', const Color(0xFF3BE0B3), BronzColors.ink),
              const SizedBox(height: 8),
              _PayPill('tamara', const Color(0xFFFFB3A7), BronzColors.ink),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayPill extends StatelessWidget {
  final String name;
  final Color bg;
  final Color fg;
  const _PayPill(this.name, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: fg, letterSpacing: -0.5)),
    );
  }
}

// ───────── شريط المزايا ─────────

class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BronzColors.ink,
      child: Marquee(
        height: 40,
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
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 18),
          const Text('•', style: TextStyle(color: BronzColors.goldSoft, fontSize: 12)),
        ],
      ),
    );
  }
}

// ───────── أيقونة دائرية كبيرة بصورة منتج ─────────

class _Circle extends StatelessWidget {
  final String label;
  final int? categoryId;
  final String? text;
  final String image;
  final VoidCallback onTap;
  const _Circle({
    required this.label,
    required this.onTap,
    this.categoryId,
    this.text,
    this.image = '',
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD9E5F3), width: 1.4),
                boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              clipBehavior: Clip.antiAlias,
              child: image.isNotEmpty
                  ? NetImage(image, padding: 8, background: Colors.white)
                  : categoryId != null
                      ? CategoryCover(categoryId: categoryId!, padding: 8, background: Colors.white)
                      : Center(
                          child: Text(
                            text ?? '•',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: text == '%' ? 40 : 15,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                              color: BronzColors.ink,
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
