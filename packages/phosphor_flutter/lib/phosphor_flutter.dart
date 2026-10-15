/// أيقونات برونز.
///
/// مكتبة Phosphor الأصلية لا تتوافق مع إصدار Flutter الحالي (IconData صار final)،
/// فهذه طبقة بنفس الأسماء ترجع أيقونات آبل (SF-style) الرفيعة المدمجة.
/// كل القيم const حتى يعمل تقليص خطوط الأيقونات في نسخة الإصدار.
library phosphor_flutter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum PhosphorIconsStyle { regular, thin, light, bold, fill, duotone }

class PhosphorIcons {
  PhosphorIcons._();

  static bool _f(PhosphorIconsStyle s) => s == PhosphorIconsStyle.fill;

  static IconData house([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      _f(s) ? CupertinoIcons.house_fill : CupertinoIcons.house;

  static IconData squaresFour([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      _f(s) ? CupertinoIcons.square_grid_2x2_fill : CupertinoIcons.square_grid_2x2;

  static IconData handbag([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      _f(s) ? CupertinoIcons.bag_fill : CupertinoIcons.bag;

  static IconData user([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      _f(s) ? CupertinoIcons.person_fill : CupertinoIcons.person;

  static IconData magnifyingGlass([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      CupertinoIcons.search;

  static IconData bell([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      _f(s) ? CupertinoIcons.bell_fill : CupertinoIcons.bell;

  static IconData bellSimple([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      _f(s) ? CupertinoIcons.bell_fill : CupertinoIcons.bell;

  static IconData heart([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      _f(s) ? CupertinoIcons.heart_fill : CupertinoIcons.heart;

  /// سهم «التالي / عرض الكل» — يُعكس تلقائيًا فيشير لليسار في العربي
  static IconData caretLeft([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      Icons.arrow_forward_ios_rounded;

  /// سهم «الرجوع» — يُعكس تلقائيًا فيشير لليمين في العربي
  static IconData caretRight([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      Icons.arrow_back_ios_new_rounded;

  static IconData plus([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => CupertinoIcons.add;

  static IconData minus([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => CupertinoIcons.minus;

  static IconData trash([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => CupertinoIcons.trash;

  static IconData sealCheck([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      CupertinoIcons.checkmark_seal;

  static IconData truck([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      Icons.local_shipping_outlined;

  static IconData lock([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => CupertinoIcons.lock;

  static IconData lockSimple([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      CupertinoIcons.lock;

  static IconData percent([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      CupertinoIcons.percent;

  static IconData sparkle([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      CupertinoIcons.sparkles;

  static IconData signOut([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      Icons.logout_rounded;

  static IconData checkCircle([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      _f(s) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.checkmark_circle;

  static IconData check([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      CupertinoIcons.checkmark;

  static IconData image([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => CupertinoIcons.photo;

  static IconData imageBroken([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      Icons.broken_image_outlined;

  static IconData wifiSlash([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      CupertinoIcons.wifi_slash;

  static IconData package([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) =>
      CupertinoIcons.cube_box;
}
