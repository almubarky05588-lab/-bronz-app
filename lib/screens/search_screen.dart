import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/product_grid.dart';

class SearchScreen extends StatefulWidget {
  final bool autofocus;
  const SearchScreen({super.key, this.autofocus = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  static const _suggestions = ['جيرلان', 'كارولينا هيريرا', 'بربري', 'عود', 'أحمر شفاه', 'مسك'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search(String v) => setState(() => _query = v.trim());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(end: 16),
          child: TextField(
            controller: _ctrl,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'ابحث عن عطر أو ماركة…',
              hintStyle: const TextStyle(color: BronzColors.muted),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 20, color: BronzColors.muted),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: BronzColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: BronzColors.ink),
              ),
            ),
            onSubmitted: _search,
          ),
        ),
      ),
      body: _query.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('عمليات بحث شائعة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _suggestions)
                      GestureDetector(
                        onTap: () {
                          _ctrl.text = s;
                          _search(s);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: BronzColors.line),
                          ),
                          child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ],
            )
          : ProductGrid(
              key: ValueKey(_query),
              loader: (p) => StoreApi.search(_query, page: p),
            ),
    );
  }
}

// للتوافق: شاشة فاضية تُعرض إن لم توجد نتائج
class SearchEmpty extends StatelessWidget {
  const SearchEmpty({super.key});
  @override
  Widget build(BuildContext context) =>
      EmptyView(icon: PhosphorIcons.magnifyingGlass(), message: 'اكتب اسم العطر أو الماركة');
}
