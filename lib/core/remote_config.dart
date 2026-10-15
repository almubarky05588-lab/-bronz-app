import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إعدادات تُدار من «لوحة برونز» (Cloudflare) بدون تحديث التطبيق:
/// ترتيب دوائر الأقسام وصورها، صفوف الرئيسية، والبوب اب.
const remoteConfigUrl = 'https://bronz-push.almubarky05588.workers.dev/config';

class HomeItem {
  final String type; // offers | latest | category
  final int? id;
  final String label;
  final String image;
  final bool hidden;
  const HomeItem({required this.type, this.id, this.label = '', this.image = '', this.hidden = false});

  factory HomeItem.fromJson(Map m, String labelKey) => HomeItem(
        type: '${m['type'] ?? 'category'}',
        id: int.tryParse('${m['id'] ?? ''}'),
        label: '${m[labelKey] ?? ''}'.trim(),
        image: '${m['image'] ?? ''}'.trim(),
        hidden: m['hidden'] == true,
      );
}

class PopupConfig {
  final bool active;
  final String id;
  final String image;
  final String title;
  final String body;
  final String button;
  final String open; // none | offers | latest | product | category | url
  final String value;
  final String freq; // once | daily | always
  const PopupConfig({
    required this.active,
    required this.id,
    this.image = '',
    this.title = '',
    this.body = '',
    this.button = '',
    this.open = 'none',
    this.value = '',
    this.freq = 'once',
  });

  bool get isEmpty => title.isEmpty && body.isEmpty && image.isEmpty;

  factory PopupConfig.fromJson(Map m) => PopupConfig(
        active: m['active'] == true,
        id: '${m['id'] ?? ''}',
        image: '${m['image'] ?? ''}'.trim(),
        title: '${m['title'] ?? ''}'.trim(),
        body: '${m['body'] ?? ''}'.trim(),
        button: '${m['button'] ?? ''}'.trim(),
        open: '${m['open'] ?? 'none'}',
        value: '${m['value'] ?? ''}'.trim(),
        freq: '${m['freq'] ?? 'once'}',
      );
}

class AppConfig {
  final List<HomeItem> circles;
  final List<HomeItem> rails;
  final PopupConfig? popup;
  const AppConfig({required this.circles, required this.rails, this.popup});

  factory AppConfig.fromJson(Map<String, dynamic> m) {
    List<HomeItem> list(String k, String labelKey) => (m[k] is List ? m[k] as List : const [])
        .whereType<Map>()
        .map((e) => HomeItem.fromJson(e, labelKey))
        .where((e) => e.type != 'category' || e.id != null)
        .toList();
    return AppConfig(
      circles: list('circles', 'label'),
      rails: list('rails', 'title'),
      popup: m['popup'] is Map ? PopupConfig.fromJson(m['popup'] as Map) : null,
    );
  }
}

class RemoteConfig {
  RemoteConfig._();
  static final instance = RemoteConfig._();

  static const _cacheKey = 'remote_config_v1';

  /// null = نستخدم الترتيب الافتراضي المبني في التطبيق.
  final config = ValueNotifier<AppConfig?>(null);
  Future<void>? _loading;

  /// يحمّل النسخة المحفوظة فورًا ثم يجلب الأحدث من اللوحة.
  Future<void> ensure() => _loading ??= _load();

  Future<void> _load() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) _apply(cached);
    } catch (_) {}
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final req = await client.getUrl(Uri.parse(remoteConfigUrl));
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        if (_apply(body)) await prefs?.setString(_cacheKey, body);
      }
      client.close();
    } catch (_) {
      // بدون إنترنت: تبقى النسخة المحفوظة أو الافتراضية
    }
  }

  bool _apply(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return false;
      config.value = AppConfig.fromJson(Map<String, dynamic>.from(m));
      return true;
    } catch (_) {
      return false;
    }
  }
}
