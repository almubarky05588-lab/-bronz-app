import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/cart.dart';
import 'core/favorites.dart';
import 'core/push.dart';
import 'core/remote_config.dart';
import 'core/store_bridge.dart';
import 'core/theme.dart';
import 'screens/shell.dart';
import 'widgets/common.dart';
import 'widgets/promo_popup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await Future.wait([Cart.instance.load(), Favorites.instance.load()]);
  Push.init();
  RemoteConfig.instance.ensure(); // قطع الرئيسية والبوب اب من لوحة برونز
  runApp(const BronzApp());
}

class BronzApp extends StatelessWidget {
  const BronzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'برونز',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // طبقة الربط المخفية: صفحة المتجر بمقاس جوال كامل لكنها شفافة وخلف الواجهة
      builder: (context, child) => Stack(
        children: [
          const Positioned(left: 0, top: 0, width: 400, height: 860, child: StoreBridgeHost()),
          if (child != null) Positioned.fill(child: child),
        ],
      ),
      home: const _Launch(),
    );
  }
}

/// الرئيسية تُبنى وتحمّل بياناتها من أول لحظة، والرسم الرصاصي فوقها
/// حتى يجهز المتجر — ثم يختفي بتلاشٍ ناعم، وبعدها إذن الإشعارات ثم البوب اب.
class _Launch extends StatefulWidget {
  const _Launch();

  @override
  State<_Launch> createState() => _LaunchState();
}

class _LaunchState extends State<_Launch> with WidgetsBindingObserver {
  bool _showSplash = true;
  bool _removeSplash = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waitForStore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// لما يرجع العميل للتطبيق بعد دقيقة أو أكثر: نجيب أحدث إعدادات اللوحة ونعرض البوب اب.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _removeSplash) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      if (away >= const Duration(seconds: 60)) {
        RemoteConfig.instance.refresh().then((_) => PromoPopup.maybeShow());
      }
    }
  }

  Future<void> _waitForStore() async {
    final started = DateTime.now();
    var storeReady = false;
    try {
      await StoreBridge.instance.waitReady(seconds: 12);
      storeReady = true;
      await Future.delayed(const Duration(milliseconds: 1100));
    } catch (_) {
      // لو تأخر المتجر نكمل؛ الرئيسية تعرض حالة إعادة المحاولة بنفسها
    }
    final elapsed = DateTime.now().difference(started);
    const minimum = Duration(milliseconds: 1400);
    if (elapsed < minimum) await Future.delayed(minimum - elapsed);
    if (!mounted) return;
    setState(() => _showSplash = false);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _removeSplash = true);

    Push.uiReady();
    if (storeReady) Push.identify();

    // إذن الإشعارات أولًا (مرة وحدة بالعمر)، ثم البوب اب لو مفعّل من اللوحة
    await Future.delayed(const Duration(milliseconds: 600));
    await Push.askPermission();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));
    await PromoPopup.showWhenReady();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: BronzColors.bg, child: Shell())),
        if (!_removeSplash)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showSplash,
              child: AnimatedOpacity(
                opacity: _showSplash ? 1 : 0,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOut,
                child: const BrandSplash(),
              ),
            ),
          ),
      ],
    );
  }
}
