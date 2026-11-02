import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/push.dart';
import '../core/store_bridge.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// تسجيل الدخول عبر نافذة سلة الرسمية (نفس اللي في الموقع):
/// سلة غيّرت نظام التحقق لنظام جديد، فالرمز يوصل فقط من نافذتها.
/// الصفحة تُفتح داخل التطبيق، وبعد الدخول تتشارك الجلسة مع المتجر المخفي تلقائيًا.
/// يُرجع true عند نجاح الدخول.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static Future<bool> open(BuildContext context) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const LoginScreen()),
    );
    return ok ?? false;
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _web;
  Timer? _poll;
  bool _loading = true;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          _web.runJavaScript(_openLoginJs);
          if (mounted) setState(() => _loading = false);
        },
        // الصفحة الرئيسية تبقى داخل المتجر وسلة فقط — أما الإطارات الداخلية (التحقق الأمني/الكابتشا)
        // فلازم تتحمّل بحرية، وإلا تفشل سلة في إرسال الرمز
        onNavigationRequest: (req) {
          if (!req.isMainFrame) return NavigationDecision.navigate;
          final host = Uri.tryParse(req.url)?.host ?? '';
          final ok = host.endsWith('bronz-sa.com') || host.endsWith('salla.com') || host.endsWith('salla.sa');
          return ok ? NavigationDecision.navigate : NavigationDecision.prevent;
        },
      ))
      // هوية سفاري حتى يتعامل التحقق الأمني مع التطبيق كمتصفح عادي
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1')
      ..loadRequest(Uri.parse(storeUrl));
    _poll = Timer.periodic(const Duration(milliseconds: 1500), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// يفتح نافذة دخول سلة فوق الصفحة ويخفي بقية الموقع.
  static const _openLoginJs = r'''
(function(){
  if (!document.getElementById('bronz-login-css')) {
    var s = document.createElement('style');
    s.id = 'bronz-login-css';
    s.textContent = 'header,footer,.s-footer,salla-cookies,.promotion-bar,#__bs_notify__,salla-chat{display:none!important}body{background:#fff!important}';
    document.head.appendChild(s);
  }
  var tries = 0;
  (function open(){
    if (window.salla && salla.event && salla.config) {
      if (!salla.config.isGuest()) return;
      try { salla.event.dispatch('login::open', { withoutReload: true }); } catch (e) {}
      return;
    }
    if (++tries < 150) setTimeout(open, 200);
  })();
})();
''';

  Future<void> _check() async {
    if (_finishing || !mounted) return;
    try {
      final r = await _web.runJavaScriptReturningResult(
        "(window.salla && salla.config && !salla.config.isGuest()) ? '1' : '0'",
      );
      if ('$r'.replaceAll('"', '') == '1') await _finish();
    } catch (_) {}
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _poll?.cancel();
    if (mounted) setState(() => _loading = true);
    // الجلسة مشتركة مع المتجر المخفي — نعيد تحميله حتى يعرف العميل
    try {
      await StoreBridge.instance.refreshSession();
      await Push.identify();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  RoundIcon(icon: PhosphorIcons.x(), onTap: () => Navigator.of(context).pop(false)),
                  const Expanded(
                    child: Text(
                      'تسجيل الدخول',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _web),
                  if (_loading)
                    const ColoredBox(
                      color: BronzColors.bg,
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: BronzColors.ink),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
