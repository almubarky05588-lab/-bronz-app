import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إعدادات تُدار من «لوحة برونز» (Cloudflare) بدون تحديث التطبيق:
/// قطع الرئيسية (بانرات، أيقونات، منتجات) وترتيبها، والبوب اب.
const remoteConfigUrl = 'https://bronz-push.almubarky05588.workers.dev/config';

/// وجهة أيقونة أو زر: offers | latest | best | rated | category | product | url | none
class LinkTarget {
  final String to;
  final String value;
  const LinkTarget(this.to, [this.value = '']);

  factory LinkTarget.fromJson(dynamic m) =>
      m is Map ? LinkTarget('${m['to'] ?? 'none'}', '${m['value'] ?? ''}'.trim()) : const LinkTarget('none');

  String _digits(String pattern) {
    final m = RegExp(pattern).firstMatch(value);
    if (m != null) return m.group(1)!;
    return RegExp(r'^\d+$').hasMatch(value) ? value : '';
  }

  int? get categoryId => int.tryParse(_digits(r'/c(\d+)'));

  /// بنفس صيغة بيانات الإشعار — يفتحها Push.open.
  Map<String, dynamic>? data({String title = ''}) {
    switch (to) {
      case 'offers':
      case 'latest':
      case 'best':
      case 'rated':
        return {to: '1'};
      case 'category':
        final id = _digits(r'/c(\d+)');
        return id.isEmpty ? null : {'category_id': id, 'title': title};
      case 'product':
        final id = _digits(r'/p(\d+)');
        return id.isEmpty ? (value.startsWith('http') ? {'url': value} : null) : {'product_id': id};
      case 'url':
        return value.isEmpty ? null : {'url': value};
    }
    return null;
  }
}

class IconItem {
  final String label;
  final String image;
  final LinkTarget link;
  const IconItem({this.label = '', this.image = '', this.link = const LinkTarget('none')});

  factory IconItem.fromJson(Map m) => IconItem(
        label: '${m['label'] ?? ''}'.trim(),
        image: '${m['image'] ?? ''}'.trim(),
        link: LinkTarget.fromJson(m['link']),
      );
}

/// شريحة في «البانر الذكي»: نص كبير + سطر + رقم ضخم + صورة منتج + لون خلفية.
class HeroSlide {
  final String title;
  final String sub;
  final String big;
  final String image;
  final String bg; // hex مثل #EEF1F4
  final LinkTarget link;
  const HeroSlide({
    this.title = '',
    this.sub = '',
    this.big = '',
    this.image = '',
    this.bg = '',
    this.link = const LinkTarget('none'),
  });

  factory HeroSlide.fromJson(Map m) => HeroSlide(
        title: '${m['title'] ?? ''}'.trim(),
        sub: '${m['sub'] ?? ''}'.trim(),
        big: '${m['big'] ?? ''}'.trim(),
        image: '${m['image'] ?? ''}'.trim(),
        bg: '${m['bg'] ?? ''}'.trim(),
        link: LinkTarget.fromJson(m['link']),
      );
}

/// قطعة في الرئيسية: hero | banners | features | circles | products
class HomeBlock {
  final String type;
  final bool hidden;
  final String title;
  // البانر الذكي
  final List<HeroSlide> slides;
  // أيقونات
  final int rows; // 1 صف · 2 صفين · 3 شبكة كاملة
  final List<IconItem> items;
  // منتجات
  final String source; // latest | best | rated | offers | category | custom
  final int? id;
  /// منتجات مثبّتة بروابطها (تطلع أول القائمة) — أو كل القائمة لو المصدر custom
  final List<String> links;
  final String style; // rail | grid
  final int limit;

  const HomeBlock({
    required this.type,
    this.hidden = false,
    this.title = '',
    this.slides = const [],
    this.rows = 1,
    this.items = const [],
    this.source = 'latest',
    this.id,
    this.links = const [],
    this.style = 'rail',
    this.limit = 10,
  });

