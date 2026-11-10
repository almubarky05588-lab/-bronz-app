import 'cart.dart';
import 'product.dart';
import 'push.dart';
import 'store_bridge.dart';
import 'util.dart';
import '../widgets/banner_carousel.dart' show resolveStoreLink;

/// نتيجة التحقق من رمز الدخول.
enum VerifyResult { authenticated, newCustomer }

/// خطوة الدفع التالية كما تحددها سلة.
class CheckoutStep {
  final String? to; // checkout | login | refresh
  final String? url;
  final List<String> failedItems;
  const CheckoutStep(this.to, this.url, this.failedItems);
  bool get needsLogin => to == 'login';
  bool get ready => to == 'checkout' && (url?.isNotEmpty ?? false);
}

/// بانر من بانرات الصفحة الرئيسية في المتجر.
class StoreBanner {
  final String image;
  final String? link;
  const StoreBanner(this.image, this.link);
}

/// كل ما تحتاجه الشاشات من المتجر — عبر مكتبة سلة الرسمية في طبقة الربط.
class StoreApi {
  static final _b = StoreBridge.instance;

  // ───────── المنتجات ─────────

  /// روابط الصفحات التالية كما ترجعها سلة (ترقيم بالمؤشر cursor).
  /// المفتاح: «مصدر|قيمة|رقم الصفحة» — القيمة '' تعني ما فيه صفحات بعدها.
  static final _next = <String, String>{};

  static String? _pickUrl(dynamic v) => (v is String && v.startsWith('http')) ? v : null;

  /// يقرأ رابط الصفحة التالية من رد سلة بأي صيغة معروفة.
  /// يرجع null لو الرد ما فيه ترقيم أصلًا، و'' لو فيه ترقيم بس هذي آخر صفحة.
  static String? _nextUrl(dynamic res) {
    if (res is! Map) return null;
    var paged = false;
    for (final k in const ['cursor', 'pagination', 'links']) {
      final m = res[k];
      if (m is! Map) continue;
      paged = true;
      final links = m['links'];
      final n = _pickUrl(m['next']) ??
          _pickUrl(m['next_page_url']) ??
          (links is Map ? _pickUrl(links['next']) : null);
      if (n != null) return n;
    }
    final n = _pickUrl(res['next_page_url']) ?? _pickUrl(res['next']);
    if (n != null) return n;
    return paged ? '' : null;
  }

