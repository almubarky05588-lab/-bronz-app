import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

// أيقونات الواجهة بنفس نمط أيقونات الشريط السفلي:
// تعبئة رمادية فاتحة + خط أسود + لمسة ذهبية.

class BrandIcons {
  BrandIcons._();

  static const _o = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke-linecap="round" stroke-linejoin="round">';
  static const _c = '</svg>';
  static const _ink = '#141414';
  static const _gold = '#C9A35A';
  static const _fill = '#E7E5E0';
  static const _cream = '#F6EBD6';

  static const bell = '$_o<path d="M24 7v3" stroke="$_gold" stroke-width="3"/>'
      '<path d="M13 34V23a11 11 0 0 1 22 0v11l3 4H10z" fill="$_fill" stroke="$_ink" stroke-width="2.6"/>'
      '<path d="M20 42.5a4.2 4.2 0 0 0 8 0" stroke="$_gold" stroke-width="3"/>$_c';

  static const search = '$_o<circle cx="21" cy="21" r="12" fill="$_fill" stroke="$_ink" stroke-width="2.6"/>'
      '<path d="M15.5 18a6.5 6.5 0 0 1 5.5-3.5" stroke="#FFFFFF" stroke-width="2.6"/>'
      '<path d="M30.5 30.5 40 40" stroke="$_gold" stroke-width="4"/>$_c';

  /// سهم الرجوع (يشير لليمين في الواجهة العربية)
  static const back = '$_o<path d="M19 11l13 13-13 13" stroke="$_ink" stroke-width="3.4"/>$_c';

  static const bag = '$_o<path d="M17 16v-2a7 7 0 0 1 14 0v2" stroke="$_gold" stroke-width="2.8"/>'
      '<path d="M9.5 16h29l-2.3 21.5A4 4 0 0 1 32.2 41H15.8a4 4 0 0 1-4-3.5z" fill="$_fill" stroke="$_ink" stroke-width="2.6"/>'
      '<path d="M19 24a5 5 0 0 0 10 0" stroke="$_ink" stroke-width="2.6"/>$_c';

  static const original = '$_o<path d="M24 5l4.6 3.4 5.7-.3 1.8 5.4 4.6 3.3-1.8 5.4 1.8 5.4-4.6 3.3-1.8 5.4-5.7-.3L24 43l-4.6-3.4-5.7.3-1.8-5.4-4.6-3.3 1.8-5.4-1.8-5.4 4.6-3.3 1.8-5.4 5.7.3z" '
      'transform="translate(0 0)" fill="$_cream" stroke="$_gold" stroke-width="2.4"/>'
      '<path d="M17.5 24.5l4.5 4.5 8.5-9" stroke="$_ink" stroke-width="3"/>$_c';

  static const truck = '$_o<path d="M5 13h22v20H5z" fill="$_fill" stroke="$_ink" stroke-width="2.6"/>'
      '<path d="M27 19h8l7 7v7H27z" fill="$_cream" stroke="$_ink" stroke-width="2.6"/>'
      '<circle cx="13" cy="35" r="4" fill="$_gold" stroke="$_ink" stroke-width="2.4"/>'
      '<circle cx="35" cy="35" r="4" fill="$_gold" stroke="$_ink" stroke-width="2.4"/>$_c';

  static const lock = '$_o<path d="M16 21v-5a8 8 0 0 1 16 0v5" stroke="$_gold" stroke-width="3"/>'
      '<rect x="10" y="21" width="28" height="21" rx="5" fill="$_fill" stroke="$_ink" stroke-width="2.6"/>'
      '<path d="M24 29v5" stroke="$_ink" stroke-width="3.2"/>$_c';

  /// إشعار «أبلغني عند التوفّر»
  static const bellPlus = '$_o<path d="M13 34V23a11 11 0 0 1 22 0v11l3 4H10z" fill="$_cream" stroke="$_ink" stroke-width="2.6"/>'
      '<path d="M20 42.5a4.2 4.2 0 0 0 8 0" stroke="$_gold" stroke-width="3"/>'
      '<path d="M24 19v10M19 24h10" stroke="$_gold" stroke-width="3"/>$_c';
}

/// أيقونة SVG من مجموعة برونز.
class BIcon extends StatelessWidget {
  final String svg;
  final double size;
  const BIcon(this.svg, {super.key, this.size = 22});

  @override
  Widget build(BuildContext context) => SvgPicture.string(svg, width: size, height: size);
}
