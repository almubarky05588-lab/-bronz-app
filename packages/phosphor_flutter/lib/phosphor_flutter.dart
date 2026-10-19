/// أيقونات برونز — خط أيقونات خاص (BronzIcons) مرسوم خطيًا بنفس أسلوب تصميم Figma.
///
/// الخط يُولَّد وقت البناء من ci/build_icons.py (fonts/BronzIcons.ttf) — نفس أسماء Phosphor
/// حتى ما تتغير أي شاشة: regular = خط رفيع · bold = خط أعرض · fill = مصمت.
library phosphor_flutter;

import 'package:flutter/widgets.dart';

enum PhosphorIconsStyle { regular, thin, light, bold, fill, duotone }

const _f = 'BronzIcons';
const _p = 'phosphor_flutter';

class PhosphorIcons {
  PhosphorIcons._();

  static IconData _pick(PhosphorIconsStyle s, IconData r, IconData b, IconData f) =>
      s == PhosphorIconsStyle.fill ? f : (s == PhosphorIconsStyle.bold ? b : r);

  static IconData house([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE900, fontFamily: _f, fontPackage: _p),
      const IconData(0xE901, fontFamily: _f, fontPackage: _p),
      const IconData(0xE902, fontFamily: _f, fontPackage: _p));

  static IconData squaresFour([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE903, fontFamily: _f, fontPackage: _p),
      const IconData(0xE904, fontFamily: _f, fontPackage: _p),
      const IconData(0xE905, fontFamily: _f, fontPackage: _p));

  static IconData handbag([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE906, fontFamily: _f, fontPackage: _p),
      const IconData(0xE907, fontFamily: _f, fontPackage: _p),
      const IconData(0xE908, fontFamily: _f, fontPackage: _p));

  static IconData user([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE909, fontFamily: _f, fontPackage: _p),
      const IconData(0xE90A, fontFamily: _f, fontPackage: _p),
      const IconData(0xE90B, fontFamily: _f, fontPackage: _p));

  static IconData magnifyingGlass([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE90C, fontFamily: _f, fontPackage: _p),
      const IconData(0xE90D, fontFamily: _f, fontPackage: _p),
      const IconData(0xE90E, fontFamily: _f, fontPackage: _p));

  static IconData bell([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE90F, fontFamily: _f, fontPackage: _p),
      const IconData(0xE910, fontFamily: _f, fontPackage: _p),
      const IconData(0xE911, fontFamily: _f, fontPackage: _p));

  static IconData heart([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE912, fontFamily: _f, fontPackage: _p),
      const IconData(0xE913, fontFamily: _f, fontPackage: _p),
      const IconData(0xE914, fontFamily: _f, fontPackage: _p));

  static IconData caretLeft([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE915, fontFamily: _f, fontPackage: _p),
      const IconData(0xE916, fontFamily: _f, fontPackage: _p),
      const IconData(0xE917, fontFamily: _f, fontPackage: _p));

  static IconData caretRight([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE918, fontFamily: _f, fontPackage: _p),
      const IconData(0xE919, fontFamily: _f, fontPackage: _p),
      const IconData(0xE91A, fontFamily: _f, fontPackage: _p));

  static IconData plus([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE91B, fontFamily: _f, fontPackage: _p),
      const IconData(0xE91C, fontFamily: _f, fontPackage: _p),
      const IconData(0xE91D, fontFamily: _f, fontPackage: _p));

  static IconData minus([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE91E, fontFamily: _f, fontPackage: _p),
      const IconData(0xE91F, fontFamily: _f, fontPackage: _p),
      const IconData(0xE920, fontFamily: _f, fontPackage: _p));

  static IconData check([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE921, fontFamily: _f, fontPackage: _p),
      const IconData(0xE922, fontFamily: _f, fontPackage: _p),
      const IconData(0xE923, fontFamily: _f, fontPackage: _p));

  static IconData trash([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE924, fontFamily: _f, fontPackage: _p),
      const IconData(0xE925, fontFamily: _f, fontPackage: _p),
      const IconData(0xE926, fontFamily: _f, fontPackage: _p));

  static IconData truck([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE927, fontFamily: _f, fontPackage: _p),
      const IconData(0xE928, fontFamily: _f, fontPackage: _p),
      const IconData(0xE929, fontFamily: _f, fontPackage: _p));

