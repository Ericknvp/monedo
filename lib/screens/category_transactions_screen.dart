import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../theme/app_theme.dart';
import '../utils/category_colors.dart';
import '../utils/category_icons.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

/// Abre el detalle de los gastos de una categoría PARA UN PERIODO dado (el
/// mismo que se esté viendo en el donut de Estadísticas — mes, semana u
/// hoy): ventana modal centrada en escritorio, pantalla completa en móvil
/// — mismo patrón que [openRecurringTransactionsScreen]. Para el histórico
/// completo de todos los periodos está la pestaña "Movimientos" con su
/// propio filtro por categoría.
Future<void> openCategoryTransactionsScreen(
  BuildContext context, {
  required String category,
  required List<TransactionModel> transactions,
  required String periodLabel,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => CategoryTransactionsScreen(
        category: category,
        transactions: transactions,
        periodLabel: periodLabel,
        isDialog: true,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CategoryTransactionsScreen(
        category: category,
        transactions: transactions,
        periodLabel: periodLabel,
      ),
    ),
  );
}

class CategoryTransactionsScreen extends StatefulWidget {
  final String category;
  final List<TransactionModel> transactions;
  final String periodLabel;
  final bool isDialog;

  const CategoryTransactionsScreen({
    super.key,
    required this.category,
    required this.transactions,
    required this.periodLabel,
    this.isDialog = false,
  });

  @override
  State<CategoryTransactionsScreen> createState() =>
      _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState
    extends State<CategoryTransactionsScreen> {
  final _txService = TransactionService();
  late List<TransactionModel> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.transactions];
  }

  /// Devuelve si realmente se eliminó (false si se canceló la
  /// confirmación) — la vista de detalle del movimiento usa esto para
  /// saber si debe cerrarse o quedarse abierta.
  Future<bool> _confirmDelete(TransactionModel t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Eliminar movimiento?',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
        content: Text(
          'Se eliminará "${t.title}" (${CurrencyFormatter.format(t.amount)}). Esta acción no se puede deshacer.',
          style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar',
                style: TextStyle(
                    color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return false;
    await _txService.deleteTransaction(t);
    if (mounted) setState(() => _items.remove(t));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) return _buildDialog(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _periodBadge(),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Ventana modal centrada (escritorio).
  Widget _buildDialog(BuildContext context) {
    final color = CategoryColors.forCategory(widget.category);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
          child: Material(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            elevation: 24,
            shadowColor: Colors.black.withOpacity(0.4),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                            CategoryIconRegistry.iconFor(widget.category),
                            color: color,
                            size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.category,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primary,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _periodBadge(compact: true),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: AppTheme.onSurfaceVariant),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodBadge({bool compact = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 10),
      child: Text(
        widget.periodLabel,
        style: GoogleFonts.beVietnamPro(
          color: AppTheme.onSurfaceVariant,
          fontSize: compact ? 12 : 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 40, color: AppTheme.outlineVariant),
              const SizedBox(height: 12),
              Text(
                'Sin gastos en "${widget.category}"',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.periodLabel,
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    final total = _items.fold<double>(0, (sum, t) => sum + t.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Text(
                '${_items.length} movimiento${_items.length == 1 ? '' : 's'}',
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 13),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.format(total),
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.errorRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: _items.length,
            itemBuilder: (ctx, i) {
              final t = _items[i];
              return TransactionTile(
                transaction: t,
                onEdit: () => openAddTransaction(context, transaction: t),
                onDelete: () => _confirmDelete(t),
              );
            },
          ),
        ),
      ],
    );
  }
}
