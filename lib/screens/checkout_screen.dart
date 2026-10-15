import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/cart.dart';
import '../core/store_bridge.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// الدفع: ننقل سلة التطبيق إلى سلة المتجر ثم نعرض خطوات الدفع من سلة
/// بعد إخفاء كل عناصر الموقع (الهيدر، الفوتر، القوائم، البانرات، أزرار التواصل)
/// وتلوين الصفحة بألوان وخط التطبيق — والغطاء يبقى فوقها حتى يكتمل التنظيف
/// فلا يظهر الموقع ولو لجزء من ثانية.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static final _storeHost = Uri.parse(storeUrl).host;

  late final WebViewController _c;
  bool _covered = true;
  bool _injected = false;
  String? _error;
  final _failed = <String>[];
  Timer? _safety;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(BronzColors.bg)
      ..enableZoom(false)
      ..addJavaScriptChannel('BronzCheckout', onMessageReceived: _onMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: _onStarted,
        onPageFinished: _onFinished,
        onNavigationRequest: _onNavigation,
      ));
    _start();
  }

  bool _isStore(String url) => Uri.tryParse(url)?.host == _storeHost;

  Future<void> _start() async {
    setState(() {
      _covered = true;
      _injected = false;
      _error = null;
      _failed.clear();
    });
    // سلة نظيفة في كل مرة حتى لا تتكرر المنتجات
    await WebViewCookieManager().clearCookies();
    await _c.loadRequest(Uri.parse(storeUrl));
    _armSafety();
  }

  void _armSafety() {
    _safety?.cancel();
    _safety = Timer(const Duration(seconds: 30), () {
      if (mounted && _covered && _injected) setState(() => _covered = false);
    });
  }

  @override
  void dispose() {
    _safety?.cancel();
    super.dispose();
  }

  NavigationDecision _onNavigation(NavigationRequest req) {
    final u = req.url;
    if (!u.startsWith('http')) {
      launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }
    // لو حاول العميل الرجوع لصفحات الموقع العادية (الرئيسية/منتج/قسم) نرجّعه للتطبيق
    if (_injected && _isStore(u)) {
      final path = Uri.parse(u).path;
      const allowed = ['cart', 'checkout', 'payment', 'login', 'auth', 'thank', 'order', 'success', 'verify'];
      final ok = allowed.any(path.contains);
      if (!ok) {
        Navigator.of(context).maybePop();
        return NavigationDecision.prevent;
      }
    }
    return NavigationDecision.navigate;
  }

  void _onStarted(String url) {
    if (_injected && _isStore(url) && !_covered) {
      setState(() => _covered = true);
      _armSafety();
    }
  }

  Future<void> _onFinished(String url) async {
    if (!_injected) {
      _injected = true;
      final items = Cart.instance.items.map((e) => {'id': e.id, 'qty': e.qty, 'name': e.name}).toList();
      await _c.runJavaScript(_cleanJs);
      await _c.runJavaScript(_addJs.replaceFirst('__ITEMS__', jsonEncode(items)));
      return;
    }
    if (url.contains('thank') || url.contains('success')) {
      Cart.instance.clear();
    }
    if (_isStore(url)) {
      await _c.runJavaScript(_cleanJs);
      await Future.delayed(const Duration(milliseconds: 180));
    }
    if (!mounted) return;
    if (_covered) {
      setState(() => _covered = false);
      if (_failed.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تعذّرت إضافة: ${_failed.join('، ')}'),
        ));
        _failed.clear();
      }
    }
  }

  void _onMessage(JavaScriptMessage m) {
    try {
      final map = jsonDecode(m.message) as Map<String, dynamic>;
      if (map['error'] == 'sdk') {
        setState(() {
          _covered = false;
          _error = 'تعذّر فتح صفحة الدفع';
        });
      } else if (map['error'] == 'item') {
        _failed.add('${map['name']}');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب')),
      body: Stack(
        children: [
          WebViewWidget(controller: _c),
          if (_covered)
            Container(
              color: BronzColors.bg,
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('لحظات…'),
                ],
              ),
            ),
          if (_error != null)
            Container(
              color: BronzColors.bg,
              child: ErrorView(message: _error!, onRetry: _start),
            ),
        ],
      ),
    );
  }

  /// يخفي كل ما يدل على الموقع ويُلبس الصفحة شكل التطبيق.
  /// MutationObserver يعيد الإخفاء لأي عنصر يظهر لاحقًا (نوافذ، شات، بانرات).
  static const _cleanJs = r'''
(function(){
  var css = [
    'header, footer, .store-header, .store-footer, .top-navbar, .main-nav-container, .navbar,',
    '.breadcrumbs, nav.breadcrumbs, salla-breadcrumb, .page-title-wrap,',
    'salla-menu, .mobile-menu, .mm-ocd, .sidebar-menu, .menu-toggle,',
    'salla-social, salla-apps-icons, salla-contacts, salla-trust-badges, .store-contacts,',
    'salla-advertisement, .advertisement, .s-advertisement, .s-app-banner, .app-banner, .top-banner,',
    'salla-newsletter, .newsletter, salla-scroll-top, .scroll-top, .back-to-top,',
    '.whatsapp-button, .floating-whatsapp, [href*="wa.me"], [href*="whatsapp"], salla-chat, #chat-widget, .chat-widget,',
    'salla-products-slider, .s-products-slider, .related-products, .cart-upsells, salla-offer-modal,',
    '.cookies-bar, salla-cookies, .cookie-consent, .powered-by, .copyright',
    '{ display:none !important; }',
    'html, body { background:#FAF8F5 !important; padding-top:0 !important; margin-top:0 !important; }',
    'body, body * { font-family:"Tajawal", -apple-system, sans-serif !important; }',
    '* { -webkit-tap-highlight-color:transparent !important; }',
    'a, img { -webkit-touch-callout:none !important; }',
    'body { -webkit-user-select:none !important; user-select:none !important; overscroll-behavior:none !important; }',
    'input, textarea, select { -webkit-user-select:auto !important; user-select:auto !important; font-size:16px !important; }',
    'main, .main-content, .container { padding-top:8px !important; }',
    '.btn-primary, .s-button-primary, button[type=submit], salla-button button { background:#111111 !important; border-color:#111111 !important; color:#fff !important; border-radius:14px !important; }',
    '.card, .s-cart-item, .cart-item, .box { border-radius:14px !important; border-color:#ECE7DF !important; box-shadow:none !important; }'
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
    document.title = 'برونز';
  }
  apply();
  if (!window.__bronzObs) {
    window.__bronzObs = new MutationObserver(function(){ apply(); });
    window.__bronzObs.observe(document.documentElement, { childList:true, subtree:true });
  }
})();
''';

  static const _addJs = r'''
(function(){
  var items = __ITEMS__;
  function post(o){ try { BronzCheckout.postMessage(JSON.stringify(o)); } catch(e) {} }
  var tries = 0;
  function go(){
    if (!(window.salla && salla.cart && typeof salla.cart.addItem === 'function')) {
      if (++tries > 100) { post({ ok: false, error: 'sdk' }); return; }
      setTimeout(go, 250); return;
    }
    (async function(){
      for (var i = 0; i < items.length; i++) {
        try { await salla.cart.addItem({ id: items[i].id, quantity: items[i].qty }); }
        catch(e) { post({ ok: false, error: 'item', name: items[i].name }); }
      }
      post({ ok: true });
      var target = '/ar/cart';
      try { if (salla.url && salla.url.get) target = salla.url.get('cart'); } catch(e) {}
      window.location.href = target;
    })();
  }
  go();
})();
''';
}
