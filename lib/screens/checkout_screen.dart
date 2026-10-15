import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/cart.dart';
import '../core/store_bridge.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// الدفع: ننقل سلة التطبيق إلى سلة المتجر الرسمية ثم نعرض صفحة الدفع من سلة
/// حتى يُسجَّل الطلب في لوحة التحكم بكل طرق الدفع والشحن المفعّلة.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final WebViewController _c;
  bool _preparing = true;
  bool _injected = false;
  String? _error;
  final _failed = <String>[];
  Timer? _safety;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('BronzCheckout', onMessageReceived: _onMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: _onFinished,
        onNavigationRequest: (req) {
          final u = req.url;
          if (u.startsWith('http')) return NavigationDecision.navigate;
          launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
      ));
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _preparing = true;
      _injected = false;
      _error = null;
      _failed.clear();
    });
    // سلة نظيفة في كل مرة حتى لا تتكرر المنتجات
    await WebViewCookieManager().clearCookies();
    await _c.loadRequest(Uri.parse(storeUrl));
    _safety?.cancel();
    _safety = Timer(const Duration(seconds: 30), () {
      if (mounted && _preparing) setState(() => _preparing = false);
    });
  }

  @override
  void dispose() {
    _safety?.cancel();
    super.dispose();
  }

  void _onFinished(String url) {
    if (!_injected) {
      _injected = true;
      final items = Cart.instance.items.map((e) => {'id': e.id, 'qty': e.qty, 'name': e.name}).toList();
      _c.runJavaScript(_addJs.replaceFirst('__ITEMS__', jsonEncode(items)));
      return;
    }
    if (_preparing && url.contains('cart')) {
      setState(() => _preparing = false);
      if (_failed.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تعذّرت إضافة: ${_failed.join('، ')} — أضفها من الصفحة'),
        ));
      }
    }
    if (url.contains('thank') || url.contains('success')) {
      Cart.instance.clear();
    }
  }

  void _onMessage(JavaScriptMessage m) {
    try {
      final map = jsonDecode(m.message) as Map<String, dynamic>;
      if (map['error'] == 'sdk') {
        setState(() {
          _preparing = false;
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
          if (_preparing)
            Container(
              color: BronzColors.bg,
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('نجهّز طلبك…'),
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