  /// يجيب صفحة: أول صفحة بالطلب العادي، وبعدها برابط «التالي» من سلة إن وُجد.
  static Future<List<Product>> _page(String key, int page, Future<dynamic> Function() first) async {
    final dynamic res;
    final known = page > 1 ? _next['$key|$page'] : null;
    if (known == '') return const []; // وصلنا لآخر صفحة
    res = known != null ? await _b.get(known) : await first();
    final n = _nextUrl(res);
    if (n != null) _next['$key|${page + 1}'] = n;
    return extractList(res)
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id != 0 && !giftProductIds.contains(p.id)) // خدمات التغليف تظهر في شاشة الهدية فقط
        .toList();
  }

  static Future<List<Product>> _list(String source, {Object? value, int page = 1}) =>
      _page('$source|${value ?? ''}', page, () => _b.call('products', {
            'source': source,
            if (value != null) 'value': value,
            if (page > 1) 'page': page,
          }));

  /// ترتيب خاص من سلة (الأكثر مبيعًا / الأعلى تقييمًا) عبر واجهة المتجر نفسها.
  static Future<List<Product>> _sorted(String sort, int page) => _page(
        'sorted|$sort',
        page,
        () => _b.get('products?source=latest&sort=$sort${page > 1 ? '&page=$page' : ''}'),
      );

  /// هل القائمة هي نفسها «وصل حديثًا»؟ (سلة تتجاهل الترتيب أحيانًا وترجع الأحدث)
  static Future<bool> _sameAsLatest(List<Product> l) async {
    if (l.isEmpty) return false;
    try {
      final fresh = await latest();
      final n = l.length < 6 ? l.length : 6;
      if (fresh.length < n) return false;
      for (var i = 0; i < n; i++) {
        if (fresh[i].id != l[i].id) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// «الأكثر مبيعًا» — قائمة مختارة يدويًا بالترتيب (رقم المنتج في سلة).
  /// لتعديلها: غيّر الأرقام هنا.
  static const featuredIds = <int>[
    729976151, // فيراري ايسنس
    // ايفن
    1622566670, 1816822432, 900640946, 266544262, 1820438499, 1012232434,
    // ارماف كلوب دي نوي
    50146272, 1171656101, 1490244479, 1289708302, 1449373818,
    // هوس — الرصاصي
    1333357884, 1010722460,
    // سير فرانسيس
    1996180, 1877815053, 458801895, 243240173,
  ];

  static Future<List<Product>>? _featured;

  static Future<List<Product>> bestSellers({int page = 1}) async {
    if (page > 1) return const [];
    final l = await (_featured ??= _loadFeatured());
    if (l.isEmpty) _featured = null; // نعيد المحاولة المرة الجاية
    return l;
  }

  /// يجيب المنتجات المختارة على دفعات صغيرة ويحافظ على ترتيبها،
  /// ويتخطى أي منتج محذوف أو فشل تحميله.
  static Future<List<Product>> _loadFeatured() async {
    final out = <Product>[];
    for (var i = 0; i < featuredIds.length; i += 6) {
      final batch = featuredIds.skip(i).take(6);
      final res = await Future.wait(batch.map((id) async {
        try {
          final p = await details(id);
          return (p.id != 0 && p.image.isNotEmpty) ? p : null;
        } catch (_) {
          return null;
        }
      }));
      out.addAll(res.whereType<Product>());
    }
    return out;
  }

  /// الأعلى تقييمًا — بنفس الحماية من التكرار.
  static Future<List<Product>> topRated({int page = 1}) async {
    try {
      final l = await _sorted('topRated', page);
      if (page == 1 && await _sameAsLatest(l)) return const [];
      return l;
    } catch (_) {
      return const [];
    }
  }

  /// يجمع صفحات متتالية لين يوصل للعدد المطلوب (حد أقصى 4 صفحات).
  static Future<List<Product>> take(Future<List<Product>> Function(int page) loader, int count) async {
    final out = <Product>[];
    final seen = <int>{};
    for (var page = 1; page <= 4 && out.length < count; page++) {
      final list = await loader(page);
      if (list.isEmpty) break;
      final before = out.length;
      for (final p in list) {
        if (seen.add(p.id)) out.add(p);
      }
      if (out.length == before) break; // الصفحة ما جابت جديد
    }
    return out.length > count ? out.sublist(0, count) : out;
  }

  static Future<List<Product>> latest({int page = 1}) => _list('latest', page: page);

  static Future<List<Product>> byCategory(int id, {int page = 1}) =>
      _list('categories', value: id, page: page);

  static Future<List<Product>> search(String q, {int page = 1}) =>
      _list('search', value: q, page: page);

  static Future<List<Product>> offers({int page = 1}) => _list('offers', page: page);

  static final _linkIds = <String, int>{};

  /// رقم المنتج من رابطه (الكامل أو المختصر) — المختصر يُقرأ من صفحة المنتج.
  static Future<int?> idFromLink(String link) async {
    final l = link.trim();
    if (l.isEmpty) return null;
    final known = _linkIds[l];
    if (known != null) return known;
    int? id = int.tryParse(l) ?? int.tryParse(RegExp(r'/p(\d+)(?:$|[/?#])').firstMatch(l)?.group(1) ?? '');
    if (id == null && l.startsWith('http')) {
      final full = await resolveStoreLink(l);
      id = int.tryParse(RegExp(r'/p(\d+)(?:$|[/?#])').firstMatch(full ?? '')?.group(1) ?? '');
    }
    if (id != null) _linkIds[l] = id;
    return id;
  }

  /// منتجات مختارة بروابطها، بنفس ترتيب الروابط.
  static Future<List<Product>> byLinks(List<String> links) async {
    final ids = <int>[];
    for (final id in await Future.wait(links.map(idFromLink))) {
      if (id != null && !ids.contains(id)) ids.add(id);
    }
    if (ids.isEmpty) return const [];
    var found = <Product>[];
    try {
      found = await _page('selected|${ids.join(',')}', 1, () => _b.call('products', {'source': 'selected', 'value': ids}));
    } catch (_) {}
    final byId = {for (final p in found) p.id: p};
    // اللي ما رجع من القائمة نجيبه بالتفاصيل
    for (final id in ids.where((i) => !byId.containsKey(i))) {
      try {
        final p = await details(id);
        if (p.id != 0) byId[id] = p;
      } catch (_) {}
    }
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  /// منتجات ماركة (أو أي قائمة أرقام) صفحة صفحة، بنفس ترتيب الأرقام.
  static Future<List<Product>> byIds(List<int> ids, {int page = 1, int perPage = 20}) async {
    final start = (page - 1) * perPage;
    if (start >= ids.length) return const [];
    final end = start + perPage < ids.length ? start + perPage : ids.length;
    final slice = ids.sublist(start, end);
    var found = <Product>[];
    try {
      found = await _page('ids|${slice.join(',')}', 1, () => _b.call('products', {'source': 'selected', 'value': slice}));
    } catch (_) {}
    final byId = {for (final p in found) p.id: p};
    return [for (final id in slice) if (byId[id] != null) byId[id]!];
  }

  /// التفاصيل الكاملة: الوصف، كل الصور، الماركة، التقييم، التصنيف.
  static Future<Product> details(int id) async {
    final res = await _b.call('details', {'id': id});
    return Product.fromJson(extractMap(res));
  }

  // ───────── الواجهة ─────────

  static Future<List<StoreBanner>>? _banners;

  /// بانرات رئيسية المتجر نفسها — أي تغيير في لوحة سلة يظهر في التطبيق.
  static Future<List<StoreBanner>> banners() => _banners ??= _loadBanners();

  static Future<List<StoreBanner>> _loadBanners() async {
    try {
      final res = await _b.call('banners', const {}, 20);
      if (res is! List) return const [];
      return res
          .whereType<Map>()
          .map((m) => StoreBanner('${m['image'] ?? ''}', m['link'] as String?))
          .where((b) => b.image.startsWith('http'))
          .toList();
    } catch (_) {
      _banners = null;
      return const [];
    }
  }

  static final _covers = <int, Future<String>>{};
  static final _usedCovers = <String>{};
  static Future<void> _coverChain = Future.value();

  /// صورة غلاف القسم: أول منتج فيه لم تُستخدم صورته غلافًا لقسم آخر،
  /// حتى لا تتكرر نفس الصورة في رجالي ونسائي وللجنسين.
  /// الأقسام تُحسب بالترتيب (سلسلة) ليكون الاختيار ثابتًا.
  static Future<String> categoryCover(int id) => _covers.putIfAbsent(id, () {
        final f = _coverChain.then((_) => _pickCover(id));
        _coverChain = f.then((_) {}, onError: (_) {});
        return f;
      });

  static const _unisexIds = {886820816, 1783479303};

  static Future<String> _pickCover(int id) async {
    try {
      final list = (await byCategory(id)).where((p) => p.image.isNotEmpty).toList();
      if (list.isEmpty) return '';
      final unisexCat = _unisexIds.contains(id);
      bool fits(Product p) => unisexCat || !p.name.contains('للجنسين');
      final pick = list.firstWhere(
        (p) => !_usedCovers.contains(p.image) && fits(p),
        orElse: () => list.firstWhere(
          (p) => !_usedCovers.contains(p.image),
          orElse: () => list.first,
        ),
      );
      _usedCovers.add(pick.image);
      return pick.image;
    } catch (_) {
      _covers.remove(id);
      return '';
    }
  }

  // ───────── حساب العميل ─────────

  /// رقم الجوال بصيغة سلة: 5xxxxxxxx (بدون صفر ولا 966).
  static String normalizePhone(String input) {
    var p = input.replaceAll(RegExp(r'[^0-9٠-٩]'), '');
    const ar = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      p = p.replaceAll(ar[i], '$i');
    }
    if (p.startsWith('00966')) p = p.substring(5);
    if (p.startsWith('966')) p = p.substring(3);
    if (p.startsWith('0')) p = p.substring(1);
    return p;
  }

  static bool isValidPhone(String phone) => RegExp(r'^5\d{8}$').hasMatch(phone);

  static Future<bool> isLoggedIn() async {
    try {
      final res = await _b.call('me');
      return res is Map && res['guest'] == false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> customerName() async {
    try {
      final res = await _b.call('me');
      final u = res is Map ? res['user'] : null;
      if (u is Map) return '${u['first_name'] ?? u['name'] ?? ''}'.trim();
    } catch (_) {}
    return null;
  }

  /// يرسل رمز التحقق للجوال ويرجع رسالة سلة (قناة الإرسال/التنبيه) لعرضها للعميل.
  static Future<String> sendCode(String phone) async => _msg(await _b.call('login', {'phone': phone}));

  static Future<String> resendCode(String phone) async => _msg(await _b.call('resend', {'phone': phone}));

  static String _msg(dynamic res) {
    if (res is! Map) return '';
    final d = res['data'];
    for (final v in [res['message'], if (d is Map) d['message'], if (d is Map) d['msg']]) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  static Future<VerifyResult> verifyCode(String phone, String code) async {
    final res = await _b.call('verify', {'phone': phone, 'code': code});
    final data = res is Map ? res['data'] : null;
    final c = data is Map ? '${data['case']}' : '';
    if (c == 'new_customer') return VerifyResult.newCustomer;
    await _b.refreshSession();
    await Push.identify();
    return VerifyResult.authenticated;
  }

  /// تسجيل عميل جديد بعد التحقق من رمزه.
  static Future<void> register({
    required String phone,
    required String code,
    required String firstName,
    required String lastName,
    String? email,
  }) async {
    await _b.call('register', {
      'phone': phone,
      'code': code,
      'first': firstName,
      'last': lastName,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    await _b.refreshSession();
    await Push.identify();
  }

  static Future<void> logout() async {
    Push.forget();
    await _b.clearSession();
  }

  // ───────── الدفع ─────────

  /// ينقل سلة التطبيق إلى سلة المتجر ثم يطلب من سلة رابط صفحة الدفع.
  static Future<CheckoutStep> prepareCheckout() async {
    final items = Cart.instance.items
        .map((e) => {'id': e.id, 'qty': e.qty, 'name': e.name})
        .toList();
    final sync = await _b.call('syncCart', {'items': items}, 90);
    final failed = <String>[];
    if (sync is Map && sync['failed'] is List) {
      for (final f in sync['failed'] as List) {
        if (f is Map) failed.add('${f['name']}');
      }
    }
    final step = await _b.call('checkoutUrl');
    final m = step is Map ? step : const {};
    return CheckoutStep(m['to'] as String?, m['url'] as String?, failed);
  }
}
