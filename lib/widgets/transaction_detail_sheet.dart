import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/category_icons.dart';
import '../utils/category_colors.dart';
import '../utils/account_colors.dart';

const _monthNames = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String _longDate(DateTime d) => '${d.day} de ${_monthNames[d.month - 1]} de ${d.year}';

/// Ver el movimiento primero, editar aparte: tocar una fila en la lista abre
/// esto (solo lectura, con el ícono de la categoría y todos los datos);
/// "Editar" y "Eliminar" son acciones explícitas dentro, no el toque mismo.
Future<void> showTransactionDetail(
  BuildContext context, {
  required TransactionModel transaction,
  required VoidCallback onEdit,
  // Devuelve si realmente se eliminó (false si se canceló la confirmación):
  // la hoja/diálogo solo se cierra solo cuando de verdad se borró.
  required Future<bool> Function() onDelete,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;
  if (isDesktop) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => _DesktopDetailDialog(
        transaction: transaction,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _MobileDetailSheet(
      transaction: transaction,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.t});
  final TransactionModel t;

  @override
  Widget build(BuildContext context) {
    final bg = t.isTransfer
        ? AppTheme.surfaceContainerHighest
        : (t.isIncome
            ? AppTheme.secondaryContainer.withOpacity(0.5)
            : AppTheme.expenseContainer);
    final fg = t.isTransfer
        ? AppTheme.onSurfaceVariant
        : (t.isIncome
            ? AppTheme.onSecondaryContainer
            : AppTheme.onExpenseContainer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(
        t.isTransfer ? 'TRANSFERENCIA' : (t.isIncome ? 'INGRESO' : 'GASTO'),
        style: GoogleFonts.beVietnamPro(
          color: fg, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Bolsillo de un movimiento buscado en vivo entre los bolsillos del usuario
/// (el modelo solo guarda el id); si no se encuentra o es null, "—".
class _AccountValue extends StatelessWidget {
  const _AccountValue({required this.accountId, this.dense = false});
  final String? accountId;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (accountId == null) {
      return Text('—',
          style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: dense ? 13 : 14, fontWeight: FontWeight.w600));
    }
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<AccountModel>>(
      stream: AccountService().getAccounts(userId),
      builder: (context, snap) {
        final accounts = snap.data ?? [];
        AccountModel? account;
        for (final a in accounts) {
          if (a.id == accountId) {
            account = a;
            break;
          }
        }
        if (account == null) {
          return Text('—',
              style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: dense ? 13 : 14, fontWeight: FontWeight.w600));
        }
        final color = AccountColors.forAccount(account);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: dense ? 16 : 18,
              height: dense ? 16 : 18,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
            ),
            const SizedBox(width: 8),
            Text(account.name,
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.primary, fontSize: dense ? 13 : 14, fontWeight: FontWeight.w600)),
          ],
        );
      },
    );
  }
}

