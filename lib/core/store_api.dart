import 'cart.dart';
import 'product.dart';
import 'store_bridge.dart';
import 'util.dart';

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

  static Future<List<Product>> _list(String source, {Object? value, int page = 1}) async {
    final res = await _b.call('products', {
      'source': source,
      if (value != null) 'value': value,
      if (page > 1) 'page': page,
    });
    return extractList(res)
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id != 0)
        .toList();
  }

  static Future<List<Product>> latest({int page = 1}) => _list('latest', page: page);

  static Future<List<Product>> byCategory(int id, {int page = 1}) =>
      _list('categories', value: id, page: page);

  static Future<List<Product>> search(String q, {int page = 1}) =>
      _list('search', value: q, page: page);

  static Future<List<Product>> offers({int page = 1}) => _list('offers', page: page);

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

  /// صورة غلاف القسم: صورة أول منتج فيه.
  static Future<String> categoryCover(int id) => _covers.putIfAbsent(id, () async {
        try {
          final list = await byCategory(id);
          for (final p in list) {
            if (p.image.isNotEmpty) return p.image;
          }
        } catch (_) {
          _covers.remove(id);
        }
        return '';
      });

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

  /// يرسل رمز التحقق للجوال.
  static Future<void> sendCode(String phone) => _b.call('login', {'phone': phone});

  static Future<void> resendCode(String phone) => _b.call('resend', {'phone': phone});

  static Future<VerifyResult> verifyCode(String phone, String code) async {
    final res = await _b.call('verify', {'phone': phone, 'code': code});
    final data = res is Map ? res['data'] : null;
    final c = data is Map ? '${data['case']}' : '';
    if (c == 'new_customer') return VerifyResult.newCustomer;
    await _b.refreshSession();
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
  }

  static Future<void> logout() async {
    await _b.call('logout');
    await _b.refreshSession();
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
