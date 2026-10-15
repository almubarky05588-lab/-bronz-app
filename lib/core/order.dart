import 'store_bridge.dart';
import 'util.dart';

double? _n(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is Map) return _n(v['amount']);
  if (v is String) return double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), ''));
  return null;
}

String _s(dynamic v) => v == null ? '' : '$v'.trim();

String _img(dynamic v) {
  if (v is String) return v;
  if (v is Map) return _s(v['url'] ?? v['thumbnail'] ?? v['original']);
  return '';
}

/// سطر في فاتورة الطلب.
class OrderLine {
  final String name;
  final int qty;
  final double? price;
  final double? total;
  final String image;
  const OrderLine({required this.name, required this.qty, this.price, this.total, required this.image});

  factory OrderLine.fromJson(Map j) {
    final product = j['product'] is Map ? j['product'] as Map : const {};
    var image = _img(j['image']);
    if (image.isEmpty) image = _img(j['thumbnail']);
    if (image.isEmpty) image = _img(j['product_image']);
    if (image.isEmpty) image = _img(product['thumbnail']);
    if (image.isEmpty) image = _img(product['image']);
    final qty = int.tryParse(_s(j['quantity'])) ?? 1;
    final price = _n(j['price']) ?? _n(product['price']);
    final total = _n(j['total']) ?? (price != null ? price * qty : null);
    var name = _s(j['name']);
    if (name.isEmpty) name = _s(product['name']);
    return OrderLine(name: name, qty: qty, price: price, total: total, image: image);
  }
}

/// طلب العميل من متجر سلة.
class StoreOrder {
  final int id;
  final String number;
  final String date;
  final double? total;
  final double? subTotal;
  final double? shipping;
  final double? discount;
  final double? tax;
  final String statusName;
  final String statusSlug;
  final String payment;
  final String? address;
  final List<OrderLine> lines;

  const StoreOrder({
    required this.id,
    required this.number,
    required this.date,
    this.total,
    this.subTotal,
    this.shipping,
    this.discount,
    this.tax,
    required this.statusName,
    required this.statusSlug,
    required this.payment,
    this.address,
    required this.lines,
  });

  factory StoreOrder.fromJson(Map<String, dynamic> j) {
    final st = j['status'] is Map ? j['status'] as Map : const {};
    final custom = st['customized'] is Map ? st['customized'] as Map : const {};
    final amounts = j['amounts'] is Map ? j['amounts'] as Map : const {};

    var date = _s(j['created_at']);
    if (date.isEmpty && j['date'] is Map) date = _s((j['date'] as Map)['date']);
    if (date.isEmpty) date = _s(j['date']);
    if (date.length >= 10) date = date.substring(0, 10).replaceAll('-', '/');

    final lines = <OrderLine>[];
    final raw = j['items'];
    if (raw is List) {
      for (final i in raw) {
        if (i is Map) lines.add(OrderLine.fromJson(i));
      }
    }

    final pay = j['payment_method'];
    final payment = pay is Map ? _s(pay['name'] ?? pay['slug']) : _s(pay);

    String? address;
    final shipping = j['shipping'];
    final ad = j['address'] ?? j['shipping_address'] ?? (shipping is Map ? shipping['address'] : null);
    if (ad is Map) {
      final parts = [ad['city'], ad['district'], ad['street_number'] ?? ad['street'], ad['description']]
          .map(_s)
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) address = parts.join('، ');
    } else if (ad is String && ad.trim().isNotEmpty) {
      address = ad.trim();
    }

    final taxRaw = amounts['tax'];
    final ref = _s(j['reference_id']);