// ── Móvil: hoja "recibo", centrada ──────────────────────────────
class _MobileDetailSheet extends StatelessWidget {
  const _MobileDetailSheet({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback onEdit;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final categoryColor = CategoryColors.forCategory(t.category);
    final amountColor =
        t.isTransfer ? AppTheme.onSurfaceVariant : (t.isIncome ? AppTheme.onSecondaryContainer : AppTheme.primary);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ValueListenableBuilder<Map<String, IconData>>(
                valueListenable: CategoryIconRegistry.customIcons,
                builder: (context, _, __) => Icon(
                  CategoryIconRegistry.iconFor(t.category),
                  color: categoryColor,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _TypePill(t: t),
            const SizedBox(height: 14),
            Text(
              t.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary, fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              t.isTransfer
                  ? CurrencyFormatter.format(t.amount)
                  : CurrencyFormatter.formatWithSign(t.amount, t.isIncome),
              style: GoogleFonts.plusJakartaSans(
                  color: amountColor, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 24),
            Divider(color: AppTheme.surfaceVariant, height: 1),
            const SizedBox(height: 20),
            _row('Categoría',
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: categoryColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(t.category,
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                ])),
            const SizedBox(height: 14),
            _row('Fecha',
                child: Text(_longDate(t.date),
                    style: GoogleFonts.beVietnamPro(
                        color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600))),
            const SizedBox(height: 14),
            _row('Bolsillo', child: _AccountValue(accountId: t.accountId)),
            if (t.note != null && t.note!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _row('Nota',
                  child: Text(t.note!,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant, fontSize: 13, fontStyle: FontStyle.italic))),
            ],
            if (!t.isTransfer) ...[
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.outlineVariant),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      // La confirmación aparece encima de esta hoja (que se
                      // queda abierta detrás); solo se cierra si de verdad
                      // se elimina, no si se cancela.
                      onPressed: () async {
                        final deleted = await onDelete();
                        if (deleted && context.mounted) Navigator.pop(context);
                      },
                      icon: Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed, size: 17),
                      label: Text('Eliminar', style: TextStyle(color: AppTheme.errorRed)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.errorRed.withOpacity(0.4)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, {required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant, fontSize: 13)),
        Flexible(child: Align(alignment: Alignment.centerRight, child: child)),
      ],
    );
  }
}

// ── Escritorio: diálogo compacto, denso ─────────────────────────
class _DesktopDetailDialog extends StatelessWidget {
  const _DesktopDetailDialog({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback onEdit;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final categoryColor = CategoryColors.forCategory(t.category);
    final amountColor =
        t.isTransfer ? AppTheme.onSurfaceVariant : (t.isIncome ? AppTheme.onSecondaryContainer : AppTheme.primary);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ValueListenableBuilder<Map<String, IconData>>(
                          valueListenable: CategoryIconRegistry.customIcons,
                          builder: (context, _, __) => Icon(
                            CategoryIconRegistry.iconFor(t.category),
                            color: categoryColor,
                            size: 21,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 5),
                            _TypePill(t: t),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.pop(context),
                        hoverColor: AppTheme.surfaceContainerHigh,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, color: AppTheme.onSurfaceVariant, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    t.isTransfer
                        ? CurrencyFormatter.format(t.amount)
                        : CurrencyFormatter.formatWithSign(t.amount, t.isIncome),
                    style: GoogleFonts.plusJakartaSans(
                        color: amountColor, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppTheme.surfaceContainerHigh, height: 1),
                  const SizedBox(height: 14),
                  _row('Categoría',
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 9, height: 9,
                          decoration: BoxDecoration(color: categoryColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 7),
                        Text(t.category,
                            style: GoogleFonts.beVietnamPro(
                                color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ])),
                  const SizedBox(height: 10),
                  _row('Fecha',
                      child: Text(_longDate(t.date),
                          style: GoogleFonts.beVietnamPro(
                              color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                  const SizedBox(height: 10),
                  _row('Bolsillo', child: _AccountValue(accountId: t.accountId, dense: true)),
                  if (t.note != null && t.note!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _row('Nota',
                        child: Text(t.note!,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.beVietnamPro(
                                color: AppTheme.onSurfaceVariant, fontSize: 12.5, fontStyle: FontStyle.italic))),
                  ],
                  if (!t.isTransfer) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          // La confirmación aparece encima de este diálogo
                          // (que se queda abierto detrás); solo se cierra si
                          // de verdad se elimina, no si se cancela.
                          onPressed: () async {
                            final deleted = await onDelete();
                            if (deleted && context.mounted) Navigator.pop(context);
                          },
                          icon: Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed, size: 16),
                          label: Text('Eliminar',
                              style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.errorRed, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ),
                        const SizedBox(width: 4),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit();
                          },
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text('Editar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.successFixed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            textStyle: GoogleFonts.beVietnamPro(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, {required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant, fontSize: 12.5)),
        const SizedBox(width: 12),
        Flexible(child: Align(alignment: Alignment.centerRight, child: child)),
      ],
    );
  }
}
