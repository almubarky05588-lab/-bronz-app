String formatPrice(double v) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  return '$s ر.س';
}

String stripHtml(String html) {
  var t = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
  t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return t.trim();
}

List<dynamic> extractList(dynamic res) {
  if (res is List) return res;
  if (res is Map) {
    final d = res['data'];
    if (d is List) return d;
    if (d is Map) return extractList(d);
    final p = res['products'];
    if (p is List) return p;
  }
  return const [];
}

Map<String, dynamic> extractMap(dynamic res) {
  if (res is Map) {
    if (res.containsKey('id') && res.containsKey('name')) {
      return Map<String, dynamic>.from(res);
    }
    final d = res['data'];
    if (d is Map) return extractMap(d);
    return Map<String, dynamic>.from(res);
  }
  return <String, dynamic>{};
}
