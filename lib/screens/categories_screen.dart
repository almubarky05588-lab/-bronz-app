import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/catalog.dart';
import '../core/remote_config.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/category_cover.dart';
import '../widgets/motion.dart';
import 'category_screen.dart';
import 'search_screen.dart';

/// لون خاص لكل قسم (خلفية البطاقة) — صور المنتجات تذوب فيه.
const _tints = <int, Color>{
  886820816: Color(0xFFE3F0EB), // للجنسين
  1783479303: Color(0xFFF7E6DA), // عطور الجسم
  781738507: Color(0xFFF4EADA), // العود والبخور
  952945814: Color(0xFFFAE5E9), // التجميل
  1935632650: Color(0xFFFBE3E6), // أحمر الشفاه
  666982592: Color(0xFFF5EBE3), // كريم أساس
  1723150419: Color(0xFFEDEBF5), // الماسكرا
  971641143: Color(0xFFFBE7EF), // الأظافر
  1590276103: Color(0xFFEEF0F3), // أدوات المكياج
  1860677013: Color(0xFFE4EEF7), // العناية
  2020370844: Color(0xFFE9F3EE), // السيروم
  111210193: Color(0xFFEEE9FA), // عطور الشعر
  138908188: Color(0xFFF2EFE8), // عطور بديلة
  769323888: Color(0xFFE3F2F5), // العدسات
  315372818: Color(0xFFF5EEEA), // الرموش
};
const _fallbackTints = [Color(0xFFF4EADA), Color(0xFFE4EEF7), Color(0xFFFAE5E9), Color(0xFFE3F0EB), Color(0xFFEEE9FA)];

Color _tintOf(int id, int i) => _tints[id] ?? _fallbackTints[i % _fallbackTints.length];

void _openCategory(BuildContext context, StoreCategory c) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryScreen(category: c)));

void openBrand(BuildContext context, BrandInfo b) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProductListScreen(title: b.title, loader: (p) => StoreApi.byIds(b.ids, page: p)),
    ));

