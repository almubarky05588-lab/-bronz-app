import 'package:flutter/material.dart';

import '../core/product.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/product_grid.dart';
import '../widgets/brand_icons.dart';
import 'category_screen.dart';

/// «دليل العطور»: اختر لمين (رجالي / نسائي / للجنسين) ونوع الرائحة.
class ScentFinderScreen extends StatefulWidget {
  const ScentFinderScreen({super.key});

  @override
  State<ScentFinderScreen> createState() => _ScentFinderScreenState();
}

class _Opt {
  final String label;
  final String icon; // أيقونة SVG (للروائح) — فاضية للجنس
  final List<String> terms; // كلمات البحث في المتجر
  final int? category;
  final String desc; // وصف قصير فوق النتائج
  const _Opt(this.label, this.icon, {this.terms = const [], this.category, this.desc = ''});
}

class _ScentFinderScreenState extends State<ScentFinderScreen> {
  static const _men = 636667848, _women = 2011162313, _unisex = 886820816;
  static const _perfumeCats = [_men, _women, _unisex];

  static const _genders = <_Opt>[
    _Opt('الكل', '', desc: 'كل العطور'),
    _Opt('رجالي', '', category: _men, desc: 'عطور رجالية'),
    _Opt('نسائي', '', category: _women, desc: 'عطور نسائية'),
    _Opt('للجنسين', '', category: _unisex, desc: 'عطور للجنسين'),
  ];

  static const _scents = <_Opt>[
    _Opt('كل الروائح', BrandIcons.scentAll),
    _Opt('عودي', BrandIcons.scentOud, terms: ['عود', 'oud'], desc: 'بلمسة عودية'),
    _Opt('زهري', BrandIcons.scentFloral, terms: ['ورد', 'زهر', 'ياسمين', 'rose'], desc: 'بلمسة زهرية'),
    _Opt('حلو وفانيلا', BrandIcons.scentSweet, terms: ['فانيلا', 'vanilla', 'حلو', 'كراميل'], desc: 'بلمسة حلوة وفانيلا'),
    _Opt('مسك', BrandIcons.scentMusk, terms: ['مسك', 'musk'], desc: 'بلمسة مسك'),
    _Opt('فريش', BrandIcons.scentFresh, terms: ['فريش', 'منعش', 'حمضي', 'ليمون', 'بحري', 'fresh'], desc: 'بلمسة فريش ومنعشة'),
    _Opt('خشبي', BrandIcons.scentWoody, terms: ['خشب', 'صندل', 'عنبر', 'amber', 'wood'], desc: 'بلمسة خشبية وعنبرية'),
  ];

  int _g = 0, _s = 0;

  // أرقام منتجات كل قسم عطور (تُحمّل مرة وحدة)
  static final _catIds = <int, Future<Set<int>>>{};

  static Future<Set<int>> _idsOf(int cat) => _catIds[cat] ??= () async {
        final ids = <int>{};
        for (var p = 1; p <= 12; p++) {
          final l = await StoreApi.byCategory(cat, page: p);
          if (l.isEmpty) break;
          final before = ids.length;
          ids.addAll(l.map((e) => e.id));
          if (ids.length == before) break;
        }
        if (ids.isEmpty) _catIds.remove(cat); // نعيد المحاولة المرة الجاية
        return ids;
      }();

  /// كل الأقسام معًا بالتناوب (لما ما يختار رائحة)
  Future<List<Product>> _mixed(List<int> cats, int page) async {
    final lists = await Future.wait(cats.map((c) => StoreApi.byCategory(c, page: page).catchError((_) => <Product>[])));
    final out = <Product>[];
    final n = lists.fold<int>(0, (m, l) => l.length > m ? l.length : m);
    for (var i = 0; i < n; i++) {
      for (final l in lists) {
        if (i < l.length) out.add(l[i]);
      }
    }
    return out;
  }

  /// بحث بكلمات الرائحة، ثم تصفية حسب الجنس (أو أقسام العطور كلها).
  Future<List<Product>> _byScent(_Opt scent, int? cat) async {
    final results = await Future.wait([
      for (final t in scent.terms)
        for (var p = 1; p <= 2; p++) StoreApi.search(t, page: p).catchError((_) => <Product>[]),
    ]);
    final cats = cat != null ? [cat] : _perfumeCats;
    final allowed = <int>{};
    for (final s in await Future.wait(cats.map(_idsOf))) {
      allowed.addAll(s);
    }
    final seen = <int>{};
    final out = <Product>[];
    for (final l in results) {
      for (final p in l) {
        if (allowed.isNotEmpty && !allowed.contains(p.id)) continue;
        if (seen.add(p.id)) out.add(p);
      }
    }
    // المتوفّر أول
    out.sort((a, b) => (b.available ? 1 : 0) - (a.available ? 1 : 0));
    return out;
  }

  Future<List<Product>> _load(int page) {
    final g = _genders[_g], s = _scents[_s];
    if (s.terms.isEmpty) {
      return g.category != null ? StoreApi.byCategory(g.category!, page: page) : _mixed(_perfumeCats, page);
    }
    // نتائج الرائحة تجي كلها بالصفحة الأولى
    return page > 1 ? Future.value(const <Product>[]) : _byScent(s, g.category);
  }

  /// شريط «لمين العطر؟»
  Widget _segment() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF3F1EC), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          for (var i = 0; i < _genders.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _g = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == _g ? BronzColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: i == _g
                        ? const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))]
                        : null,
                  ),
                  child: Text(
                    _genders[i].label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: i == _g ? Colors.white : const Color(0xFF6E6A63),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// مربعات الروائح
  Widget _scentTiles() {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _scents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final on = i == _s;
          return GestureDetector(
            onTap: () => setState(() => _s = i),
            child: SizedBox(
              width: 74,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 74,
                    height: 74,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? const Color(0xFFFBF4E6) : const Color(0xFFF7F5F0),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: on ? const Color(0xFFC9A35A) : Colors.transparent, width: 1.6),
                    ),
                    child: AnimatedScale(
                      scale: on ? 1.08 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: BIcon(_scents[i].icon, size: 36),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _scents[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: on ? BronzColors.ink : const Color(0xFF4A4741),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8A867E))),
      );

  String get _desc {
    final g = _genders[_g].desc, s = _scents[_s].desc;
    return s.isEmpty ? g : '$g $s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BronzHeader(title: 'دليل العطور'),
            _label('العطر لمين؟'),
            _segment(),
            _label('وش الرائحة اللي تحبها؟'),
            _scentTiles(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _desc,
                  key: ValueKey(_desc),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8A867E)),
                ),
              ),
            ),
            Expanded(
              child: ProductGrid(
                key: ValueKey('$_g-$_s'),
                loader: _load,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة الدخول لدليل العطور (في الأقسام والبحث).
class ScentFinderCard extends StatelessWidget {
  final EdgeInsetsGeometry margin;
  const ScentFinderCard({super.key, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScentFinderScreen())),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1C1A17), Color(0xFF3A3123)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x24C9A35A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const BIcon(BrandIcons.bottleGold, size: 32),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('دليل العطور',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('اختر عطرك حسب الرائحة',
                        style: TextStyle(color: Color(0xFFD9C7A0), fontSize: 12.5)),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: Color(0xFFC9A35A), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_left_rounded, color: BronzColors.ink, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
