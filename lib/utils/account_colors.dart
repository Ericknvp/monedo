import 'package:flutter/material.dart';
import '../models/account.dart';
import 'category_colors.dart';

/// Color de una cuenta: el que el usuario eligió, o uno estable por hash de
/// su id si no ha elegido ninguno (misma paleta validada que las categorías).
class AccountColors {
  AccountColors._();

  static Color forAccount(AccountModel account) {
    if (account.color != null) return Color(account.color!);

    var hash = 0;
    for (final unit in account.id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return CategoryColors.swatches[hash % CategoryColors.swatches.length];
  }
}
