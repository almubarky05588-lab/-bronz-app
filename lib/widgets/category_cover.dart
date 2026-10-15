import 'package:flutter/material.dart';

import '../core/store_api.dart';
import 'common.dart';

/// صورة غلاف القسم (أول منتج فيه) — على خلفية بيضاء تمامًا
/// حتى تذوب خلفية صورة المنتج البيضاء ولا يظهر مربع داخل الدائرة.
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
        if (url.isEmpty) return const ColoredBox(color: Colors.white);
        return NetImage(url, padding: padding, background: Colors.white);
      },
    );
  }
}
