import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/catalog.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_cover.dart';
import '../widgets/common.dart';
import '../widgets/product_rail.dart';
import 'category_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, StoreCategory c) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryScreen(category: c)));
  }

  void _list(BuildContext context, String title, Future<List<dynamic>> Function(int) _) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ─── الرأس: الشعار + الإشعارات ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  const BronzLogo(width: 120),
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
            // ─── شريط البحث ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: GestureDetector(
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
            // ─── البانرات ───
            const BannerCarousel(),
            const SizedBox(height: 20),
            // ─── دوائر الأقسام ───
            SizedBox(
              height: 112,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
            // ─── صفوف المنتجات ───
            ProductRail(
              title: 'وصل حديثًا',
              loader: () => StoreApi.latest(),
              onMore: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProductListScreen(
                  title: 'وصل حديثًا',
                  loader: (p) => StoreApi.latest(page: p),
                ),
              )),
            ),
            ProductRail(
              title: 'أقوى العروض',
              loader: () => StoreApi.offers(),
              onMore: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProductListScreen(
                  title: 'العروض',
                  loader: (p) => StoreApi.offers(page: p),
                ),
              )),
            ),
            for (final c in homeSections)
              ProductRail(
                title: c.name,
                loader: () => StoreApi.byCategory(c.id),
                onMore: () => _open(context, c),
              ),
            const SizedBox(height: 8),
          ],
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: BronzColors.goldSoft, width: 1.4),
              ),
              child: ClipOval(
                child: categoryId != null
                    ? CategoryCover(categoryId: categoryId!, padding: 9)
                    : Container(
                        color: dark ? BronzColors.ink : Colors.white,
                        alignment: Alignment.center,
                        child: Icon(icon, size: 28, color: dark ? BronzColors.gold : BronzColors.ink),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
