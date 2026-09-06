import 'package:flutter/foundation.dart';

class Currency {
  final String code;
  final String name;
  final String symbol;
  final String thousandsSeparator;
  final String decimalSeparator;
  final int decimalDigits;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.thousandsSeparator,
    required this.decimalSeparator,
    required this.decimalDigits,
  });
}

const List<Currency> kCurrencies = [
  Currency(code: 'USD', name: 'Dólar estadounidense', symbol: '\$', thousandsSeparator: ',', decimalSeparator: '.', decimalDigits: 2),
  Currency(code: 'COP', name: 'Peso colombiano', symbol: '\$', thousandsSeparator: '.', decimalSeparator: ',', decimalDigits: 0),
  Currency(code: 'EUR', name: 'Euro', symbol: '€', thousandsSeparator: '.', decimalSeparator: ',', decimalDigits: 2),
  Currency(code: 'MXN', name: 'Peso mexicano', symbol: '\$', thousandsSeparator: ',', decimalSeparator: '.', decimalDigits: 2),
  Currency(code: 'ARS', name: 'Peso argentino', symbol: '\$', thousandsSeparator: '.', decimalSeparator: ',', decimalDigits: 2),
  Currency(code: 'CLP', name: 'Peso chileno', symbol: '\$', thousandsSeparator: '.', decimalSeparator: ',', decimalDigits: 0),
  Currency(code: 'PEN', name: 'Sol peruano', symbol: 'S/', thousandsSeparator: ',', decimalSeparator: '.', decimalDigits: 2),
  Currency(code: 'BRL', name: 'Real brasileño', symbol: 'R\$', thousandsSeparator: '.', decimalSeparator: ',', decimalDigits: 2),
  Currency(code: 'GBP', name: 'Libra esterlina', symbol: '£', thousandsSeparator: ',', decimalSeparator: '.', decimalDigits: 2),
];

Currency currencyByCode(String? code) {
  return kCurrencies.firstWhere(
    (c) => c.code == code,
    orElse: () => kCurrencies.first,
  );
}

class CurrencyFormatter {
  /// Notifica a toda la app cuando cambia la moneda activa, para que
  /// cada pantalla (incluidas las que quedan vivas en un IndexedStack)
  /// se refresque automáticamente.
  static final ValueNotifier<Currency> notifier =
      ValueNotifier<Currency>(kCurrencies.first);

  static Currency get current => notifier.value;

  /// Establece la moneda activa para todo el formateo de la app.
  static void setCurrency(String code) {
    notifier.value = currencyByCode(code);
  }

  /// Agrupa un número con el separador de miles/decimales de la moneda
  /// activa, sin símbolo (ej. "1.234,56" para COP, "1,234.56" para USD).
  static String formatNumber(double amount) {
    final c = current;
    final fixed = amount.toStringAsFixed(c.decimalDigits);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(c.thousandsSeparator);
      }
      buffer.write(intPart[i]);
    }

    return decPart.isEmpty
        ? buffer.toString()
        : '${buffer.toString()}${c.decimalSeparator}$decPart';
  }

  static String format(double amount) {
    final isNegative = amount < 0;
    final body = '${current.symbol}${formatNumber(amount.abs())}';
    return isNegative ? '-$body' : body;
  }

  /// Formatea con signo + o - según sea ingreso o gasto.
  static String formatWithSign(double amount, bool isIncome) {
    final sign = isIncome ? '+' : '-';
    return '$sign${format(amount.abs())}';
  }

  /// Interpreta un texto ya agrupado con los separadores de la moneda
  /// activa (lo que escribe el usuario en un campo de monto) y devuelve
  /// el número real, o null si no es válido.
  static double? parse(String text) {
    final c = current;
    var raw = text.trim().replaceAll(c.thousandsSeparator, '');
    raw = raw.replaceAll(c.decimalSeparator, '.');
    return double.tryParse(raw);
  }
}
