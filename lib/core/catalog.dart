import 'package:flutter/material.dart';

class StoreCategory {
  final int id;
  final String name;
  final IconData icon;
  final List<StoreCategory> children;

  const StoreCategory(this.id, this.name, this.icon, [this.children = const []]);
}

const menPerfumes = StoreCategory(636667848, 'عطور رجالية', Icons.man_outlined);
const womenPerfumes = StoreCategory(2011162313, 'عطور نسائية', Icons.woman_outlined);
const unisexPerfumes = StoreCategory(886820816, 'للجنسين', Icons.wc_outlined, [
  StoreCategory(1783479303, 'عطور الجسم', Icons.water_drop_outlined),
]);
const oud = StoreCategory(781738507, 'العود والبخور', Icons.local_fire_department_outlined);
const cosmetics = StoreCategory(952945814, 'مستحضرات التجميل', Icons.face_retouching_natural, [
  StoreCategory(1935632650, 'أحمر الشفاه', Icons.brush_outlined),
  StoreCategory(666982592, 'كريم أساس', Icons.opacity),
  StoreCategory(1723150419, 'الماسكرا', Icons.remove_red_eye_outlined),
  StoreCategory(971641143, 'طلاء الأظافر', Icons.colorize_outlined),
  StoreCategory(1590276103, 'أدوات المكياج', Icons.handyman_outlined),
]);
const care = StoreCategory(1860677013, 'العناية', Icons.spa_outlined, [
  StoreCategory(2020370844, 'السيروم', Icons.science_outlined),
]);
const hairPerfumes = StoreCategory(111210193, 'عطور الشعر', Icons.air);
const alternatives = StoreCategory(138908188, 'عطور بديلة', Icons.swap_horiz);
const lenses = StoreCategory(769323888, 'العدسات', Icons.visibility_outlined);
const lashes = StoreCategory(315372818, 'الرموش', Icons.auto_awesome_outlined);

const allCategories = <StoreCategory>[
  menPerfumes,
  womenPerfumes,
  unisexPerfumes,
  oud,
  cosmetics,
  care,
  hairPerfumes,
  alternatives,
  lenses,
  lashes,
];

const homeSections = <StoreCategory>[menPerfumes, womenPerfumes, oud, cosmetics, care];
