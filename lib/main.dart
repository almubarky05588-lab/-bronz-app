import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/cart.dart';
import 'core/store_bridge.dart';
import 'core/theme.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Cart.instance.load();
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
      // طبقة الربط المخفية مع المتجر تعمل خلف الواجهة طوال عمر التطبيق
      builder: (context, child) => Stack(
        children: [
          const Positioned(left: 0, top: 0, width: 1, height: 1, child: StoreBridgeHost()),
          if (child != null) Positioned.fill(child: child),
        ],
      ),
      home: const Shell(),
    );
  }
}
