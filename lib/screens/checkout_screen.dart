import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/cart.dart';
import '../core/store_api.dart';
import '../core/store_bridge.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'orders_screen.dart';

/// الدفع:
/// 1) دخول العميل من شاشة التطبيق (إن لم يكن داخلًا)
/// 2) تعبئة سلة المتجر في الخلفية عبر طبقة الربط المحمّلة أصلًا
/// 3) طلب رابط صفحة الدفع من سلة وفتحه وحده — لا رئيسية ولا سلة ولا أي صفحة من الثيم
/// 4) الغطاء لا يُرفع أبدًا عن صفحة غير صفحات الدفع، وأي خطأ يظهر داخل التطبيق
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum _Phase { preparing, paying, done, error }

class _CheckoutScreenState extends State<CheckoutScreen> {
  static final _storeHost = Uri.parse(storeUrl).host;
  static const _checkoutWords = [
    'checkout', 'payment', 'pay', 'thank', 'success', 'order', 'verify', '3ds', 'otp', 'confirm',
  ];

  late final WebViewController _c;
  _Phase _phase = _Phase.preparing;
  bool _covered = true;
  String _status = 'نجهّز طلبك…';
  String? _error;
  List<String> _failed = const [];

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(BronzColors.bg)
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: _onStarted,
        onPageFinished: _onFinished,
        onNavigationRequest: _onNavigation,
      ));
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  // ───────── التجهيز ─────────

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.preparing;
      _covered = true;
      _error = null;
      _status = 'نجهّز طلبك…';
    });
    try {
      if (!await StoreApi.isLoggedIn()) {
        if (!mounted) return;
        final ok = await LoginScreen.open(context);
        if (!ok) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
      }
      setState(() => _status = 'ننقل منتجاتك…');
      var step = await StoreApi.prepareCheckout();

      // الجلسة انتهت عند سلة: نطلب الدخول مرة ثانية ونعيد المحاولة
      if (step.needsLogin) {
        if (!mounted) return;
        final ok = await LoginScreen.open(context);
        if (!ok) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
        step = await StoreApi.prepareCheckout();
      }

      if (!step.ready) {
        throw StoreError('تعذّر فتح صفحة الدفع، حاول مرة ثانية');
      }
      _failed = step.failedItems;
      setState(() {
        _phase = _Phase.paying;
        _status = 'نفتح صفحة الدفع…';
      });
      await _c.loadRequest(Uri.parse(step.url!));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = '$e';
      });
    }
  }

  // ───────── التنقّل داخل صفحة الدفع ─────────

  bool _isStore(String url) => (Uri.tryParse(url)?.host ?? '').endsWith(_storeHost);

  bool _isCheckoutPage(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return false;
    if (!_isStore(url)) return true; // بوابات الدفع والبنوك
    final s = '${u.path}?${u.query}'.toLowerCase();
    return _checkoutWords.any(s.contains);
  }

  bool _isSuccess(String url) {
    final s = url.toLowerCase();
    return _isStore(url) && (s.contains('thank') || s.contains('success') || s.contains('order-received'));
  }

  NavigationDecision _onNavigation(NavigationRequest req) {
    final u = req.url;
    if (!u.startsWith('http')) {
      launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }
    if (_isSuccess(u)) {
      _finish();
      return NavigationDecision.prevent;
    }
    // أي محاولة للذهاب لصفحة عادية في الموقع (الرئيسية/السلة/منتج) → نرجع للتطبيق
    if (_phase == _Phase.paying && !_isCheckoutPage(u)) {
      if (mounted) Navigator.of(context).pop();
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _onStarted(String url) {
    if (_phase != _Phase.paying) return;
    if (_isStore(url) && !_covered) setState(() => _covered = true);
  }

  Future<void> _onFinished(String url) async {
    if (_phase != _Phase.paying) return;
    if (_isSuccess(url)) return _finish();
    if (!_isCheckoutPage(url)) return; // الغطاء يبقى
    if (_isStore(url)) {
      await _c.runJavaScript(_cleanJs);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;
    if (_covered) {
      setState(() => _covered = false);
      if (_failed.isNotEmpty) {
        showBronzToast(context, 'تعذّرت إضافة: ${_failed.join('، ')}', icon: Icons.info_outline_rounded);
        _failed = const [];
      }
    }
  }

  void _finish() {
    if (_phase == _Phase.done) return;
    Cart.instance.clear();
    if (mounted) setState(() => _phase = _Phase.done);
  }

  // ───────── الواجهة ─────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الطلب', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: _phase == _Phase.done
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: Stack(
        children: [
          if (_phase == _Phase.paying) WebViewWidget(controller: _c),
          if (_phase == _Phase.preparing || (_phase == _Phase.paying && _covered)) _loading(),
          if (_phase == _Phase.error)
            Container(
              color: BronzColors.bg,
              child: ErrorView(message: _error ?? 'حدث خطأ', onRetry: _start),
            ),
          if (_phase == _Phase.done) _success(),
        ],
      ),
    );
  }

  Widget _loading() => Container(
        color: BronzColors.bg,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: BronzColors.ink),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(_status, key: ValueKey(_status), style: const TextStyle(fontSize: 15)),
            ),
          ],
        ),
      );

  Widget _success() => Container(
        color: BronzColors.bg,
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: BronzColors.ink, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: BronzColors.gold, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            const Text('تم استلام طلبك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'شكرًا لك! تقدر تتابع حالة طلبك وفاتورته من «طلباتي» أول بأول.',
              textAlign: TextAlign.center,
              style: TextStyle(color: BronzColors.muted, height: 1.6),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              ),
              child: const Text('تابع طلبك'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('متابعة التسوق',
                  style: TextStyle(color: BronzColors.ink, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  /// تنظيف صفحة الدفع من أي أثر للموقع وإلباسها شكل التطبيق.
  static const _cleanJs = r'''
(function(){
  var css = [
    'header, footer, .store-header, .store-footer, .top-navbar, .navbar, salla-breadcrumb, .breadcrumbs,',
    '[href*="wa.me"], [href*="whatsapp"], salla-chat, .chat-widget, .powered-by, .copyright, .cookies-bar, salla-cookies',
    '{ display:none !important; }',
    'html, body { background:#FAF8F5 !important; }',
    'body, body * { font-family:"Tajawal", -apple-system, sans-serif !important; }',
    '* { -webkit-tap-highlight-color:transparent !important; }',
    'a, img { -webkit-touch-callout:none !important; }',
    'body { -webkit-user-select:none !important; user-select:none !important; overscroll-behavior:none !important; }',
    'input, textarea, select { -webkit-user-select:auto !important; user-select:auto !important; font-size:16px !important; }'
  ].join('\n');
  function apply(){
    if (!document.head) return;
    if (!document.getElementById('bronz-font')) {
      var l = document.createElement('link');
      l.id = 'bronz-font'; l.rel = 'stylesheet';
      l.href = 'https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800&display=swap';
      document.head.appendChild(l);
    }
    var s = document.getElementById('bronz-clean');
    if (!s) { s = document.createElement('style'); s.id = 'bronz-clean'; document.head.appendChild(s); }
    if (s.textContent !== css) s.textContent = css;
    var v = document.querySelector('meta[name=viewport]');
    if (!v) { v = document.createElement('meta'); v.name = 'viewport'; document.head.appendChild(v); }
    v.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
  }
  apply();
  if (!window.__bronzObs) {
    window.__bronzObs = new MutationObserver(apply);
    window.__bronzObs.observe(document.documentElement, { childList:true, subtree:true });
  }
})();
''';
}
