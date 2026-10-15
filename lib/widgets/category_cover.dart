import 'package:flutter/material.dart';

import '../core/store_api.dart';
import '../core/theme.dart';
import 'common.dart';

/// صورة غلاف القسم (أول منتج فيه) على خلفية ناعمة.
class CategoryCover extends StatelessWidget {
  final int categoryId;
  final double padding;
  const CategoryCover({super.key, required this.categoryId, this.padding = 8});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: StoreApi.categoryCover(categoryId),
      builder: (context, s) {
        final url = s.data ?? '';
        if (url.isEmpty) return const ColoredBox(color: BronzColors.tile);
        return NetImage(url, padding: padding, background: BronzColors.tile);
      },
    );
  }
}
