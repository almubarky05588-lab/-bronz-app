import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/catalog.dart';
import '../core/theme.dart';
import '../widgets/category_cover.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'category_screen.dart';
import 'search_screen.dart';

/// الأقسام — بطاقات رمادية فاتحة بصورة القسم والاسم تحتها (تصميم v2).
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Row(
                  children: [
                    const Text('الأقسام', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    RoundIcon(
                      icon: PhosphorIcons.magnifyingGlass(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchScreen(autofocus: true)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: allCategories.length,
                itemBuilder: (context, i) {
                  final c = allCategories[i];
                  return FadeSlideIn(
                    order: i ~/ 2,
                    child: Pressable(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CategoryScreen(category: c)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: BronzColors.tile,
                          borderRadius: BorderRadius.circular(BronzRadius.card),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: CategoryCover(categoryId: c.id, padding: 16)),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 12, 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Icon(PhosphorIcons.caretLeft(), size: 16, color: BronzColors.muted),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
