import 'product.dart';
import 'store_bridge.dart';
import 'util.dart';

class StoreApi {
  static String _pg(int p) => p > 1 ? '&page=$p' : '';

  static Future<List<Product>> _list(String path) async {
    final res = await StoreBridge.instance.get(path);
    return extractList(res)
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id != 0)
        .toList();
  }

  static Future<List<Product>> latest({int page = 1}) =>
      _list('products?source=latest${_pg(page)}');

  static Future<List<Product>> byCategory(int id, {int page = 1}) =>
      _list('products?source=categories&source_value[]=$id${_pg(page)}');

  static Future<List<Product>> search(String q, {int page = 1}) =>
      _list('products?source=search&source_value=${Uri.encodeQueryComponent(q)}${_pg(page)}');

  static Future<Product> details(int id) async {
    final res = await StoreBridge.instance.get('products/$id/details');
    return Product.fromJson(extractMap(res));
  }
}
