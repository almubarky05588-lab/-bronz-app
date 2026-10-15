import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product.dart';

/// المفضلة — محفوظة على جهاز العميل.
class Favorites extends ChangeNotifier {
  Favorites._();
  static final Favorites instance = Favorites._();
  static const _key = 'bronz_favs_v1';

  final List<Product> items = [];

  bool contains(int id) => items.any((e) => e.id == id);

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      items
        ..clear()
        ..addAll(list.whereType<Map>().map((e) => Product.fromJson(Map<String, dynamic>.from(e))));
    } catch (_) {}
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  void toggle(Product product) {
    final i = items.indexWhere((e) => e.id == product.id);
    if (i >= 0) {
      items.removeAt(i);
    } else {
      items.insert(0, product);
    }
    notifyListeners();
    _save();
  }
}
