import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color tokens ──────────────────────────────────────────────
  static const Color primary = Color(0xFF001F2D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0C3547);
  static const Color onPrimaryContainer = Color(0xFF7A9EB3);
  static const Color onPrimaryFixedVariant = Color(0xFF264B5E);

  static const Color secondary = Color(0xFF006C4B);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF96F6C8);
  static const Color onSecondaryContainer = Color(0xFF00734F);
  static const Color secondaryFixed = Color(0xFF96F6C8);
  static const Color secondaryFixedDim = Color(0xFF7AD9AD);
  static const Color onSecondaryFixed = Color(0xFF002114);
  static const Color onSecondaryFixedVariant = Color(0xFF005137);

  static const Color background = Color(0xFFFCF9F8);
  static const Color onBackground = Color(0xFF1C1B1B);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F3F2);
  static const Color surfaceContainer = Color(0xFFF0EDEC);
  static const Color surfaceContainerHigh = Color(0xFFEBE7E7);
  static const Color surfaceContainerHighest = Color(0xFFE5E2E1);
  static const Color surfaceVariant = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFF42484C);
  static const Color outlineVariant = Color(0xFFC1C7CC);
  static const Color outline = Color(0xFF72787C);

  static const Color errorRed = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Semantic aliases (backward compat) ───────────────────────
  static const Color income = secondary;
  static const Color expense = errorRed;
  static const Color textPrimary = onBackground;
  static const Color textSecondary = onSurfaceVariant;
  static const Color backgroundDark = background;
  static const Color cardDark = surfaceContainerLowest;
  static const Color cardMedium = surfaceContainer;
  static const Color primaryPurple = secondary;
  static const Color accentPurple = secondary;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Theme ────────────────────────────────────────────────────
  static ThemeData get darkTheme => lightTheme;

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: secondary,
      onPrimary: onSecondary,
      primaryContainer: secondaryContainer,
      onPrimaryContainer: onSecondaryContainer,
      secondary: primary,
      onSecondary: onPrimary,
      surface: surfaceContainerLowest,
      onSurface: onBackground,
      error: errorRed,
      onError: onPrimary,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: primary, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: primary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: primary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: primary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: onBackground),
        bodyMedium: TextStyle(color: onSurfaceVariant),
        labelLarge: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: onSurfaceVariant),
        labelSmall: TextStyle(color: onSurfaceVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceContainerLowest,
      elevation: 0,
      foregroundColor: primary,
      iconTheme: const IconThemeData(color: primary),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        elevation: 0,
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: surfaceVariant, width: 2),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: surfaceVariant, width: 2),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: secondary, width: 2),
      ),
      labelStyle: GoogleFonts.beVietnamPro(
        color: onSurfaceVariant,
        fontSize: 14,
      ),
      floatingLabelStyle: GoogleFonts.beVietnamPro(
        color: secondary,
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    ),
    cardTheme: CardTheme(
      color: surfaceContainerLowest,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceContainer,
      indicatorColor: secondaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.beVietnamPro(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}
