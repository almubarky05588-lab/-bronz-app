class Product {
  final int id;
  final String name;
  final double price;
  final double? oldPrice;
  final String image;
  final List<String> images;
  final String description;
  final String url;
  final bool available;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice,
    required this.image,
    required this.images,
    required this.description,
    required this.url,
    required this.available,
  });

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is Map) return _num(v['amount']);
    if (v is String) return double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), ''));
    return null;
  }

  static String _img(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map) return '${v['url'] ?? v['original'] ?? v['thumbnail'] ?? ''}';
    return '';
  }

  factory Product.fromJson(Map<String, dynamic> j) {
    final sale = _num(j['sale_price']);
    final base = _num(j['price']) ?? _num(j['starting_price']);
    final regular = _num(j['regular_price']) ?? base;
    final current = (sale != null && sale > 0) ? sale : (base ?? 0);

    final images = <String>[];
    final raw = j['images'];
    if (raw is List) {
      for (final i in raw) {
        final u = _img(i);
        if (u.isNotEmpty && !images.contains(u)) images.add(u);
      }
    }
    var image = _img(j['image']);
    if (image.isEmpty) image = _img(j['thumbnail']);
    if (image.isEmpty && images.isNotEmpty) image = images.first;
    if (images.isEmpty && image.isNotEmpty) images.add(image);

    final status = '${j['status'] ?? ''}';
    final avail = j['is_available'];

    return Product(
      id: int.tryParse('${j['id']}') ?? 0,
      name: '${j['name'] ?? ''}'.trim(),
      price: current,
      oldPrice: (regular != null && regular > current) ? regular : null,
      image: image,
      images: images,
      description: '${j['description'] ?? ''}',
      url: '${j['url'] ?? ''}',
      available: avail is bool ? avail : (status.isEmpty || status == 'sale'),
    );
  }

  Product mergedWith(Product fallback) => Product(
        id: id != 0 ? id : fallback.id,
        name: name.isNotEmpty ? name : fallback.name,
        price: price > 0 ? price : fallback.price,
        oldPrice: oldPrice ?? fallback.oldPrice,
        image: image.isNotEmpty ? image : fallback.image,
        images: images.isNotEmpty ? images : fallback.images,
        description: description.isNotEmpty ? description : fallback.description,
        url: url.isNotEmpty ? url : fallback.url,
        available: available,
      );
}