  static IconData sealCheck([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE92A, fontFamily: _f, fontPackage: _p),
      const IconData(0xE92B, fontFamily: _f, fontPackage: _p),
      const IconData(0xE92C, fontFamily: _f, fontPackage: _p));

  static IconData checkCircle([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE92D, fontFamily: _f, fontPackage: _p),
      const IconData(0xE92E, fontFamily: _f, fontPackage: _p),
      const IconData(0xE92F, fontFamily: _f, fontPackage: _p));

  static IconData lock([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE930, fontFamily: _f, fontPackage: _p),
      const IconData(0xE931, fontFamily: _f, fontPackage: _p),
      const IconData(0xE932, fontFamily: _f, fontPackage: _p));

  static IconData percent([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE933, fontFamily: _f, fontPackage: _p),
      const IconData(0xE934, fontFamily: _f, fontPackage: _p),
      const IconData(0xE935, fontFamily: _f, fontPackage: _p));

  static IconData sparkle([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE936, fontFamily: _f, fontPackage: _p),
      const IconData(0xE937, fontFamily: _f, fontPackage: _p),
      const IconData(0xE938, fontFamily: _f, fontPackage: _p));

  static IconData signOut([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE939, fontFamily: _f, fontPackage: _p),
      const IconData(0xE93A, fontFamily: _f, fontPackage: _p),
      const IconData(0xE93B, fontFamily: _f, fontPackage: _p));

  static IconData image([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE93C, fontFamily: _f, fontPackage: _p),
      const IconData(0xE93D, fontFamily: _f, fontPackage: _p),
      const IconData(0xE93E, fontFamily: _f, fontPackage: _p));

  static IconData imageBroken([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE93F, fontFamily: _f, fontPackage: _p),
      const IconData(0xE940, fontFamily: _f, fontPackage: _p),
      const IconData(0xE941, fontFamily: _f, fontPackage: _p));

  static IconData wifiSlash([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE942, fontFamily: _f, fontPackage: _p),
      const IconData(0xE943, fontFamily: _f, fontPackage: _p),
      const IconData(0xE944, fontFamily: _f, fontPackage: _p));

  static IconData package([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE945, fontFamily: _f, fontPackage: _p),
      const IconData(0xE946, fontFamily: _f, fontPackage: _p),
      const IconData(0xE947, fontFamily: _f, fontPackage: _p));

  static IconData share([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE948, fontFamily: _f, fontPackage: _p),
      const IconData(0xE949, fontFamily: _f, fontPackage: _p),
      const IconData(0xE94A, fontFamily: _f, fontPackage: _p));

  static IconData star([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE94B, fontFamily: _f, fontPackage: _p),
      const IconData(0xE94C, fontFamily: _f, fontPackage: _p),
      const IconData(0xE94D, fontFamily: _f, fontPackage: _p));

  static IconData sliders([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE94E, fontFamily: _f, fontPackage: _p),
      const IconData(0xE94F, fontFamily: _f, fontPackage: _p),
      const IconData(0xE950, fontFamily: _f, fontPackage: _p));

  static IconData receipt([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE951, fontFamily: _f, fontPackage: _p),
      const IconData(0xE952, fontFamily: _f, fontPackage: _p),
      const IconData(0xE953, fontFamily: _f, fontPackage: _p));

  static IconData chat([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE954, fontFamily: _f, fontPackage: _p),
      const IconData(0xE955, fontFamily: _f, fontPackage: _p),
      const IconData(0xE956, fontFamily: _f, fontPackage: _p));

  static IconData shield([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE957, fontFamily: _f, fontPackage: _p),
      const IconData(0xE958, fontFamily: _f, fontPackage: _p),
      const IconData(0xE959, fontFamily: _f, fontPackage: _p));

  static IconData x([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => _pick(s,
      const IconData(0xE95A, fontFamily: _f, fontPackage: _p),
      const IconData(0xE95B, fontFamily: _f, fontPackage: _p),
      const IconData(0xE95C, fontFamily: _f, fontPackage: _p));

  static IconData bellSimple([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => bell(s);

  static IconData lockSimple([PhosphorIconsStyle s = PhosphorIconsStyle.regular]) => lock(s);
}
