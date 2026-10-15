import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../screens/category_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/product_screen.dart';
import '../widgets/banner_carousel.dart';
import 'catalog.dart';
import 'order.dart';
import 'product.dart';
import 'store_api.dart';
import 'store_bridge.dart';

const oneSignalAppId = 'da1ab6c7-deb4-458e-bfcb-6e41e150d686';

/// مفتاح التنقّل العام — حتى يفتح الإشعار الشاشة المناسبة من أي مكان.
final navigatorKey = GlobalKey<NavigatorState>();

/// الإشعارات (OneSignal):
/// - كل جوال يُربط برقم العميل في سلة (external_id) بعد دخوله،
///   فيصله إشعار تغيّر حالة طلبه هو فقط.
/// - الضغط على الإشعار يفتح داخل التطبيق حسب بياناته الإضافية:
///   order_id → تفاصيل الطلب · product_id → المنتج · category_id → القسم
///   offers → العروض · latest → وصل حديثًا · url → أي رابط من المتجر
/// - البوب اب الترويجي يُدار من «لوحة برونز» (widgets/promo_popup.dart).
class Push {
  static bool _ready = false;
  static Map<String, dynamic>? _pending;
  static bool _uiReady = false;

  static void init() {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.none);
      OneSignal.initialize(oneSignalAppId);
      OneSignal.Notifications.addClickListener((event) {
        final data = <String, dynamic>{...?event.notification.additionalData};
        _handle(data);
      });
      _ready = true;
    } catch (_) {}
  }

  /// نافذة إذن الإشعارات (تظهر مرة واحدة).
  static Future<void> askPermission() async {
    if (!_ready) return;
    try {
      await OneSignal.Notifications.requestPermission(true);
    } catch (_) {}
  }

  /// يربط الجوال برقم العميل في سلة.
  static Future<void> identify() async {
    if (!_ready) return;
    try {
      final res = await StoreBridge.instance.call('me');
      if (res is Map && res['guest'] == false && res['user'] is Map) {
        final id = '${(res['user'] as Map)['id'] ?? ''}';
        if (id.isNotEmpty && id != 'null') OneSignal.login(id);
      }
    } catch (_) {}
  }

  static void forget() {
    if (!_ready) return;
    try {
      OneSignal.logout();
    } catch (_) {}
  }

  /// تُستدعى بعد اختفاء الشاشة الافتتاحية — تفتح إشعارًا ضُغط والتطبيق مغلق.
  static void uiReady() {
    _uiReady = true;
    final p = _pending;
    _pending = null;
    if (p != null) _handle(p);
  }

  /// فتح وجهة داخل التطبيق (يستخدمها البوب اب بنفس صيغة بيانات الإشعار).
  static void open(Map<String, dynamic> d) => _handle(d);

  static void _handle(Map<String, dynamic> d) {
    final nav = navigatorKey.currentState;
    if (nav == null || !_uiReady) {
      _pending = d;
      return;
    }
    int? n(String k) => int.tryParse('${d[k] ?? ''}'.trim());

    final order = n('order_id');
    if (order != null) {
      nav.push(MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(
          order: StoreOrder(
            id: order,
            number: '${d['order_number'] ?? ''}',
            date: '',
            statusName: '',
            statusSlug: '',
            payment: '',
            lines: const [],
          ),
        ),
      ));
      return;
    }
    final product = n('product_id');
    if (product != null) {
      nav.push(MaterialPageRoute(builder: (_) => ProductScreen(product: Product.stub(product))));
      return;
    }
    final cat = n('category_id');
    final c = cat == null ? null : (findCategory(cat) ?? StoreCategory(cat, '${d['title'] ?? 'القسم'}', Icons.category_outlined));
    if (c != null) {
      nav.push(MaterialPageRoute(builder: (_) => CategoryScreen(category: c)));
      return;
    }
    if (d['offers'] != null) {
      nav.push(MaterialPageRoute(
        builder: (_) => ProductListScreen(title: 'العروض', loader: (p) => StoreApi.offers(page: p)),
      ));
      return;
    }
    if (d['latest'] != null) {
      nav.push(MaterialPageRoute(
        builder: (_) => ProductListScreen(title: 'وصل حديثًا', loader: (p) => StoreApi.latest(page: p)),
      ));
      return;
    }
    final url = d['url'];
    if (url is String && url.isNotEmpty) openStoreLink(nav.context, url);
  }
}
