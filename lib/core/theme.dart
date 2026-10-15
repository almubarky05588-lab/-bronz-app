import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BronzColors {
  static const ink = Color(0xFF111111);
  static const gold = Color(0xFFB08D57);
  static const bg = Color(0xFFFAF8F5);
  static const card = Colors.white;
  static const muted = Color(0xFF8A8580);
  static const soft = Color(0xFFF1EDE7);
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
  );
  return base.copyWith(
    textTheme: GoogleFonts.tajawalTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: BronzColors.bg,
      foregroundColor: BronzColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: BronzColors.soft,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BronzColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
