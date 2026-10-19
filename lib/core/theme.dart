import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// هوية برونز v2 — أسود وأبيض فاخر (مطابقة لتصميم Figma «برونز — تصميم التطبيق v2»).
class BronzColors {
  static const ink = Color(0xFF0B0B0B); // النص والأزرار الأساسية
  static const gold = Color(0xFF8C8C88); // لون مساند محايد (كان ذهبيًا)
  static const goldSoft = Color(0xFFBDBDB8); // نص ثانوي فوق الخلفيات الداكنة
  static const bg = Color(0xFFFFFFFF); // خلفية الشاشات
  static const card = Colors.white;
  static const muted = Color(0xFF6F6F6C); // نص ثانوي
  static const faint = Color(0xFFA8A8A4); // نص خافت / أيقونات غير نشطة
  static const soft = Color(0xFFF4F4F2); // خلفيات البطاقات والحقول
  static const tile = Color(0xFFF4F4F2); // خلفية صور المنتجات
  static const line = Color(0xFFE6E6E3); // الحدود والفواصل
  static const sale = Color(0xFF0B0B0B); // شارة الخصم (أسود)
}

/// الزوايا والمسافات الموحّدة.
class BronzRadius {
  static const field = 16.0;
  static const tile = 20.0;
  static const card = 22.0;
  static const hero = 24.0;
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BronzColors.ink,
      primary: BronzColors.ink,
      secondary: BronzColors.muted,
      surface: BronzColors.bg,
    ),
    scaffoldBackgroundColor: BronzColors.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    dividerColor: BronzColors.line,
  );
  return base.copyWith(
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: BronzColors.ink,
      displayColor: BronzColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: BronzColors.bg,
      foregroundColor: BronzColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700, color: BronzColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BronzColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFD6D6D3),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BronzColors.ink,
        side: const BorderSide(color: BronzColors.line),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BronzColors.soft,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(BronzRadius.field), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BronzRadius.field), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BronzRadius.field),
        borderSide: const BorderSide(color: BronzColors.ink, width: 1.2),
      ),
      hintStyle: const TextStyle(color: BronzColors.faint),
    ),
  );
}
