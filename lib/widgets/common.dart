import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';

const splashAsset = 'assets/branding/BRONZ_splash_graphite.png';

/// شاشة «الجمعة البيضاء» الافتتاحية — false يرجّع الشاشة العادية.
/// الخلفية تتولّد وقت البناء (ci/make_bf_splash.py) والشريطان يرسمهم التطبيق متحركين.
const kWhiteFriday = false;
const splashWfAsset = 'assets/branding/BRONZ_splash_wf_bg.png';

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
    if (kWhiteFriday) return const _WhiteFridaySplash();
    return const _BronzSplash();
  }
}

/// مدة حركة شاشة الافتتاح كاملة (main.dart ينتظرها قبل ما يدخل العميل).
const splashMotion = Duration(milliseconds: 2700);

/// شاشة الافتتاح البيضاء: الشعار يظهر بهدوء ← الخط الذهبي والعبارة ←
/// «عطور · مكياج · عناية» تنبض وحدة ورا الثانية ← غمزة سريعة لحرف O مع صوت «تِن».
class _BronzSplash extends StatefulWidget {
  const _BronzSplash();

  @override
  State<_BronzSplash> createState() => _BronzSplashState();
}

class _BronzSplashState extends State<_BronzSplash> with SingleTickerProviderStateMixin {
  static const _ms = 2700.0;
  late final AnimationController _c = AnimationController(vsync: this, duration: splashMotion)..forward();
  Timer? _ting;

  // مركز حرف O داخل الشعار (من رسم الشعار 1264×440) — نقطة الغمزة
  static const _oCenter = Alignment(593 / 1264 * 2 - 1, 287.5 / 440 * 2 - 1);

  @override
  void initState() {
    super.initState();
    _ting = Timer(const Duration(milliseconds: 2250), _playTing);
  }

