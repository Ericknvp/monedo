import 'package:flutter/services.dart';
import 'currency_formatter.dart';

/// Agrega el separador de miles (y respeta el decimal) de la moneda activa
/// mientras el usuario escribe un monto, para que no se vea "de corrido".
class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final c = CurrencyFormatter.current;
    var raw = newValue.text.replaceAll(c.thousandsSeparator, '');

    var hasDecimal = c.decimalDigits > 0 && raw.contains(c.decimalSeparator);
    var integerPart = raw;
    var decimalPart = '';

    if (hasDecimal) {
      final decIndex = raw.indexOf(c.decimalSeparator);
      integerPart = raw.substring(0, decIndex);
      decimalPart = raw
          .substring(decIndex + c.decimalSeparator.length)
          .replaceAll(c.decimalSeparator, '');
    }

    integerPart = integerPart.replaceAll(RegExp(r'[^0-9]'), '');
    decimalPart = decimalPart.replaceAll(RegExp(r'[^0-9]'), '');
    if (decimalPart.length > c.decimalDigits) {
      decimalPart = decimalPart.substring(0, c.decimalDigits);
    }

    if (integerPart.isEmpty && !hasDecimal) {
      return const TextEditingValue(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(c.thousandsSeparator);
      }
      buffer.write(integerPart[i]);
    }

    var formatted = buffer.toString();
    if (hasDecimal) {
      formatted += '${c.decimalSeparator}$decimalPart';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
