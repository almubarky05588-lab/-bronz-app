import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const storeUrl = 'https://bronz-sa.com/ar';

class StoreError implements Exception {
  final String message;
  StoreError(this.message);
  @override
  String toString() => message;
}

/// طبقة الربط: صفحة المتجر تعمل مخفية تمامًا خلف التطبيق، ونستدعي منها
/// مكتبة سلة الرسمية (Twilight SDK) مباشرة: المنتجات، التفاصيل، تسجيل الدخول
/// برمز التحقق، تعبئة السلة، وجلب رابط صفحة الدفع — كل ذلك كبيانات JSON.
class StoreBridge {
  StoreBridge._();
  static final StoreBridge instance = StoreBridge._();

  late final WebViewController controller = _build();
  final _pending = <String, Completer<dynamic>>{};
  bool _ready = false;
  bool _failed = false;
  int _seq = 0;

  WebViewController _build() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('BronzBridge', onMessageReceived: _onMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => _ready = false,
        onPageFinished: (_) => controller.runJavaScript(_js),
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) _failed = true;
        },
        // الصفحة المخفية لا تغادر المتجر أبدًا (تمنع أي تحويل تلقائي بعد الدخول)
        onNavigationRequest: (req) {
          final host = Uri.tryParse(req.url)?.host ?? '';
          return host.endsWith('bronz-sa.com')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(storeUrl));
  }

  void reload() {
    _failed = false;
    _ready = false;
    controller.loadRequest(Uri.parse(storeUrl));
  }

  Future<void> waitReady({int seconds = 25}) async {
    controller; // يضمن بدء التحميل
    if (_failed) reload();
    final start = DateTime.now();
    while (!_ready) {
      if (_failed || DateTime.now().difference(start).inSeconds > seconds) {
        throw StoreError('تعذّر الاتصال بالمتجر، تحقق من الإنترنت');
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  /// يعيد تحميل الصفحة المخفية وينتظر جاهزيتها (بعد تسجيل الدخول مثلًا
  /// حتى تتحدّث جلسة العميل داخل مكتبة سلة).
  Future<void> refreshSession() async {
    reload();
    await Future.delayed(const Duration(milliseconds: 300));
    await waitReady();
  }

  void _onMessage(JavaScriptMessage m) {
    Map<String, dynamic> map;
    try {
      map = jsonDecode(m.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final id = map['id'];
    if (id == '__ready') {
      if (map['ok'] == true) {
        _ready = true;
        _failed = false;
      } else {
        _failed = true;
      }
      return;
    }
    final c = _pending.remove(id);
    if (c == null || c.isCompleted) return;
    if (map['ok'] == true) {
      c.complete(map['data']);
    } else {
      c.completeError(StoreError('${map['error'] ?? 'تعذّر تنفيذ الطلب'}'));
    }
  }

  /// يستدعي إجراءً من مكتبة سلة داخل الصفحة المخفية.
  Future<dynamic> call(String action, [Map<String, dynamic> args = const {}, int timeoutSeconds = 25]) async {
    await waitReady();
    final id = 'r${_seq++}';
    final c = Completer<dynamic>();
    _pending[id] = c;
    await controller.runJavaScript(
      'window.__bronzCall(${jsonEncode(id)}, ${jsonEncode(action)}, ${jsonEncode(args)});',
    );
    return c.future.timeout(Duration(seconds: timeoutSeconds), onTimeout: () {
      _pending.remove(id);
      throw StoreError('انتهت مهلة الاتصال');
    });
  }

  /// طلب مباشر لمسار في واجهة سلة (للتوافق مع الكود السابق).
  Future<dynamic> get(String path) => call('request', {'path': path});

  static const _js = r'''
(function(){
  if (window.__bronzInit) return;
  window.__bronzInit = true;

  function post(o){
    try { BronzBridge.postMessage(JSON.stringify(o)); }
    catch(e) { try { BronzBridge.postMessage(JSON.stringify({ id: o.id, ok: false, error: 'serialize' })); } catch(_) {} }
  }
  function sid(){ try { return salla.config.get('store.id'); } catch(e) { return null; } }
  function unwrap(r){ return (r && r.data !== undefined && r.status !== undefined && r.headers) ? r.data : r; }
  function errMsg(e){
    try {
      var r = e && e.response && e.response.data;
      if (r && r.error && r.error.message) return r.error.message;
      if (r && r.message) return r.message;
      if (e && e.error && e.error.message) return e.error.message;
    } catch(_) {}
    return String((e && e.message) || e);
  }
  function noRedirect(){ try { salla.api.auth.setCanRedirect(false); } catch(e) {} }

  async function cartId(){ return await salla.api.cart.getCurrentCartId(); }
  async function cartItems(id){
    var r = await salla.api.cart.details(id, []);
    var d = (r && r.data) || {};
    var c = d.cart || d;
    return c.items || [];
  }

  var A = {
    request: async function(a){ return unwrap(await salla.api.request(a.path, null, 'get')); },

    products: async function(a){
      var q = { source: a.source };
      if (a.value !== undefined && a.value !== null) {
        q.source_value = (a.source === 'categories' || a.source === 'brands' || a.source === 'tags' || a.source === 'selected') ? [a.value] : a.value;
      }
      if (a.page && a.page > 1) q.page = a.page;
      return await salla.api.product.fetch(q);
    },

    details: async function(a){
      return await salla.api.product.getDetails(a.id, ['images', 'brand', 'rating', 'category']);
    },

    me: async function(){
      var guest = true, user = null;
      try { guest = salla.config.isGuest(); } catch(e) {}
      try { user = salla.config.get('user'); } catch(e) {}
      return { guest: guest, user: user };
    },

    login: async function(a){
      noRedirect();
      return await salla.api.auth.login({ type: 'mobile', phone: a.phone, country_code: 'SA' });
    },

    resend: async function(a){
      return await salla.api.auth.resend({ type: 'mobile', phone: a.phone, country_code: 'SA' });
    },

    verify: async function(a){
      noRedirect();
      return await salla.api.auth.verify({ type: 'mobile', phone: a.phone, code: a.code, country_code: 'SA' }, false);
    },

    register: async function(a){
      noRedirect();
      var p = { first_name: a.first, last_name: a.last, phone: a.phone, country_code: 'SA', verified_by: 'phone', code: a.code };
      if (a.email) p.email = a.email;
      return await salla.api.auth.register(p);
    },

    logout: async function(){ noRedirect(); return await salla.api.auth.logout(); },

    syncCart: async function(a){
      var id = await cartId();
      var existing = [];
      try { existing = await cartItems(id); } catch(e) {}
      for (var i = 0; i < existing.length; i++) {
        try { await salla.api.cart.deleteItem(existing[i].id); } catch(e) {}
      }
      var failed = [];
      for (var j = 0; j < a.items.length; j++) {
        try { await salla.api.cart.addItem({ id: a.items[j].id, quantity: a.items[j].qty }); }
        catch(e) { failed.push({ name: a.items[j].name, error: errMsg(e) }); }
      }
      return { failed: failed };
    },

    checkoutUrl: async function(){
      var id = await cartId();
      var r = await salla.api.cart.status(id, false);
      var ns = (r && r.data && r.data.next_step) || {};
      return { to: ns.to || null, url: ns.url || null };
    }
  };

  window.__bronzCall = function(id, action, args){
    var f = A[action];
    if (!f) { post({ id: id, ok: false, error: 'unknown action: ' + action }); return; }
    Promise.resolve()
      .then(function(){ return f(args || {}); })
      .then(function(d){ post({ id: id, ok: true, data: d }); })
      .catch(function(e){ post({ id: id, ok: false, error: errMsg(e) }); });
  };

  var tries = 0;
  (function wait(){
    if (window.salla && salla.api && salla.api.product && salla.api.cart && salla.config && sid()) {
      noRedirect();
      post({ id: '__ready', ok: true });
      return;
    }
    if (++tries > 120) { post({ id: '__ready', ok: false }); return; }
    setTimeout(wait, 200);
  })();
})();
''';
}

class StoreBridgeHost extends StatelessWidget {
  const StoreBridgeHost({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.01,
        child: WebViewWidget(controller: StoreBridge.instance.controller),
      ),
    );
  }
}
