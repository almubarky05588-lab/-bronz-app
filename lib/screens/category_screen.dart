import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/catalog.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/product_grid.dart';
import 'search_screen.dart';

/// رأس الصفحات الداخلية (تصميم v2): رجوع · العنوان · بحث.
class BronzHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool search;
  const BronzHeader({super.key, required this.title, this.subtitle, this.search = true});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          if (canPop)
            RoundIcon(icon: PhosphorIcons.caretRight(), onTap: () => Navigator.of(context).maybePop())
          else
            const SizedBox(width: 42),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(fontSize: 12, color: BronzColors.muted)),
              ],
            ),
          ),
          if (search)
            RoundIcon(
              icon: PhosphorIcons.magnifyingGlass(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen(autofocus: true)),
              ),
            )
          else
            const SizedBox(width: 42),
        ],
      ),
    );
  }
}

class CategoryScreen extends StatefulWidget {
  final StoreCategory category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late int _selected = widget.category.id;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BronzHeader(title: c.name),
            if (c.children.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                  children: [
                    _chip('الكل', c.id),
                    for (final s in c.children) _chip(s.name, s.id),
                  ],
                ),
              ),
            Expanded(
              child: ProductGrid(
                key: ValueKey(_selected),
                loader: (p) => StoreApi.byCategory(_selected, page: p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int id) {
    final on = _selected == id;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: () {
          if (on) return;
          HapticFeedback.selectionClick();
          setState(() => _selected = id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? BronzColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? BronzColors.ink : BronzColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              color: on ? Colors.white : BronzColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// قائمة منتجات عامة بعنوان (العروض، وصل حديثًا…)
class ProductListScreen extends StatelessWidget {
  final String title;
  final PageLoader loader;
  const ProductListScreen({super.key, required this.title, required this.loader});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BronzHeader(title: title),
            Expanded(child: ProductGrid(loader: loader)),
          ],
        ),
      ),
    );
  }
}
