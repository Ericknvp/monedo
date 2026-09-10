import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/branded_loading_screen.dart';
import '../widgets/app_date_picker.dart';
import 'add_transaction_screen.dart';
import 'export_screen.dart';

enum _DateFilterMode { all, month, range }

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

  _DateFilterMode _dateMode = _DateFilterMode.all;
  int _filterMonth = DateTime.now().month;
  int _filterYear = DateTime.now().year;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  bool get _dateFilterActive => _dateMode != _DateFilterMode.all;

  String get _dateFilterLabel {
    switch (_dateMode) {
      case _DateFilterMode.all:
        return 'Fecha';
      case _DateFilterMode.month:
        return '${_months[_filterMonth - 1]} $_filterYear';
      case _DateFilterMode.range:
        if (_rangeStart == null || _rangeEnd == null) return 'Fecha';
        return '${_shortDate(_rangeStart!)} - ${_shortDate(_rangeEnd!)}';
    }
  }

  String _shortDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  bool _matchesDateFilter(TransactionModel t) {
    switch (_dateMode) {
      case _DateFilterMode.all:
        return true;
      case _DateFilterMode.month:
        return t.date.year == _filterYear && t.date.month == _filterMonth;
      case _DateFilterMode.range:
        if (_rangeStart == null || _rangeEnd == null) return true;
        final start =
            DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
        final end = DateTime(
            _rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day, 23, 59, 59);
        return !t.date.isBefore(start) && !t.date.isAfter(end);
    }
  }

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
    if (confirm == true) await _txService.deleteTransaction(t);
  }

  void _setFilter(String f) {
    setState(() {
      _filter = f;
      _currentPage = 0;
    });
  }

  Future<void> _showDateFilterSheet() async {
    var mode = _dateMode;
    var month = _filterMonth;
    var year = _filterYear;
    var rangeStart = _rangeStart;
    var rangeEnd = _rangeEnd;
    final years = List.generate(6, (i) => DateTime.now().year - i);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
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
                'Filtrar por fecha',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _sheetChoiceChip('Todo el tiempo', mode == _DateFilterMode.all,
                      () => setSheetState(() => mode = _DateFilterMode.all)),
                  _sheetChoiceChip(
                      'Mes específico',
                      mode == _DateFilterMode.month,
                      () => setSheetState(() => mode = _DateFilterMode.month)),
                  _sheetChoiceChip(
                      'Rango de fechas',
                      mode == _DateFilterMode.range,
                      () => setSheetState(() => mode = _DateFilterMode.range)),
                ],
              ),
              if (mode == _DateFilterMode.month) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _sheetDropdown<int>(
                        value: month,
                        items: List.generate(12, (i) => i + 1),
                        labelBuilder: (m) => _months[m - 1],
                        onChanged: (v) => setSheetState(() => month = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _sheetDropdown<int>(
                        value: year,
                        items: years,
                        labelBuilder: (y) => '$y',
                        onChanged: (v) => setSheetState(() => year = v!),
                      ),
                    ),
                  ],
                ),
              ],
              if (mode == _DateFilterMode.range) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _sheetDateButton(
                        label: 'Desde',
                        date: rangeStart,
                        onTap: () async {
                          final picked = await showAppDatePicker(
                            ctx,
                            initialDate: rangeStart ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => rangeStart = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sheetDateButton(
                        label: 'Hasta',
                        date: rangeEnd,
                        onTap: () async {
                          final picked = await showAppDatePicker(
                            ctx,
                            initialDate: rangeEnd ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => rangeEnd = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _dateMode = mode;
                      _filterMonth = month;
                      _filterYear = year;
                      _rangeStart = rangeStart;
                      _rangeEnd = rangeEnd;
                      _currentPage = 0;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text('Aplicar filtro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetChoiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.secondary : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppTheme.secondary : AppTheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: selected ? Colors.white : AppTheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _sheetDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceContainerLowest,
          style: GoogleFonts.beVietnamPro(
              color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600),
          items: items
              .map((e) =>
                  DropdownMenuItem(value: e, child: Text(labelBuilder(e))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _sheetDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date != null ? _shortDate(date) : 'Elegir',
              style: GoogleFonts.beVietnamPro(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return StreamBuilder<List<TransactionModel>>(
      stream: _txService.getTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: BrandedInlineLoader());
        }

        var all = snapshot.data ?? [];
        if (_filter == 'Ingresos') {
          all = all.where((t) => t.isIncome).toList();
        } else if (_filter == 'Gastos') {
          all = all.where((t) => !t.isIncome).toList();
        }
        if (_dateFilterActive) {
          all = all.where(_matchesDateFilter).toList();
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
                      children: [
                        ..._filters.map((f) {
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
                        }),
                        GestureDetector(
                          onTap: _showDateFilterSheet,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: _dateFilterActive
                                  ? AppTheme.primary
                                  : AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month_rounded,
                                    size: 15,
                                    color: _dateFilterActive
                                        ? Colors.white
                                        : AppTheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  _dateFilterLabel,
                                  style: GoogleFonts.beVietnamPro(
                                    color: _dateFilterActive
                                        ? Colors.white
                                        : AppTheme.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: _dateFilterActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                if (_dateFilterActive) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _dateMode = _DateFilterMode.all;
                                      _currentPage = 0;
                                    }),
                                    child: const Icon(Icons.close_rounded,
                                        size: 15, color: Colors.white),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isDesktop)
                    InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () => openExportScreen(context),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: AppTheme.surfaceContainer,
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.ios_share_rounded,
                                size: 17, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Exportar datos',
                              style: GoogleFonts.beVietnamPro(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
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
