import 'package:flutter/material.dart';

import '../core/store_api.dart';
import '../core/theme.dart';
import 'common.dart';

/// صورة غلاف القسم (أول منتج فيه) — خلفية الصورة البيضاء تذوب في لون البطاقة.
class CategoryCover extends StatelessWidget {
  final int categoryId;
  final double padding;
  final Color background;
  const CategoryCover({super.key, required this.categoryId, this.padding = 8, this.background = BronzColors.tile});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: StoreApi.categoryCover(categoryId),
      builder: (context, s) {
        final url = s.data ?? '';
        if (url.isEmpty) return ColoredBox(color: background);
        return NetImage(url, padding: padding, background: background);
      },
    );
  }
}
