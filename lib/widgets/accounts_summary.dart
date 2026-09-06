import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';
import '../screens/accounts_screen.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

/// Tarjeta que muestra en qué cuentas está el dinero del usuario, con
/// acceso directo a agregarlas o administrarlas (Mis cuentas).
class AccountsSummaryCard extends StatelessWidget {
  final List<AccountModel> accounts;

  const AccountsSummaryCard({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dónde está tu dinero',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountsScreen()),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        accounts.isEmpty ? 'Agregar' : 'Ver todas',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.secondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.secondary, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (accounts.isEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountsScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.outlineVariant,
                      style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded,
                        color: AppTheme.onSurfaceVariant, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      'Agrega tu primera cuenta',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accounts.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  if (i == accounts.length) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AccountsScreen()),
                      ),
                      child: Container(
                        width: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: AppTheme.onSurfaceVariant),
                      ),
                    );
                  }
                  final a = accounts[i];
                  return Container(
                    width: 138,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            color: AppTheme.secondary, size: 18),
                        const SizedBox(height: 8),
                        Text(
                          a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(a.balance),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
