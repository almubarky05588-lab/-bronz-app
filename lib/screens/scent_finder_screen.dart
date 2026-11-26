import 'package:flutter/material.dart';

import '../core/product.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/product_grid.dart';
import 'category_screen.dart';

/// «دليل العطور»: اختر لمين (رجالي / نسائي / للجنسين) ونوع الرائحة.
class ScentFinderScreen extends StatefulWidget {
  const ScentFinderScreen({super.key});

  @override
  State<ScentFinderScreen> createState() => _ScentFinderScreenState();
}

class _Opt {
  final String label;
  final String emoji;
  final List<String> terms; // كلمات البحث في المتجر
  final int? category;
  const _Opt(this.label, this.emoji, {this.terms = const [], this.category});
}

class _ScentFinderScreenState extends State<ScentFinderScreen> {
  static const _men = 636667848, _women = 2011162313, _unisex = 886820816;
  static const _perfumeCats = [_men, _women, _unisex];

  static const _genders = <_Opt>[
    _Opt('الكل', '✨'),
    _Opt('رجالي', '🤵', category: _men),
    _Opt('نسائي', '💃', category: _women),
    _Opt('للجنسين', '🤝', category: _unisex),
  ];

  static const _scents = <_Opt>[
    _Opt('كل الروائح', '🌈'),
    _Opt('عودي', '🪵', terms: ['عود', 'oud']),
    _Opt('زهري', '🌸', terms: ['ورد', 'زهر', 'ياسمين', 'rose']),
    _Opt('حلو وفانيلا', '🍬', terms: ['فانيلا', 'vanilla', 'حلو', 'كراميل']),
    _Opt('مسك', '🤍', terms: ['مسك', 'musk']),
    _Opt('فريش ومنعش', '🍋', terms: ['فريش', 'منعش', 'حمضي', 'ليمون', 'بحري', 'fresh']),
    _Opt('خشبي وعنبري', '🌲', terms: ['خشب', 'صندل', 'عنبر', 'amber', 'wood']),
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

  Widget _chips(List<_Opt> opts, int sel, ValueChanged<int> pick) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: opts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = i == sel;
          return GestureDetector(
            onTap: () => setState(() => pick(i)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? BronzColors.ink : Colors.white,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: on ? BronzColors.ink : BronzColors.line),
              ),
              child: Text(
                '${opts[i].emoji}  ${opts[i].label}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : BronzColors.ink,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: BronzColors.muted)),
      );

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
            _chips(_genders, _g, (i) => _g = i),
            _label('وش الرائحة اللي تحبها؟'),
            _chips(_scents, _s, (i) => _s = i),
            const SizedBox(height: 10),
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
          child: const Row(
            children: [
              Text('🧭', style: TextStyle(fontSize: 30)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('دليل العطور',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('اختر عطرك حسب الرائحة: عودي، زهري، مسك…',
                        style: TextStyle(color: Color(0xFFD9C7A0), fontSize: 12.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: Color(0xFFC9A35A), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
