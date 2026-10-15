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

/// طبقة الربط: صفحة المتجر تعمل مخفية، ونستخدم محرّك سلة الرسمي داخلها
/// لجلب المنتجات كبيانات JSON — بدون توكن وبدون أن يرى العميل أي صفحة ويب.
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
      ))
      ..loadRequest(Uri.parse(storeUrl));
  }

  void reload() {
    _failed = false;
    _ready = false;
    controller.loadRequest(Uri.parse(storeUrl));
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
      c.completeError(StoreError('${map['error'] ?? 'تعذّر جلب البيانات'}'));
    }
  }

  Future<dynamic> get(String path) async {
    controller; // يضمن بدء التحميل
    if (_failed) reload();
    final start = DateTime.now();
    while (!_ready) {
      if (_failed || DateTime.now().difference(start).inSeconds > 25) {
        throw StoreError('تعذّر الاتصال بالمتجر، تحقق من الإنترنت');
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    final id = 'r${_seq++}';
    final c = Completer<dynamic>();
    _pending[id] = c;
    await controller.runJavaScript('window.__bronzReq(${jsonEncode(id)}, ${jsonEncode(path)});');
    return c.future.timeout(const Duration(seconds: 20), onTimeout: () {
      _pending.remove(id);
      throw StoreError('انتهت مهلة الاتصال');
    });
  }

  static const _js = r'''
(function(){
  if (window.__bronzInit) return;
  window.__bronzInit = true;
  function post(o){ try { BronzBridge.postMessage(JSON.stringify(o)); } catch(e) {} }
  function sid(){ try { return salla.config.get('store.id'); } catch(e) { return null; } }
  function unwrap(r){ return (r && r.data !== undefined && r.status !== undefined && r.headers) ? r.data : r; }
  async function get(path){
    if (window.salla && salla.api && typeof salla.api.request === 'function') {
      try { var r = await salla.api.request(path, null, 'get'); if (r) return unwrap(r); } catch(e) {}
    }
    var res = await fetch('https://api.salla.dev/store/v1/' + path, {
      headers: { 'Store-Identifier': String(sid()), 'Accept': 'application/json', 'Accept-Language': 'ar', 'currency': 'SAR' }
    });
    return await res.json();
  }
  window.__bronzReq = function(id, path){
    get(path)
      .then(function(d){ post({ id: id, ok: true, data: d }); })
      .catch(function(e){ post({ id: id, ok: false, error: String(e) }); });
  };
  var tries = 0;
  (function wait(){
    if (window.salla && salla.config && sid()) { post({ id: '__ready', ok: true }); return; }
    if (++tries > 80) { post({ id: '__ready', ok: false }); return; }
    setTimeout(wait, 250);
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
