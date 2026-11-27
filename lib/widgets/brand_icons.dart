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

  // ── دليل العطور ──
  static const scentAll = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M24 6l3.6 10.4L38 20l-10.4 3.6L24 34l-3.6-10.4L10 20l10.4-3.6z" fill="#F6EBD6" stroke="#141414" stroke-width="2.6"/><path d="M37 31l1.4 4 4 1.4-4 1.4L37 42l-1.4-4-4-1.4 4-1.4z" fill="#C9A35A" stroke="#C9A35A" stroke-width="1.6"/></svg>';
  static const scentOud = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18h26a6 9 0 0 1 0 18H9z" fill="#E7E5E0" stroke="#141414" stroke-width="2.6"/><ellipse cx="9" cy="27" rx="5" ry="9" fill="#F6EBD6" stroke="#141414" stroke-width="2.6"/><ellipse cx="9" cy="27" rx="2" ry="4" stroke="#C9A35A" stroke-width="2.2"/><path d="M20 23h9M23 31h8" stroke="#C9A35A" stroke-width="2.4"/></svg>';
  static const scentFloral = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke-linecap="round" stroke-linejoin="round"><g fill="#E7E5E0" stroke="#141414" stroke-width="2.4"><circle cx="24" cy="13" r="7"/><circle cx="34.5" cy="20.5" r="7"/><circle cx="30.5" cy="33" r="7"/><circle cx="17.5" cy="33" r="7"/><circle cx="13.5" cy="20.5" r="7"/></g><circle cx="24" cy="24" r="5.5" fill="#C9A35A" stroke="#141414" stroke-width="2.4"/></svg>';
  static const scentSweet = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18h18l-2.5 22a3 3 0 0 1-3 2.6h-7a3 3 0 0 1-3-2.6z" fill="#E7E5E0" stroke="#141414" stroke-width="2.6"/><path d="M13 18c0-6 5-10 11-10s11 4 11 10" fill="#F6EBD6" stroke="#141414" stroke-width="2.6"/><path d="M24 8V4" stroke="#C9A35A" stroke-width="3"/><path d="M19 26l2 12M27 26l-1 12" stroke="#C9A35A" stroke-width="2.2"/></svg>';
  static const scentMusk = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M24 6c6 8 12 14 12 21a12 12 0 0 1-24 0c0-7 6-13 12-21z" fill="#E7E5E0" stroke="#141414" stroke-width="2.6"/><path d="M18 28a6 6 0 0 0 5 6" stroke="#FFFFFF" stroke-width="3"/><circle cx="36" cy="10" r="2.5" fill="#C9A35A"/><circle cx="41" cy="17" r="1.6" fill="#C9A35A"/></svg>';
  static const scentFresh = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke-linecap="round" stroke-linejoin="round"><circle cx="24" cy="24" r="16" fill="#F6EBD6" stroke="#141414" stroke-width="2.6"/><circle cx="24" cy="24" r="11" stroke="#C9A35A" stroke-width="2"/><path d="M24 13v22M13 24h22M16.2 16.2l15.6 15.6M31.8 16.2 16.2 31.8" stroke="#C9A35A" stroke-width="2"/><circle cx="24" cy="24" r="2" fill="#141414"/></svg>';
  static const scentWoody = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M24 5l9 12h-5l8 10h-5l7 9H10l7-9h-5l8-10h-5z" fill="#E7E5E0" stroke="#141414" stroke-width="2.6"/><path d="M24 36v7" stroke="#C9A35A" stroke-width="3.4"/><circle cx="20" cy="24" r="1.6" fill="#C9A35A"/><circle cx="28" cy="29" r="1.6" fill="#C9A35A"/></svg>';
  static const bottleGold = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6h8v6h-8z" fill="#C9A35A" stroke="#C9A35A" stroke-width="2"/><path d="M18 12h12" stroke="#C9A35A" stroke-width="2.6"/><rect x="11" y="16" width="26" height="26" rx="7" stroke="#C9A35A" stroke-width="2.6"/><path d="M17 26h14" stroke="#C9A35A" stroke-width="2" opacity=".6"/><path d="M38 6l1 2.6 2.6 1-2.6 1L38 13l-1-2.4-2.6-1 2.6-1z" fill="#C9A35A"/></svg>';

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
