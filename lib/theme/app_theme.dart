// ============================================================
// app_theme.dart
// Define los colores, fuentes y estilos globales de Monedo.
// Aquí se pueden cambiar: Colore principales, paleta de colores.
// ============================================================

import 'package:flutter/material.dart';

class AppTheme {
  // ---- COLORES PRINCIPALES ----
  static const Color primaryPurple = Color(0xFF7C3AED);     // Morado principal
  static const Color darkPurple = Color(0xFF4C1D95);        // Morado oscuro
  static const Color lightPurple = Color(0xFFDDD6FE);       // Morado claro
  static const Color accentPurple = Color(0xFFA78BFA);      // Morado acento
  static const Color backgroundDark = Color(0xFF0F0F1A);    // Fondo negro
  static const Color cardDark = Color(0xFF1A1A2E);          // Tarjetas oscuras
  static const Color cardMedium = Color(0xFF16213E);        // Tarjetas medianas
  static const Color income = Color(0xFF10B981);            // Verde ingresos
  static const Color expense = Color(0xFFEF4444);           // Rojo gastos
  static const Color textPrimary = Color(0xFFFFFFFF);       // Texto principal
  static const Color textSecondary = Color(0xFF9CA3AF);     // Texto secundario

  // ---- GRADIENTES ----
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [darkPurple, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundDark, cardDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ---- TEMA PRINCIPAL ----
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: backgroundDark,

      // Colores generales
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: accentPurple,
        surface: cardDark,
        error: expense,
      ),

      // Estilo de tarjetas
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Estilo de botones principales
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Estilo de campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),

      // Estilo de textos
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
    );
  }
}