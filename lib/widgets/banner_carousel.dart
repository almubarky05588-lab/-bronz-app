import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/catalog.dart';
import '../core/product.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../screens/category_screen.dart';
import '../screens/product_screen.dart';

/// يفتح رابطًا من روابط المتجر داخل التطبيق (منتج / قسم / العروض).
void openStoreLink(BuildContext context, String? link) {
  if (link == null || link.isEmpty) return;
  final nav = Navigator.of(context);
  final product = RegExp(r'/p(\d+)(?:$|[/?#])').firstMatch(link);
  if (product != null) {
    final id = int.parse(product.group(1)!);
    nav.push(MaterialPageRoute(builder: (_) => ProductScreen(product: Product.stub(id))));
    return;
  }
  final cat = RegExp(r'/category/([A-Za-z0-9]+)').firstMatch(link);
  if (cat != null) {
    final id = categorySlugs[cat.group(1)!];
    final c = id == null ? null : findCategory(id);
    if (c != null) {
      nav.push(MaterialPageRoute(builder: (_) => CategoryScreen(category: c)));
      return;
    }
  }
  if (link.contains('/offers')) {
    nav.push(MaterialPageRoute(
      builder: (_) => ProductListScreen(title: 'العروض', loader: (p) => StoreApi.offers(page: p)),
    ));
  }
}

/// بانرات رئيسية المتجر — بنفس أبعادها الحقيقية (بدون قص)، تتقلّب كل 4 ثوانٍ.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _pc = PageController();
  List<StoreBanner>? _items;
  double _ratio = 2.0;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// يقرأ أبعاد أول بانر الحقيقية حتى يُعرض كاملًا بدون قص.
  Future<double> _ratioOf(String url) {
    final c = Completer<double>();
    final stream = CachedNetworkImageProvider(url).resolve(const ImageConfiguration());
    late final ImageStreamListener l;
    l = ImageStreamListener(
      (info, _) {
        if (!c.isCompleted && info.image.height > 0) {
          c.complete(info.image.width / info.image.height);
        }
        stream.removeListener(l);
      },
      onError: (_, __) {
        if (!c.isCompleted) c.complete(2.0);
        stream.removeListener(l);
      },
    );
    stream.addListener(l);
    return c.future.timeout(const Duration(seconds: 8), onTimeout: () => 2.0);
  }

  Future<void> _load() async {
    List<StoreBanner> list;
    try {
      list = await StoreApi.banners();
    } catch (_) {
      list = const [];
    }
    var ratio = 2.0;
    if (list.isNotEmpty) {
      ratio = (await _ratioOf(list.first.image)).clamp(1.1, 3.4).toDouble();
    }
    if (!mounted) return;
    setState(() {
      _items = list;
      _ratio = ratio;
    });
    _timer?.cancel();
    if (list.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_pc.hasClients) return;
        final next = (_index + 1) % list.length;
        _pc.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
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
    final items = _items;
    if (items == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AspectRatio(
          aspectRatio: 2.0,
          child: Container(
            decoration: BoxDecoration(color: BronzColors.tile, borderRadius: BorderRadius.circular(BronzRadius.hero)),
          ),
        ),
      );
    }
    if (items.isEmpty) return const _FallbackHero();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BronzRadius.hero),
            child: AspectRatio(
              aspectRatio: _ratio,
              child: PageView.builder(
                controller: _pc,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => openStoreLink(context, items[i].link),
                  child: CachedNetworkImage(
                    imageUrl: items[i].image,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (_, __) => const ColoredBox(color: BronzColors.tile),
                    errorWidget: (_, __, ___) => const ColoredBox(color: BronzColors.tile),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? BronzColors.ink : BronzColors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FallbackHero extends StatelessWidget {
  const _FallbackHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BronzRadius.hero),
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF2A2A2A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('عطور أصلية 100%',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('أشهر الماركات العالمية بضمان متجر برونز\nوشحن سريع لجميع مدن السعودية',
              style: TextStyle(color: BronzColors.goldSoft, height: 1.5)),
        ],
      ),
    );
  }
}
