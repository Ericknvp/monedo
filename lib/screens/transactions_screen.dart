import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'export_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _txService = TransactionService();
  String _filter = 'Todos';
  int _currentPage = 0;
  static const _pageSize = 10;

  static const _filters = ['Todos', 'Ingresos', 'Gastos'];

  Future<void> _delete(TransactionModel t) async {
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
    if (confirm == true) await _txService.deleteTransaction(t.id);
  }

  void _setFilter(String f) {
    setState(() {
      _filter = f;
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<TransactionModel>>(
      stream: _txService.getTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondary),
          );
        }

        var all = snapshot.data ?? [];
        if (_filter == 'Ingresos') {
          all = all.where((t) => t.isIncome).toList();
        } else if (_filter == 'Gastos') {
          all = all.where((t) => !t.isIncome).toList();
        }

        final totalPages = (all.length / _pageSize).ceil().clamp(1, 9999);
        final safePage = _currentPage.clamp(0, totalPages - 1);
        final pageItems = all.skip(safePage * _pageSize).take(_pageSize).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter pills
            Container(
              color: AppTheme.background,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filters.map((f) {
                        final isSelected = _filter == f;
                        return GestureDetector(
                          onTap: () => _setFilter(f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              f,
                              style: GoogleFonts.beVietnamPro(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.onSurfaceVariant,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Exportar datos',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () => openExportScreen(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceContainer,
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: const Icon(Icons.ios_share_rounded,
                            size: 17, color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Transaction list
            Expanded(
              child: all.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 64, color: AppTheme.outlineVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No hay movimientos',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primer movimiento',
                            style: GoogleFonts.beVietnamPro(
                                color: AppTheme.outlineVariant, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      itemCount: pageItems.length,
                      itemBuilder: (ctx, i) {
                        final t = pageItems[i];
                        return TransactionTile(
                          transaction: t,
                          onEdit: () =>
                              openAddTransaction(context, transaction: t),
                          onDelete: () => _delete(t),
                        );
                      },
                    ),
            ),

            // Pagination bar
            if (all.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppTheme.background,
                  border: Border(top: BorderSide(color: AppTheme.surfaceVariant)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${safePage * _pageSize + 1}–${(safePage * _pageSize + pageItems.length)} de ${all.length}',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        _pageBtn(
                          Icons.chevron_left_rounded,
                          safePage > 0,
                          () => setState(() => _currentPage = safePage - 1),
                        ),
                        const SizedBox(width: 4),
                        ...List.generate(totalPages, (i) {
                          if (totalPages <= 7 ||
                              i == 0 ||
                              i == totalPages - 1 ||
                              (i - safePage).abs() <= 1) {
                            return _pageNumBtn(i, safePage);
                          }
                          if (i == 1 && safePage > 3) {
                            return _ellipsis();
                          }
                          if (i == totalPages - 2 && safePage < totalPages - 4) {
                            return _ellipsis();
                          }
                          return const SizedBox.shrink();
                        }),
                        const SizedBox(width: 4),
                        _pageBtn(
                          Icons.chevron_right_rounded,
                          safePage < totalPages - 1,
                          () => setState(() => _currentPage = safePage + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppTheme.primary : AppTheme.outlineVariant,
        ),
      ),
    );
  }

  Widget _pageNumBtn(int page, int current) {
    final isSelected = page == current;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${page + 1}',
            style: GoogleFonts.beVietnamPro(
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _ellipsis() {
    return SizedBox(
      width: 28,
      height: 32,
      child: Center(
        child: Text('…',
            style: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant, fontSize: 13)),
      ),
    );
  }
}