  /// صوت «تِن» مع الغمزة — مرة وحدة في اليوم، ويحترم وضع الصامت ولا يوقف موسيقى العميل.
  Future<void> _playTing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = '${now.year}-${now.month}-${now.day}';
      if (prefs.getString('splash_ting_day') == today) return;
      await prefs.setString('splash_ting_day', today);
      final player = AudioPlayer();
      await player.setAudioContext(AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ));
      await player.play(AssetSource('sounds/ting.m4a'), volume: 0.7);
      player.onPlayerComplete.first.then((_) => player.dispose());
    } catch (_) {
      // الصوت إضافة جمالية — أي خطأ فيه ما يوقف التطبيق
    }
  }

  @override
  void dispose() {
    _ting?.cancel();
    _c.dispose();
    super.dispose();
  }

  /// قيمة 0→1 بين لحظتين (بالملي ثانية) مع منحنى.
  double _span(double from, double to, [Curve curve = Curves.easeOutCubic]) {
    final t = ((_c.value * _ms - from) / (to - from)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  /// نبضة: يكبر ثم يرجع (0 → 1 → 0).
  double _pulse(double start, [double len = 500]) {
    final t = ((_c.value * _ms - start) / len).clamp(0.0, 1.0);
    return math.sin(t * math.pi);
  }

  Widget _word(String text, double start) {
    final p = _pulse(start);
    final done = _c.value * _ms >= start + 250;
    final color = Color.lerp(done ? const Color(0xFF3A3A3A) : const Color(0xFF8A8A86), const Color(0xFFB8913F), p)!;
    return Transform.scale(
      scale: 1 + 0.3 * p,
      child: Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _dot() => Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(color: Color(0xFFC9A35A), shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    const logoW = 236.0;
    return ColoredBox(
      color: Colors.white,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final logoIn = _span(0, 700);
          final lineIn = _span(300, 800);
          final tagIn = _span(350, 850);
          final wordsIn = _span(500, 900);
          final wink = 1 - 0.92 * _pulse(2250, 300); // O يغمض ويفتح
          return Center(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: logoIn,
                    child: Transform.scale(
                      scale: 0.92 + 0.08 * logoIn,
                      child: SizedBox(
                        width: logoW,
                        height: logoW * 440 / 1264,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            SvgPicture.asset('assets/branding/bronz_logo_base.svg'),
                            Transform(
                              alignment: _oCenter,
                              transform: Matrix4.diagonal3Values(1, wink, 1),
                              child: SvgPicture.asset('assets/branding/bronz_logo_o.svg'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Opacity(
                    opacity: lineIn,
                    child: Container(width: 40, height: 1.5, color: const Color(0xFFC9A35A)),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: tagIn,
                    child: const Text(
                      'خيارك الأفضل للعطور ومستحضرات التجميل',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF3A3A3A)),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Opacity(
                    opacity: wordsIn,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.rtl,
                      children: [
                        _word('عطور', 800),
                        _dot(),
                        _word('مكياج', 1250),
                        _dot(),
                        _word('عناية', 1700),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// الخلفية بنفس قصّ الصورة الأصلية (cover)، وفوقها شريطان أصفران بنفس مكانهم في الصورة
/// والكتابة داخلهم تمشي من اليسار لليمين.
class _WhiteFridaySplash extends StatefulWidget {
  const _WhiteFridaySplash();

  @override
  State<_WhiteFridaySplash> createState() => _WhiteFridaySplashState();
}

class _WhiteFridaySplashState extends State<_WhiteFridaySplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  // أبعاد صورة الخلفية ومواضع الشريطين (نفس ci/make_bf_splash.py)
  static const _iw = 1440.0, _ih = 2560.0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final sw = box.maxWidth, sh = box.maxHeight;
      final s = math.max(sw / _iw, sh / _ih);
      final dx = (sw - _iw * s) / 2, dy = (sh - _ih * s) / 2;

      Widget tape(String text, double deg, double cyFrac) {
        final tw = _iw * 1.9 * s, th = 150 * s;
        final cx = dx + _iw / 2 * s, cy = dy + _ih * cyFrac * s;
        return Positioned(
          left: cx - tw / 2,
          top: cy - th / 2,
          width: tw,
          height: th,
          child: Transform.rotate(
            angle: deg * math.pi / 180,
            child: _MovingTape(text: text, scale: s, anim: _c),
          ),
        );
      }

      return ColoredBox(
        color: const Color(0xFF0A0A0A),
        child: Stack(
          children: [
            Positioned(
              left: dx,
              top: dy,
              width: _iw * s,
              height: _ih * s,
              child: Image.asset(
                splashWfAsset,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Image.asset(splashAsset, fit: BoxFit.cover),
              ),
            ),
            tape('BLACK FRIDAY', 11, 0.17),
            tape('WHITE FRIDAY', -9, 0.86),
          ],
        ),
      );
    });
  }
}

class _MovingTape extends StatelessWidget {
  final String text;
  final double scale;
  final Animation<double> anim;
  const _MovingTape({required this.text, required this.scale, required this.anim});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.cairo(
      fontSize: 70 * scale,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF0C0C0C),
      height: 1.0,
    );
    final label = '$text  •  ';
    final tp = TextPainter(text: TextSpan(text: label, style: style), textDirection: TextDirection.ltr)..layout();
    final seg = tp.width + 30 * scale;
    return LayoutBuilder(builder: (context, box) {
      final n = (box.maxWidth / seg).ceil() + 2;
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFD600),
          border: Border.symmetric(horizontal: BorderSide(color: const Color(0xFF141414), width: 8 * scale)),
          boxShadow: const [BoxShadow(color: Color(0x8C000000), blurRadius: 24, offset: Offset(6, 14))],
        ),
        child: ClipRect(
          child: AnimatedBuilder(
            animation: anim,
            builder: (context, child) => Transform.translate(
              offset: Offset(-seg + anim.value * seg, 0), // يسار ← يمين
              child: child,
            ),
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: [
                  for (var i = 0; i < n; i++)
                    SizedBox(width: seg, child: Text(label, style: style, maxLines: 1, softWrap: false)),
                ],
              ),
            ),
          ),
        ),
      );
    });
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