/// الأقسام: بطاقتين كبار (رجالي/نسائي) + الماركات + شبكة الأقسام الملوّنة.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rest = allCategories.where((c) => c.id != menPerfumes.id && c.id != womenPerfumes.id).toList();
    final bottom = 110 + MediaQuery.paddingOf(context).bottom; // مسافة الشريط العائم
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ─── العنوان + البحث
            SliverToBoxAdapter(
              child: FadeSlideIn(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الأقسام', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('اكتشف عطرك وكل ما تحتاجه', style: TextStyle(fontSize: 13, color: BronzColors.muted)),
                      const SizedBox(height: 16),
                      Pressable(
                        scale: 0.98,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SearchScreen(autofocus: true)),
                        ),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: BronzColors.soft,
                            borderRadius: BorderRadius.circular(BronzRadius.field),
                          ),
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.magnifyingGlass(), size: 20, color: BronzColors.muted),
                              const SizedBox(width: 10),
                              const Text('ابحث في الأقسام', style: TextStyle(color: BronzColors.faint, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ─── البطاقتين الكبار
            const SliverToBoxAdapter(
              child: FadeSlideIn(
                order: 1,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: SizedBox(
                    height: 250,
                    child: Row(
                      children: [
                        Expanded(child: _HeroCard(category: menPerfumes, dark: true)),
                        SizedBox(width: 12),
                        Expanded(child: _HeroCard(category: womenPerfumes, dark: false)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ─── الماركات (من لوحة برونز)
            SliverToBoxAdapter(
              child: ValueListenableBuilder<AppConfig?>(
                valueListenable: RemoteConfig.instance.config,
                builder: (context, cfg, _) {
                  final brands = cfg?.brands ?? const <BrandInfo>[];
                  if (brands.isEmpty) return const SizedBox(height: 8);
                  return FadeSlideIn(order: 2, child: _BrandsRow(brands: brands));
                },
              ),
            ),
            // ─── كل الأقسام
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Text('كل الأقسام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottom),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemCount: rest.length,
                itemBuilder: (context, i) => FadeSlideIn(
                  order: 3 + i ~/ 2,
                  child: _TintCard(category: rest[i], color: _tintOf(rest[i].id, i)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة كبيرة: رجالي (أسود فاخر مع دائرة ضوء) أو نسائي (وردي ناعم).
class _HeroCard extends StatelessWidget {
  final StoreCategory category;
  final bool dark;
  const _HeroCard({required this.category, required this.dark});

  @override
  Widget build(BuildContext context) {
    const spot = Color(0xFFEDE6DA);
    final text = dark ? Colors.white : const Color(0xFF2A181C);
    return Pressable(
      onTap: () => _openCategory(context, category),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BronzRadius.hero),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF36363A), Color(0xFF0E0E10)]
                : const [Color(0xFFFCE5E8), Color(0xFFF0BEC7)],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // صورة المنتج
            Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: Center(
                child: dark
                    ? ClipOval(
                        child: SizedBox(
                          width: 128,
                          height: 128,
                          child: CategoryCover(categoryId: category.id, padding: 16, background: spot),
                        ),
                      )
                    : SizedBox(
                        width: 140,
                        height: 140,
                        child: CategoryCover(categoryId: category.id, padding: 10, background: const Color(0xFFF8D9DE)),
                      ),
              ),
            ),
            // الاسم + زر
            PositionedDirectional(
              start: 14,
              end: 14,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('تسوّق الآن',
                            style: TextStyle(
                              color: dark ? const Color(0xFFC9A35A) : const Color(0xFF9A5A66),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFFC9A35A) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold), size: 15, color: BronzColors.ink),
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

/// بطاقة قسم بلونه الخاص — صورة كبيرة في المنتصف والاسم تحتها.
class _TintCard extends StatelessWidget {
  final StoreCategory category;
  final Color color;
  const _TintCard({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => _openCategory(context, category),
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(BronzRadius.card)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              bottom: 50,
              child: CategoryCover(categoryId: category.id, padding: 4, background: color),
            ),
            PositionedDirectional(
              start: 14,
              end: 14,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: BronzColors.ink),
                  ),
                  const Text(
                    'تسوّق الآن',
                    style: TextStyle(fontSize: 11.5, color: BronzColors.muted, fontWeight: FontWeight.w600),
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

/// صف «تسوّق حسب الماركة» — شعار مرفوع من اللوحة، أو اسم الماركة بخط أسود.
class _BrandsRow extends StatelessWidget {
  final List<BrandInfo> brands;
  const _BrandsRow({required this.brands});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text('تسوّق حسب الماركة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BrandsScreen(brands: brands))),
                child: Row(
                  children: [
                    const Text('عرض الكل', style: TextStyle(fontSize: 13, color: BronzColors.muted)),
                    Icon(PhosphorIcons.caretLeft(), size: 14, color: BronzColors.muted),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: brands.length > 24 ? 24 : brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => BrandBadge(brand: brands[i], size: 76),
          ),
        ),
      ],
    );
  }
}

/// دائرة الماركة: الشعار (من اللوحة) أو اسم الماركة بخط صغير.
class BrandBadge extends StatelessWidget {
  final BrandInfo brand;
  final double size;
  const BrandBadge({super.key, required this.brand, this.size = 76});

  @override
  Widget build(BuildContext context) {
    final name = brand.en.isNotEmpty ? brand.en : brand.ar;
    return Pressable(
      onTap: () => openBrand(context, brand),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        // الإطار فوق المحتوى حتى لا تغطيه صورة الشعار
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: BronzColors.line, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: brand.logo.isNotEmpty
            ? Padding(
                padding: EdgeInsets.all(size * 0.1),
                child: CachedNetworkImage(
                  imageUrl: brand.logo,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 150),
                  errorWidget: (_, __, ___) => _BrandName(name: name, latin: brand.en.isNotEmpty, size: size),
                ),
              )
            : _BrandName(name: name, latin: brand.en.isNotEmpty, size: size),
      ),
    );
  }
}

/// اسم الماركة بخط صغير وثابت لكل الدوائر (سطرين كحد أقصى).
class _BrandName extends StatelessWidget {
  final String name;
  final bool latin;
  final double size;
  const _BrandName({required this.name, required this.latin, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.14),
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textDirection: latin ? TextDirection.ltr : TextDirection.rtl,
        style: TextStyle(
          fontSize: size * 0.12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          height: 1.2,
          color: BronzColors.ink,
        ),
      ),
    );
  }
}

/// كل الماركات في شبكة.
class BrandsScreen extends StatelessWidget {
  final List<BrandInfo> brands;
  const BrandsScreen({super.key, required this.brands});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الماركات')),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemCount: brands.length,
        itemBuilder: (context, i) => Column(
          children: [
            BrandBadge(brand: brands[i], size: 86),
            const SizedBox(height: 6),
            Text(
              brands[i].ar.isNotEmpty ? brands[i].ar : brands[i].en,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
