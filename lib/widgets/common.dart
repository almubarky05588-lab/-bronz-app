import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/theme.dart';

const splashAsset = 'assets/branding/BRONZ_splash_graphite.png';

// ───────── التنبيه الأنيق ─────────

OverlayEntry? _toastEntry;

/// تنبيه صغير أسود ينزل من أعلى الشاشة ويختفي لحاله بعد ثانيتين.
void showBronzToast(
  BuildContext context,
  String message, {
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _toastEntry?.remove();
  _toastEntry = null;
  HapticFeedback.lightImpact();

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _BronzToast(
      message: message,
      icon: icon ?? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
      actionLabel: actionLabel,
      onAction: onAction,
      onDone: () {
        if (_toastEntry == entry) {
          entry.remove();
          _toastEntry = null;
        }
      },
    ),
  );
  _toastEntry = entry;
  overlay.insert(entry);
}

class _BronzToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDone;
  const _BronzToast({
    required this.message,
    required this.icon,
    required this.onDone,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_BronzToast> createState() => _BronzToastState();
}

class _BronzToastState extends State<_BronzToast> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), _close);
  }

  Future<void> _close() async {
    _timer?.cancel();
    if (!mounted) return;
    await _a.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    final curve = CurvedAnimation(parent: _a, curve: Curves.easeOutCubic);
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(curve),
          child: GestureDetector(
            onVerticalDragEnd: (_) => _close(),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: BronzColors.ink,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (widget.actionLabel != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _close();
                          widget.onAction?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: const TextStyle(color: BronzColors.ink, fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────── الشاشة الافتتاحية داخل التطبيق ─────────

class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Image.asset(
        splashAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      ),
    );
  }
}

/// شعار برونز الأصلي (متّجه SVG بالتاج) — حاد بأي مقاس، ويتلوّن (أبيض فوق الخلفيات الداكنة).
class BronzLogo extends StatelessWidget {
  final double width;
  final Color color;
  final Color background; // للتوافق مع الاستخدامات القديمة — لم يعد مستخدمًا
  const BronzLogo({
    super.key,
    this.width = 150,
    this.color = BronzColors.ink,
    this.background = BronzColors.bg,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/branding/bronz_logo.svg',
      width: width,
      height: width * 440 / 1264,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

// ───────── عناصر عامة ─────────

class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double padding;
  final Color background;
  const NetImage(
    this.url, {
    super.key,
    this.fit = BoxFit.contain,
    this.padding = 6,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: background,
        alignment: Alignment.center,
        child: Icon(PhosphorIcons.image(), color: BronzColors.faint, size: 28),
      );
    }
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => Center(
        child: Icon(PhosphorIcons.imageBroken(), color: BronzColors.faint),
      ),
    );
    return Container(
      color: background,
      padding: EdgeInsets.all(padding),
      // خلفية صور المنتجات البيضاء تذوب في لون البطاقة (دمج بالضرب) — مثل تصميم Figma
      child: background == Colors.white
          ? image
          : ColorFiltered(colorFilter: ColorFilter.mode(background, BlendMode.multiply), child: image),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: BronzColors.soft, shape: BoxShape.circle),
              child: Icon(PhosphorIcons.wifiSlash(), size: 30, color: BronzColors.ink),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.6)),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyView({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: BronzColors.soft, shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: BronzColors.ink),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: BronzColors.muted, fontSize: 15)),
        ],
      ),
    );
  }
}

/// زر دائري أبيض بأيقونة (الإشعارات، الرجوع…)
class RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const RoundIcon({super.key, required this.icon, required this.onTap, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: BronzColors.line),
        ),
        child: Icon(icon, size: size * 0.46, color: BronzColors.ink),
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  const QtyStepper({super.key, required this.value, required this.onChanged, this.min = 1});

  Widget _btn(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: BronzColors.soft, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: onTap == null ? BronzColors.faint : BronzColors.ink),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(PhosphorIcons.plus(PhosphorIconsStyle.bold), () => onChanged(value + 1)),
        SizedBox(
          width: 30,
          child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        _btn(
          value <= 1 && min == 0 ? PhosphorIcons.trash() : PhosphorIcons.minus(PhosphorIconsStyle.bold),
          value > min ? () => onChanged(value - 1) : null,
        ),
      ],
    );
  }
}
