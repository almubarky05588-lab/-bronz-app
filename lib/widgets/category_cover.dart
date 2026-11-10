import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/store_api.dart';
import '../core/theme.dart';

/// صورة غلاف القسم — لو تعذّر تحميل صورة منتج، يجرّب صورة المنتج اللي بعده تلقائيًا.
/// خلفية الصورة البيضاء تذوب في لون البطاقة (دمج بالضرب).
class CategoryCover extends StatefulWidget {
  final int categoryId;
  final double padding;
  final Color background;
  const CategoryCover({super.key, required this.categoryId, this.padding = 8, this.background = BronzColors.tile});

  @override
  State<CategoryCover> createState() => _CategoryCoverState();
}

class _CategoryCoverState extends State<CategoryCover> {
  int _i = 0;
  bool _advancing = false;

  void _next(int count) {
    if (_advancing || _i + 1 >= count) return;
    _advancing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _i++;
        _advancing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: StoreApi.categoryCovers(widget.categoryId),
      builder: (context, s) {
        final urls = s.data ?? const <String>[];
        if (urls.isEmpty || _i >= urls.length) return ColoredBox(color: widget.background);
        final image = CachedNetworkImage(
          key: ValueKey(urls[_i]),
          imageUrl: urls[_i],
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 180),
          placeholder: (_, __) => const SizedBox.shrink(),
          errorWidget: (_, __, ___) {
            _next(urls.length);
            return const SizedBox.shrink();
          },
        );
        return Container(
          color: widget.background,
          padding: EdgeInsets.all(widget.padding),
          alignment: Alignment.center,
          child: widget.background == Colors.white
              ? image
              : ColorFiltered(colorFilter: ColorFilter.mode(widget.background, BlendMode.multiply), child: image),
        );
      },
    );
  }
}
