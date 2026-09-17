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

/// Hoja de detalle genérica: una lista de movimientos ya filtrados (por
/// categoría, por día...) con su total, editable/eliminable igual que en
/// "Movimientos" — ventana modal centrada en escritorio, pantalla completa
/// en móvil. La usan [openCategoryTransactionsScreen] y
/// [openDayTransactionsScreen]; no recibe un `userId` ni arma su propio
/// stream porque siempre parte de una lista ya recortada por quien la abre
/// (el periodo que se esté viendo en Estadísticas), no del histórico
/// completo — para eso está la pestaña "Movimientos" con su propio filtro.

/// Abre el detalle de los gastos de una categoría PARA UN PERIODO dado (el
/// mismo que se esté viendo en el donut de Estadísticas — mes, semana u
/// hoy). Solo gastos (así es como se arma la gráfica de torta), un único
/// total.
Future<void> openCategoryTransactionsScreen(
  BuildContext context, {
  required String category,
  required List<TransactionModel> transactions,
  required String periodLabel,
}) {
  return _openDetailScreen(
    context,
    title: category,
    subtitle: periodLabel,
    icon: CategoryIconRegistry.iconFor(category),
    color: CategoryColors.forCategory(category),
    transactions: transactions,
    showIncome: false,
    emptyMessage: 'Sin gastos en "$category"',
  );
}

/// Abre todos los movimientos (ingresos y gastos) de un día puntual — se
/// usa al tocar una barra de "Gastos por día" en la sección semanal de
/// Estadísticas.
Future<void> openDayTransactionsScreen(
  BuildContext context, {
  required DateTime date,
  required List<TransactionModel> transactions,
}) {
  const weekdays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  final title = weekdays[date.weekday - 1];
  final subtitle = '${date.day} ${months[date.month - 1]} ${date.year}';

  return _openDetailScreen(
    context,
    title: title,
    subtitle: subtitle,
    icon: Icons.calendar_today_rounded,
    color: AppTheme.secondary,
    transactions: transactions,
    showIncome: true,
    emptyMessage: 'Sin movimientos ese día',
  );
}

Future<void> _openDetailScreen(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required List<TransactionModel> transactions,
  required bool showIncome,
  required String emptyMessage,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => TransactionsDetailScreen(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        transactions: transactions,
        showIncome: showIncome,
        emptyMessage: emptyMessage,
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
      builder: (_) => TransactionsDetailScreen(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        transactions: transactions,
        showIncome: showIncome,
        emptyMessage: emptyMessage,
      ),
    ),
  );
}

class TransactionsDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<TransactionModel> transactions;
  final bool showIncome;
  final String emptyMessage;
  final bool isDialog;

  const TransactionsDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.transactions,
    required this.showIncome,
    required this.emptyMessage,
    this.isDialog = false,
  });

  @override
  State<TransactionsDetailScreen> createState() =>
      _TransactionsDetailScreenState();
}

class _TransactionsDetailScreenState extends State<TransactionsDetailScreen> {
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
          widget.title,
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
            child: _subtitleLabel(),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Ventana modal centrada (escritorio).
  Widget _buildDialog(BuildContext context) {
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
                          color: widget.color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:
                            Icon(widget.icon, color: widget.color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primary,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _subtitleLabel(compact: true),
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

  Widget _subtitleLabel({bool compact = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 10),
      child: Text(
        widget.subtitle,
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
                widget.emptyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: _summaryRow(),
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

  /// Sin `showIncome`: un solo total (gastos, en rojo) — así es como se
  /// arma la lista, sería redundante repetir "Gastos" en la etiqueta. Con
  /// `showIncome`: dos totales lado a lado, igual que la barra de resumen
  /// de "Movimientos".
  Widget _summaryRow() {
    final countLabel =
        '${_items.length} movimiento${_items.length == 1 ? '' : 's'}';

    if (!widget.showIncome) {
      final total = _items.fold<double>(0, (sum, t) => sum + t.amount);
      return Row(
        children: [
          Text(countLabel,
              style: GoogleFonts.beVietnamPro(
                  color: AppTheme.onSurfaceVariant, fontSize: 13)),
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
      );
    }

    final income = _txService.calculateIncome(_items);
    final expenses = _txService.calculateExpenses(_items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(countLabel,
            style: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: [
            if (income > 0)
              Expanded(
                  child: _statChip('Ingresos', income, AppTheme.secondary)),
            if (income > 0 && expenses > 0) const SizedBox(width: 10),
            if (expenses > 0)
              Expanded(
                  child: _statChip('Gastos', expenses, AppTheme.errorRed)),
          ],
        ),
      ],
    );
  }

  Widget _statChip(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.beVietnamPro(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(amount),
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
