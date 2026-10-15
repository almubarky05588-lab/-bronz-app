import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BronzColors {
  static const ink = Color(0xFF111111);
  static const gold = Color(0xFFB08D57);
  static const goldSoft = Color(0xFFE9DCC6);
  static const bg = Color(0xFFFAF8F5);
  static const card = Colors.white;
  static const muted = Color(0xFF8A8580);
  static const soft = Color(0xFFF1EDE7);
  static const tile = Color(0xFFF6F4F1);
  static const line = Color(0xFFEFEBE5);
  static const sale = Color(0xFFB3261E);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BronzColors.ink,
      primary: BronzColors.ink,
      secondary: BronzColors.gold,
      surface: BronzColors.bg,
    ),
    scaffoldBackgroundColor: BronzColors.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: GoogleFonts.tajawalTextTheme(base.textTheme).apply(
      bodyColor: BronzColors.ink,
      displayColor: BronzColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: BronzColors.bg,
      foregroundColor: BronzColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.tajawal(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: BronzColors.ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BronzColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFD9D4CC),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
