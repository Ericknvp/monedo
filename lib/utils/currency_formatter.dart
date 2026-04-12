
class CurrencyFormatter {

  static String format(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    final parts = absAmount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    final formatted = decPart == '00'
        ? '\$${buffer.toString()}'
        : '\$${buffer.toString()}.$decPart';

    return isNegative ? '-$formatted' : formatted;
  }

  /// Formatea con signo + o - según sea ingreso o gasto.
  static String formatWithSign(double amount, bool isIncome) {
    final sign = isIncome ? '+' : '-';
    return '$sign${format(amount.abs())}';
  }
}
