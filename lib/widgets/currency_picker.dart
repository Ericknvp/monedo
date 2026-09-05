import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

Future<Currency?> showCurrencyPicker(BuildContext context, {Currency? selected}) {
  return showModalBottomSheet<Currency>(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecciona tu moneda',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: kCurrencies.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 24, endIndent: 24),
                  itemBuilder: (ctx, i) {
                    final c = kCurrencies[i];
                    final isSelected = selected?.code == c.code;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.secondaryContainer,
                        foregroundColor: AppTheme.onSecondaryContainer,
                        child: Text(
                          c.symbol,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        c.code,
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        c.name,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppTheme.secondary)
                          : null,
                      onTap: () => Navigator.pop(ctx, c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class CurrencyPickerField extends StatelessWidget {
  final Currency? selected;
  final ValueChanged<Currency> onChanged;

  const CurrencyPickerField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showCurrencyPicker(context, selected: selected);
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.payments_outlined,
                color: AppTheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Moneda',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 11, color: AppTheme.onSurfaceVariant),
                  ),
                  Text(
                    selected == null
                        ? 'Selecciona tu moneda'
                        : '${selected!.symbol} ${selected!.code} · ${selected!.name}',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          selected == null ? AppTheme.outline : AppTheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
