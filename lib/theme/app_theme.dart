import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // ── Modo oscuro ───────────────────────────────────────────────
  // `themeModeNotifier` guarda la preferencia del usuario (claro/oscuro/
  // sistema). `isDarkNotifier` guarda el brillo YA RESUELTO (si el modo es
  // "sistema", refleja el brillo actual del SO) y es lo que consultan los
  // getters de colores de abajo, para que TODA la app (que usa estos
  // tokens estáticos en vez de Theme.of(context)) se repinte reaccionando
  // a un solo notifier, igual que [CurrencyFormatter.notifier].
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);
  static final ValueNotifier<bool> isDarkNotifier = ValueNotifier<bool>(false);

  static bool get _isDark => isDarkNotifier.value;

  static const String _prefsKey = 'theme_mode';

  /// Carga la preferencia guardada (o "sistema" por defecto) y resuelve el
  /// brillo inicial. Debe esperarse antes de `runApp`.
  static Future<void> initThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    themeModeNotifier.value = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
    refreshResolvedBrightness();
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    refreshResolvedBrightness();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  /// Recalcula `isDarkNotifier` a partir del modo elegido y el brillo
  /// actual del sistema operativo. Se llama al iniciar, al cambiar el
  /// modo, y desde `didChangePlatformBrightness` cuando el modo es
  /// "sistema" y el usuario cambia el tema de su SO en caliente.
  static void refreshResolvedBrightness() {
    final platformIsDark =
        PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    isDarkNotifier.value = switch (themeModeNotifier.value) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system => platformIsDark,
    };
  }

  // ── Color tokens ──────────────────────────────────────────────
  // Los tokens marcados como "dinámicos" cambian de valor según el modo
  // claro/oscuro (ver getters más abajo): superficies, texto, y los
  // colores de marca cuando se usan como TEXTO/ÍCONO (necesitan un tono
  // más claro en fondo oscuro para no verse apagados).
  //
  // Los tokens "Fixed" se mantienen iguales en ambos modos: son para
  // rellenos sólidos (botones, indicadores, el riel de navegación de
  // escritorio, paneles de login) que siempre van pintados sobre — o
  // acompañados de — un color de contraste fijo (típicamente texto
  // blanco), así que invertirlos rompería ese contraste.

  // -- Navy (marca) — fijo, usado en paneles/appbar/gráficos "hero" --
  static const Color navyFixed = Color(0xFF001F2D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0C3547);
  static const Color onPrimaryContainer = Color(0xFF7A9EB3);
  static const Color onPrimaryFixedVariant = Color(0xFF264B5E);

  // -- Verde (marca/CTA) — relleno fijo, texto/ícono dinámico --
  static const Color successFixed = Color(0xFF006C4B);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryFixed = Color(0xFF96F6C8);
  static const Color secondaryFixedDim = Color(0xFF7AD9AD);
  static const Color onSecondaryFixed = Color(0xFF002114);
  static const Color onSecondaryFixedVariant = Color(0xFF005137);

  // -- Rojo (error) — relleno fijo para botones destructivos --
  static const Color dangerFixed = Color(0xFFBA1A1A);

  // -- Texto/superficie — dinámico (claro / oscuro) --
  static const Color _primaryLight = Color(0xFF001F2D);
  static const Color _primaryDark = Color(0xFFE7EEF2);
  static Color get primary => _isDark ? _primaryDark : _primaryLight;

  static const Color _backgroundLight = Color(0xFFFCF9F8);
  static const Color _backgroundDark = Color(0xFF10171A);
  static Color get background => _isDark ? _backgroundDark : _backgroundLight;

  static const Color _onBackgroundLight = Color(0xFF1C1B1B);
  static const Color _onBackgroundDark = Color(0xFFE4E2E0);
  static Color get onBackground =>
      _isDark ? _onBackgroundDark : _onBackgroundLight;

  static const Color _surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color _surfaceContainerLowestDark = Color(0xFF1B2226);
  static Color get surfaceContainerLowest =>
      _isDark ? _surfaceContainerLowestDark : _surfaceContainerLowestLight;

  static const Color _surfaceContainerLowLight = Color(0xFFF6F3F2);
  static const Color _surfaceContainerLowDark = Color(0xFF212A2F);
  static Color get surfaceContainerLow =>
      _isDark ? _surfaceContainerLowDark : _surfaceContainerLowLight;

  static const Color _surfaceContainerLight = Color(0xFFF0EDEC);
  static const Color _surfaceContainerDarkValue = Color(0xFF262F35);
  static Color get surfaceContainer =>
      _isDark ? _surfaceContainerDarkValue : _surfaceContainerLight;

  static const Color _surfaceContainerHighLight = Color(0xFFEBE7E7);
  static const Color _surfaceContainerHighDark = Color(0xFF2D373D);
  static Color get surfaceContainerHigh =>
      _isDark ? _surfaceContainerHighDark : _surfaceContainerHighLight;

  static const Color _surfaceContainerHighestLight = Color(0xFFE5E2E1);
  static const Color _surfaceContainerHighestDark = Color(0xFF333E44);
  static Color get surfaceContainerHighest =>
      _isDark ? _surfaceContainerHighestDark : _surfaceContainerHighestLight;

  static const Color _surfaceVariantLight = Color(0xFFE5E2E1);
  static const Color _surfaceVariantDark = Color(0xFF3A454B);
  static Color get surfaceVariant =>
      _isDark ? _surfaceVariantDark : _surfaceVariantLight;

  static const Color _onSurfaceVariantLight = Color(0xFF42484C);
  static const Color _onSurfaceVariantDark = Color(0xFFA6B0B5);
  static Color get onSurfaceVariant =>
      _isDark ? _onSurfaceVariantDark : _onSurfaceVariantLight;

  static const Color _outlineVariantLight = Color(0xFFC1C7CC);
  static const Color _outlineVariantDark = Color(0xFF3D474D);
  static Color get outlineVariant =>
      _isDark ? _outlineVariantDark : _outlineVariantLight;

  static const Color _outlineLight = Color(0xFF72787C);
  static const Color _outlineDark = Color(0xFF7E8A90);
  static Color get outline => _isDark ? _outlineDark : _outlineLight;

  // Verde como texto/ícono suelto (p.ej. "Ingresos", checks, links). En
  // claro es el mismo verde de marca; en oscuro se usa un verde menta más
  // claro (el mismo que `secondaryFixedDim`) para que no se vea apagado
  // sobre fondos oscuros.
  // Nota: se evita a propósito un verde/rojo "pastel" (tipo tono 80 de M3)
  // para que no se vea como si el color se hubiera quedado en modo claro
  // por error — se busca un acento vívido y saturado, no lavado.
  static const Color _secondaryTextLight = Color(0xFF006C4B);
  static const Color _secondaryTextDark = Color(0xFF3FB950);
  static Color get secondary =>
      _isDark ? _secondaryTextDark : _secondaryTextLight;

  static const Color _errorLight = Color(0xFFBA1A1A);
  static const Color _errorDark = Color(0xFFF85149);
  static Color get errorRed => _isDark ? _errorDark : _errorLight;

  static const Color _errorContainerLight = Color(0xFFFFDAD6);
  static const Color _errorContainerDark = Color(0xFF5C2328);
  static Color get errorContainer =>
      _isDark ? _errorContainerDark : _errorContainerLight;

  static const Color _onErrorContainerLight = Color(0xFF93000A);
  static const Color _onErrorContainerDark = Color(0xFFF85149);
  static Color get onErrorContainer =>
      _isDark ? _onErrorContainerDark : _onErrorContainerLight;

  static const Color _warningAmberLight = Color(0xFFC98500);
  static const Color _warningAmberDark = Color(0xFFD29922);
  static Color get warningAmber =>
      _isDark ? _warningAmberDark : _warningAmberLight;

  // Insignias verdes (avatar de moneda, iconos de categoría, etc.): en
  // claro, menta clarito + texto verde oscuro; en oscuro se invierte a
  // verde oscuro + menta clarito, para que no "brillen" sobre una tarjeta
  // oscura.
  static const Color _secondaryContainerLight = Color(0xFF96F6C8);
  static const Color _secondaryContainerDark = Color(0xFF1F4A3A);
  static Color get secondaryContainer =>
      _isDark ? _secondaryContainerDark : _secondaryContainerLight;

  static const Color _onSecondaryContainerLight = Color(0xFF00734F);
  static const Color _onSecondaryContainerDark = Color(0xFF8DF0C0);
  static Color get onSecondaryContainer =>
      _isDark ? _onSecondaryContainerDark : _onSecondaryContainerLight;

  // Insignia "Gasto" (contraparte navy de secondaryContainer/"Ingreso"):
  // en claro, lavado navy clarito + texto navy oscuro; en oscuro se
  // invierte a navy medio + texto celeste, para que no se pierda sobre
  // una tarjeta oscura.
  static const Color _expenseContainerLight = Color(0xFFDCE3E6);
  static const Color _expenseContainerDark = Color(0xFF25404E);
  static Color get expenseContainer =>
      _isDark ? _expenseContainerDark : _expenseContainerLight;

  static const Color _onExpenseContainerLight = Color(0xFF264B5E);
  static const Color _onExpenseContainerDark = Color(0xFF9DC4D6);
  static Color get onExpenseContainer =>
      _isDark ? _onExpenseContainerDark : _onExpenseContainerLight;

  // ── Semantic aliases (backward compat) ───────────────────────
  static Color get income => secondary;
  static Color get expense => errorRed;
  static Color get textPrimary => onBackground;
  static Color get textSecondary => onSurfaceVariant;
  static Color get backgroundDark => background;
  static Color get cardDark => surfaceContainerLowest;
  static Color get cardMedium => surfaceContainer;
  static Color get primaryPurple => secondary;
  static Color get accentPurple => secondary;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [navyFixed, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [navyFixed, primaryContainer],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Gradiente oscuro usado en las tarjetas "hero" (balance del dashboard,
  // balance total de Mis cuentas): un tono más profundo que primaryContainer
  // para que el balance destaque como el dato más importante de la pantalla.
  // Fijo en ambos modos (misma lógica que primaryGradient/backgroundGradient).
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0C3547), Color(0xFF082D3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Theme ────────────────────────────────────────────────────
  static ThemeData get lightTheme => _theme(dark: false);
  static ThemeData get darkTheme => _theme(dark: true);

  static ThemeData _theme({required bool dark}) {
    final bg = dark ? _backgroundDark : _backgroundLight;
    final onBg = dark ? _onBackgroundDark : _onBackgroundLight;
    final primaryColor = dark ? _primaryDark : _primaryLight;
    final surfaceLowest =
        dark ? _surfaceContainerLowestDark : _surfaceContainerLowestLight;
    final surfaceContainerColor =
        dark ? _surfaceContainerDarkValue : _surfaceContainerLight;
    final surfaceVariantColor = dark ? _surfaceVariantDark : _surfaceVariantLight;
    final onSurfaceVariantColor =
        dark ? _onSurfaceVariantDark : _onSurfaceVariantLight;
    final secondaryTextColor = dark ? _secondaryTextDark : _secondaryTextLight;
    final errorColor = dark ? _errorDark : _errorLight;
    final secondaryContainerColor =
        dark ? _secondaryContainerDark : _secondaryContainerLight;
    final onSecondaryContainerColor =
        dark ? _onSecondaryContainerDark : _onSecondaryContainerLight;

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: dark
          ? ColorScheme.fromSeed(
              seedColor: successFixed,
              brightness: Brightness.dark,
            ).copyWith(
              surface: surfaceLowest,
              onSurface: onBg,
              error: errorColor,
              onError: onSecondary,
            )
          : ColorScheme.light(
              primary: successFixed,
              onPrimary: onSecondary,
              primaryContainer: secondaryContainerColor,
              onPrimaryContainer: onSecondaryContainerColor,
              secondary: primaryColor,
              onSecondary: onPrimary,
              surface: surfaceLowest,
              onSurface: onBg,
              error: errorColor,
              onError: onPrimary,
            ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        TextTheme(
          displayLarge:
              TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
          headlineLarge:
              TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
          headlineMedium:
              TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          titleLarge:
              TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: onBg),
          bodyMedium: TextStyle(color: onSurfaceVariantColor),
          labelLarge:
              TextStyle(color: onBg, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: onSurfaceVariantColor),
          labelSmall: TextStyle(color: onSurfaceVariantColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLowest,
        elevation: 0,
        foregroundColor: primaryColor,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: successFixed,
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
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: surfaceVariantColor, width: 2),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: surfaceVariantColor, width: 2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: secondaryTextColor, width: 2),
        ),
        labelStyle: GoogleFonts.beVietnamPro(
          color: onSurfaceVariantColor,
          fontSize: 14,
        ),
        floatingLabelStyle: GoogleFonts.beVietnamPro(
          color: secondaryTextColor,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: surfaceLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainerColor,
        indicatorColor: successFixed,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: onSecondary);
          }
          return IconThemeData(color: onSurfaceVariantColor);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.beVietnamPro(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? secondaryTextColor : onSurfaceVariantColor,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
