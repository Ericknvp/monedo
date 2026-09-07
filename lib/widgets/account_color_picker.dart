import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../theme/app_theme.dart';
import '../utils/account_colors.dart';
import '../utils/category_colors.dart';

/// Hoja para elegir el color de una cuenta, de la misma paleta curada que
/// las categorías.
Future<void> showAccountColorPicker(
  BuildContext context, {
  required AccountModel account,
}) {
  final service = AccountService();
  final current = AccountColors.forAccount(account);

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Color de "${account.name}"',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: CategoryColors.swatches.map((color) {
              final isSelected = color.value == current.value;
              return InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () async {
                  await service.setColor(account.id, color.value);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );
}
