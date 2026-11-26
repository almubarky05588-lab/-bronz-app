import 'dart:convert';
import 'dart:io';

import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push.dart';

/// «أبلغني عند التوفّر»: يسجّل الجوال عند «لوحة برونز»،
/// واللوحة تفحص المنتج كل ساعة وترسل إشعار أول ما يتوفّر.
class StockAlerts {
  StockAlerts._();
  static const _key = 'bronz_stock_alerts_v1';
  static const _url = 'https://bronz-push.almubarky05588.workers.dev/watch';

  static Future<bool> isWatching(int id) async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(_key) ?? const []).contains('$id');
    } catch (_) {
      return false;
    }
  }

  /// يرجع null لو تم، أو رسالة توضح المشكلة.
  static Future<String?> watch(int id, String name) async {
    await Push.askPermission();
    String? sub;
    try {
      if (!OneSignal.Notifications.permission) {
        return 'فعّل الإشعارات لبرونز من إعدادات الجوال عشان نبلغك';
      }
      // الاشتراك أحيانًا يتأخر ثواني بعد الموافقة على الإذن
      for (var i = 0; i < 6 && (sub == null || sub.isEmpty); i++) {
        sub = OneSignal.User.pushSubscription.id;
        if (sub == null || sub.isEmpty) await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (_) {}
    if (sub == null || sub.isEmpty) return 'تعذّر تفعيل التنبيه، حاول بعد شوي';

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.postUrl(Uri.parse(_url));
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode({'id': id, 'sub': sub, 'name': name})));
      final res = await req.close().timeout(const Duration(seconds: 12));
      await res.drain<void>();
      if (res.statusCode != 200) return 'تعذّر تفعيل التنبيه، حاول بعد شوي';
    } catch (_) {
      return 'تأكد من الاتصال بالإنترنت وحاول مرة ثانية';
    } finally {
      client.close();
    }

    try {
      final p = await SharedPreferences.getInstance();
      final l = {...(p.getStringList(_key) ?? const <String>[]), '$id'}.toList();
      await p.setStringList(_key, l);
    } catch (_) {}
    return null;
  }
}
