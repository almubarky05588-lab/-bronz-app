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

/// بانرات رئيسية المتجر تتقلّب تلقائيًا كل 4 ثوانٍ.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _pc = PageController(viewportFraction: 0.92);
  List<StoreBanner>? _items;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<StoreBanner> list;
    try {
      list = await StoreApi.banners();
    } catch (_) {
      list = const [];
    }
    if (!mounted) return;
    setState(() => _items = list);
    _timer?.cancel();
    if (list.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_pc.hasClients) return;
        final next = (_index + 1) % list.length;
        _pc.animateToPage(next, duration: const Duration(milliseconds: 550), curve: Curves.easeInOutCubic);
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AspectRatio(
          aspectRatio: 2.05,
          child: Container(
            decoration: BoxDecoration(color: BronzColors.tile, borderRadius: BorderRadius.circular(22)),
          ),
        ),
      );
    }
    if (items.isEmpty) return const _FallbackHero();
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 2.05,
          child: PageView.builder(
            controller: _pc,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: GestureDetector(
                onTap: () => openStoreLink(context, items[i].link),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
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
          const SizedBox(height: 10),
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
                    color: i == _index ? BronzColors.ink : const Color(0xFFD6D0C7),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF3A2E22)],
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