    return StoreOrder(
      id: int.tryParse(_s(j['id'])) ?? 0,
      number: ref.isNotEmpty ? ref : _s(j['id']),
      date: date,
      total: _n(j['total']) ?? _n(amounts['total']),
      subTotal: _n(j['sub_total']) ?? _n(amounts['sub_total']),
      shipping: _n(j['shipping_cost']) ?? _n(amounts['shipping_cost']) ?? (shipping is Map ? _n(shipping['cost']) : _n(shipping)),
      discount: _n(j['discount']) ?? _n(j['total_discount']) ?? _n(amounts['discount']) ?? _n(amounts['total_discount']),
      tax: _n(j['tax']) ?? (taxRaw is Map ? _n(taxRaw['amount']) : _n(taxRaw)),
      statusName: _s(custom['name']).isNotEmpty ? _s(custom['name']) : _s(st['name']),
      statusSlug: _s(st['slug']).toLowerCase(),
      payment: payment,
      address: address,
      lines: lines,
    );
  }

  /// دمج التفاصيل الكاملة مع بيانات القائمة (الأولوية للتفاصيل).
  StoreOrder mergedWith(StoreOrder f) => StoreOrder(
        id: id != 0 ? id : f.id,
        number: number.isNotEmpty ? number : f.number,
        date: date.isNotEmpty ? date : f.date,
        total: total ?? f.total,
        subTotal: subTotal ?? f.subTotal,
        shipping: shipping ?? f.shipping,
        discount: discount ?? f.discount,
        tax: tax ?? f.tax,
        statusName: statusName.isNotEmpty ? statusName : f.statusName,
        statusSlug: statusSlug.isNotEmpty ? statusSlug : f.statusSlug,
        payment: payment.isNotEmpty ? payment : f.payment,
        address: address ?? f.address,
        lines: lines.isNotEmpty ? lines : f.lines,
      );

  bool get cancelled {
    final s = '$statusSlug $statusName';
    return s.contains('cancel') ||
        s.contains('restor') ||
        s.contains('refund') ||
        s.contains('ملغ') ||
        s.contains('مسترجع');
  }

  /// 0 استلام · 1 تجهيز · 2 جاري التوصيل · 3 تم التوصيل
  int get stage {
    final s = statusSlug;
    final n = statusName;
    if (const ['delivered', 'completed'].contains(s) ||
        n.contains('تم التوصيل') ||
        n.contains('مكتمل') ||
        n.contains('تم التسليم')) {
      return 3;
    }
    if (const ['delivering', 'shipped', 'in_transit', 'shipping'].contains(s) ||
        n.contains('جاري التوصيل') ||
        n.contains('شحن')) {
      return 2;
    }
    if (const ['in_progress', 'processing', 'ready'].contains(s) || n.contains('تنفيذ') || n.contains('تجهيز')) {
      return 1;
    }
    return 0;
  }

  String get summary {
    if (lines.isEmpty) return '';
    final first = lines.first.name;
    if (lines.length == 1) return first;
    return '$first و${lines.length - 1} منتج آخر';
  }
}

/// طلبات العميل — عبر واجهة سلة الرسمية في طبقة الربط (نفس جلسة الدخول).
class OrdersApi {
  static final _b = StoreBridge.instance;

  static Future<List<StoreOrder>> list({int page = 1}) async {
    final res = await _b.get(page > 1 ? 'orders?page=$page' : 'orders');
    return extractList(res)
        .whereType<Map>()
        .map((e) => StoreOrder.fromJson(Map<String, dynamic>.from(e)))
        .where((o) => o.id != 0)
        .toList();
  }

  static Future<StoreOrder> details(int id) async {
    final res = await _b.get('orders/$id');
    return StoreOrder.fromJson(extractMap(res));
  }

  /// رابط تتبّع الشحنة إن وُجد.
  static Future<String?> trackingUrl(int id) async {
    try {
      final res = await _b.get('orders/$id/shipments');
      final list = extractList(res);
      for (final s in list) {
        if (s is Map) {
          final u = _s(s['tracking_link'] ?? s['tracking_url'] ?? s['shipment_url'] ?? s['url']);
          if (u.startsWith('http')) return u;
        }
      }
    } catch (_) {}
    return null;
  }
}