  factory HomeBlock.fromJson(Map m) => HomeBlock(
        type: '${m['type'] ?? ''}',
        hidden: m['hidden'] == true,
        title: '${m['title'] ?? ''}'.trim(),
        slides: (m['slides'] is List ? m['slides'] as List : const [])
            .whereType<Map>()
            .map(HeroSlide.fromJson)
            .toList(),
        rows: (int.tryParse('${m['rows'] ?? ''}') ?? 1).clamp(1, 3),
        items: (m['items'] is List ? m['items'] as List : const [])
            .whereType<Map>()
            .map(IconItem.fromJson)
            .toList(),
        source: '${m['source'] ?? 'latest'}',
        id: int.tryParse('${m['id'] ?? ''}'),
        links: (m['links'] is List ? m['links'] as List : const [])
            .map((e) => '$e'.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        style: m['style'] == 'grid' ? 'grid' : 'rail',
        limit: (int.tryParse('${m['limit'] ?? ''}') ?? 10).clamp(2, 40),
      );
}

/// ماركة: الاسم بالإنجليزي (يظهر كشعار نصي) والعربي، وشعار اختياري، وأرقام منتجاتها.
class BrandInfo {
  final String en;
  final String ar;
  final String logo;
  final List<int> ids;
  const BrandInfo({required this.en, required this.ar, this.logo = '', this.ids = const []});

  factory BrandInfo.fromJson(Map m) => BrandInfo(
        en: '${m['en'] ?? ''}'.trim(),
        ar: '${m['ar'] ?? ''}'.trim(),
        logo: '${m['logo'] ?? ''}'.trim(),
        ids: (m['ids'] is List ? m['ids'] as List : const [])
            .map((e) => int.tryParse('$e'))
            .whereType<int>()
            .toList(),
      );

  String get title => ar.isNotEmpty ? ar : en;
}

class PopupConfig {
  final bool active;
  final String id;
  final String image;
  final String title;
  final String body;
  final String button;
  final String open; // none | offers | latest | best | product | category | url
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
  final List<HomeBlock> blocks;
  final PopupConfig? popup;
  final List<BrandInfo> brands;
  const AppConfig({required this.blocks, this.popup, this.brands = const []});

  factory AppConfig.fromJson(Map<String, dynamic> m) => AppConfig(
        blocks: (m['blocks'] is List ? m['blocks'] as List : const [])
            .whereType<Map>()
            .map(HomeBlock.fromJson)
            .where((b) => const {'hero', 'banners', 'features', 'circles', 'products', 'installments'}.contains(b.type))
            .toList(),
        popup: m['popup'] is Map ? PopupConfig.fromJson(m['popup'] as Map) : null,
        brands: (m['brands'] is List ? m['brands'] as List : const [])
            .whereType<Map>()
            .map(BrandInfo.fromJson)
            .where((b) => b.ids.isNotEmpty && (b.en.isNotEmpty || b.ar.isNotEmpty))
            .toList(),
      );
}

class RemoteConfig {
  RemoteConfig._();
  static final instance = RemoteConfig._();

  static const _cacheKey = 'remote_config_v2';

  /// null = نستخدم الترتيب الافتراضي المبني في التطبيق.
  final config = ValueNotifier<AppConfig?>(null);
  Future<void>? _loading;

  /// يحمّل النسخة المحفوظة فورًا ثم يجلب الأحدث من اللوحة.
  Future<void> ensure() => _loading ??= _load(useCache: true);

  /// يجلب الأحدث من اللوحة (عند رجوع العميل للتطبيق).
  Future<void> refresh() => _load(useCache: false);

  Future<void> _load({required bool useCache}) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final cached = useCache ? prefs.getString(_cacheKey) : null;
      if (cached != null) _apply(cached);
    } catch (_) {}
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse('$remoteConfigUrl?t=${DateTime.now().millisecondsSinceEpoch}'));
      final res = await req.close().timeout(const Duration(seconds: 12));
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
