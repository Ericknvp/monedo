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
  static Currency _current = kCurrencies.first;

  static Currency get current => _current;

  /// Establece la moneda activa para todo el formateo de la app.
  static void setCurrency(String code) {
    _current = currencyByCode(code);
  }

  static String format(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final c = _current;

    final fixed = absAmount.toStringAsFixed(c.decimalDigits);
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

    final formatted = decPart.isEmpty
        ? '${c.symbol}${buffer.toString()}'
        : '${c.symbol}${buffer.toString()}${c.decimalSeparator}$decPart';

    return isNegative ? '-$formatted' : formatted;
  }

  /// Formatea con signo + o - según sea ingreso o gasto.
  static String formatWithSign(double amount, bool isIncome) {
    final sign = isIncome ? '+' : '-';
    return '$sign${format(amount.abs())}';
  }
}
