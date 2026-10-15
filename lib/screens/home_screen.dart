import 'package:flutter/material.dart';

import '../core/catalog.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/product_rail.dart';
import 'category_screen.dart';

/// شعار برونز الأصلي مفرّغًا: الخلفية البيضاء تذوب في لون الشاشة
/// (دمج بالضرب Multiply) فلا يبقى إلا الشعار الأسود بالتاج،
/// والإطار يقص المساحة الفارغة حوله.
class BronzLogo extends StatelessWidget {
  final double width;
  const BronzLogo({super.key, this.width = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.30,
      child: ClipRect(
        child: Image.asset(
          'assets/branding/BRONZ_app_icon_4096.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          color: BronzColors.bg,
          colorBlendMode: BlendMode.multiply,
          filterQuality: FilterQuality.high,
          cacheWidth: 1024,
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, StoreCategory c) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryScreen(category: c)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Center(child: BronzLogo(width: 150)),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
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
                      style: TextStyle(color: Color(0xFFE6D9C6), height: 1.5)),
                ],
              ),
            ),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final c = allCategories[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _open(context, c),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(c.icon, color: BronzColors.ink),
                          ),
                          const SizedBox(height: 6),
                          Text(c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ProductRail(title: 'وصل حديثًا', loader: () => StoreApi.latest()),
            for (final c in homeSections)
              ProductRail(
                title: c.name,
                loader: () => StoreApi.byCategory(c.id),
                onMore: () => _open(context, c),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
