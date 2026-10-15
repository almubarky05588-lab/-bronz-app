import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/cart.dart';
import 'core/favorites.dart';
import 'core/store_bridge.dart';
import 'core/theme.dart';
import 'screens/shell.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await Future.wait([Cart.instance.load(), Favorites.instance.load()]);
  runApp(const BronzApp());
}

class BronzApp extends StatelessWidget {
  const BronzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'برونز',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // طبقة الربط المخفية: صفحة المتجر بمقاس جوال كامل (حتى تُحمَّل البانرات
      // والصور بشكل طبيعي) لكنها شفافة وخلف الواجهة ولا تستقبل أي لمسة
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
/// حتى يجهز المتجر وتمتلئ الصفوف — ثم يختفي بتلاشٍ ناعم.
class _Launch extends StatefulWidget {
  const _Launch();

  @override
  State<_Launch> createState() => _LaunchState();
}

class _LaunchState extends State<_Launch> {
  bool _showSplash = true;
  bool _removeSplash = false;

  @override
  void initState() {
    super.initState();
    _waitForStore();
  }

  Future<void> _waitForStore() async {
    final started = DateTime.now();
    try {
      await StoreBridge.instance.waitReady(seconds: 12);
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
    if (mounted) setState(() => _removeSplash = true);
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
