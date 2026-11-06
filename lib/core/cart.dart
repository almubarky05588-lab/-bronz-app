import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product.dart';

/// منتجات خدمة «التغليف كهدية» في سلة — تُعرض في شاشة الهدية فقط (مخفية من القوائم).
const giftWrapId = 1261550203; // تغليف هدية
const giftFlowersId = 1618655396; // تغليف هدية مع ورد وشكولاته (الرياض فقط)
const giftProductIds = {giftWrapId, giftFlowersId};

class CartItem {
  final int id;
  final String name;
  final String image;
  final double price;
  int qty;

  CartItem({required this.id, required this.name, required this.image, required this.price, required this.qty});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'image': image, 'price': price, 'qty': qty};

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: (j['id'] as num).toInt(),
        name: '${j['name']}',
        image: '${j['image']}',
        price: (j['price'] as num).toDouble(),
        qty: (j['qty'] as num).toInt(),
      );
}

class Cart extends ChangeNotifier {
  Cart._();
  static final Cart instance = Cart._();
  static const _key = 'bronz_cart_v1';
  static const _giftKey = 'bronz_gift_note_v1';

  final List<CartItem> items = [];

  /// بيانات الهدية (المستلم وجواله والرسالة) — تُرسل كملاحظة مع الطلب.
  String giftNote = '';

  CartItem? get gift => items.where((e) => giftProductIds.contains(e.id)).firstOrNull;
  bool get hasGift => gift != null;

  /// المنتجات بدون خدمة التغليف.
  List<CartItem> get goods => items.where((e) => !giftProductIds.contains(e.id)).toList();

  int get count => items.fold(0, (s, i) => s + i.qty);
  double get total => items.fold(0.0, (s, i) => s + i.price * i.qty);

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      giftNote = p.getString(_giftKey) ?? '';
      final raw = p.getString(_key);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      items
        ..clear()
        ..addAll(list.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map))));
    } catch (_) {}
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
    await p.setString(_giftKey, giftNote);
  }

  /// يضبط خدمة الهدية: منتج التغليف المختار + بيانات المستلم. null يلغي الهدية.
  void setGift(CartItem? wrap, String note) {
    items.removeWhere((e) => giftProductIds.contains(e.id));
    if (wrap != null) items.add(wrap);
    giftNote = wrap == null ? '' : note;
    _changed();
  }

  void add(Product product, {int qty = 1}) {
    final i = items.indexWhere((e) => e.id == product.id);
    if (i >= 0) {
      items[i].qty += qty;
    } else {
      items.add(CartItem(id: product.id, name: product.name, image: product.image, price: product.price, qty: qty));
    }
    _changed();
  }

  void setQty(int id, int qty) {
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    if (qty <= 0) {
      items.removeAt(i);
    } else {
      items[i].qty = qty;
    }
    _changed();
  }

  void remove(int id) {
    items.removeWhere((e) => e.id == id);
    _changed();
  }

  void clear() {
    if (items.isEmpty) return;
    items.clear();
    giftNote = '';
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }
}
