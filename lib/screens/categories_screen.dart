import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/catalog.dart';
import '../core/theme.dart';
import '../widgets/category_cover.dart';
import '../widgets/motion.dart';
import 'category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأقسام')),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: BronzColors.line),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 6)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: CategoryCover(categoryId: c.id, padding: 18)),
                    Container(height: 1, color: BronzColors.line),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                            ),
                          ),
                          Icon(PhosphorIcons.caretLeft(), size: 15, color: BronzColors.muted),
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
    );
  }
}
