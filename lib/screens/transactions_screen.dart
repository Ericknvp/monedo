import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_service.dart';
import '../services/account_service.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../theme/app_theme.dart';
import '../utils/account_colors.dart';
import '../utils/category_colors.dart';
import '../utils/category_icons.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/branded_loading_screen.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/fade_slide_in.dart';
import 'add_transaction_screen.dart';
import 'export_screen.dart';
import 'recurring_transactions_screen.dart';

enum _DateFilterMode { all, month, range }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _txService = TransactionService();
  final _searchCtrl = TextEditingController();
  String _filter = 'Todos';
  String _searchQuery = '';
  int _currentPage = 0;
  static const _pageSize = 10;

  static const _filters = ['Todos', 'Ingresos', 'Gastos'];

  _DateFilterMode _dateMode = _DateFilterMode.all;
  int _filterMonth = DateTime.now().month;
  int _filterYear = DateTime.now().year;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  Set<String> _selectedCategories = {};
  Set<String> _selectedAccountIds = {};

  // Se crea una sola vez: TransactionService.getTransactions() abre un
  // listener nuevo de Firestore cada vez que se llama, así que si se
  // recreara en cada build() (p.ej. al escribir en el buscador, que hace
  // setState en cada letra), el StreamBuilder vería un stream distinto,
  // volvería a "cargando" y perdería el foco del campo de texto.
  late final Stream<List<TransactionModel>> _txStream;
  late final Stream<List<AccountModel>> _accountsStream;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _txStream = _txService.getTransactions(userId);
    _accountsStream = AccountService().getAccounts(userId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _filter != 'Todos' ||
      _searchQuery.isNotEmpty ||
      _dateFilterActive ||
      _selectedCategories.isNotEmpty ||
      _selectedAccountIds.isNotEmpty;

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

  bool _matchesSearch(TransactionModel t) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return t.title.toLowerCase().contains(q) ||
        (t.note?.toLowerCase().contains(q) ?? false);
  }

  bool _matchesCategoryFilter(TransactionModel t) {
    if (_selectedCategories.isEmpty) return true;
    return _selectedCategories.contains(t.category);
  }

  bool _matchesAccountFilter(TransactionModel t) {
    if (_selectedAccountIds.isEmpty) return true;
    return _selectedAccountIds.contains(t.accountId);
  }

  /// Devuelve si realmente se eliminó (no si solo se abrió y canceló la
  /// confirmación) — la vista de detalle del movimiento usa esto para saber
  /// si debe cerrarse ella misma o quedarse abierta.
  Future<bool> _delete(TransactionModel t) async {
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
    return true;
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
                    backgroundColor: AppTheme.successFixed,
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

  /// Hoja de selección múltiple de categorías: solo ofrece las categorías
  /// que realmente tienen movimientos (no todo el catálogo de la app), para
  /// no mostrar opciones que de todos modos no filtrarían nada.
  Future<void> _showCategoryFilterSheet(List<String> availableCategories) async {
    var selected = {..._selectedCategories};

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtrar por categoría',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setSheetState(() => selected.clear()),
                      child: Text('Limpiar',
                          style: GoogleFonts.beVietnamPro(
                              color: AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableCategories.map((c) {
                  final isSelected = selected.contains(c);
                  return _sheetChoiceChip(
                    c,
                    isSelected,
                    () => setSheetState(() {
                      if (isSelected) {
                        selected.remove(c);
                      } else {
                        selected.add(c);
                      }
                    }),
                    leadingColor: CategoryColors.forCategory(c),
                    leadingIcon: CategoryIconRegistry.iconFor(c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategories = selected;
                      _currentPage = 0;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successFixed,
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

  /// Hoja de selección múltiple de cuentas — mismo patrón que la de
  /// categorías, pero solo tiene sentido mostrarla cuando hay más de una
  /// cuenta (con una sola, filtrar por cuenta no distingue nada).
  Future<void> _showAccountFilterSheet(List<AccountModel> accounts) async {
    var selected = {..._selectedAccountIds};

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtrar por cuenta',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setSheetState(() => selected.clear()),
                      child: Text('Limpiar',
                          style: GoogleFonts.beVietnamPro(
                              color: AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: accounts.map((a) {
                  final isSelected = selected.contains(a.id);
                  return _sheetChoiceChip(
                    a.name,
                    isSelected,
                    () => setSheetState(() {
                      if (isSelected) {
                        selected.remove(a.id);
                      } else {
                        selected.add(a.id);
                      }
                    }),
                    leadingColor: AccountColors.forAccount(a),
                    leadingIcon: Icons.account_balance_wallet_rounded,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedAccountIds = selected;
                      _currentPage = 0;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successFixed,
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

  Widget _sheetChoiceChip(String label, bool selected, VoidCallback onTap,
      {Color? leadingColor, IconData? leadingIcon}) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.successFixed : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppTheme.successFixed : AppTheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.25)
                      : (leadingColor ?? AppTheme.outline).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(leadingIcon,
                    size: 12,
                    color: selected ? Colors.white : leadingColor),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: selected ? Colors.white : AppTheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
            ],
          ],
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

  /// En escritorio los chips se envuelven en varias líneas (hay ancho de
  /// sobra); en móvil eso se come mucho alto antes de llegar a la lista de
  /// movimientos, así que ahí van en una sola fila desplazable horizontal.
  Widget _filterChipsContainer(bool isDesktop, List<Widget> chips) {
    if (isDesktop) {
      return Wrap(spacing: 8, runSpacing: 8, children: chips);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
        ],
      ),
    );
  }

  /// Acumulado de ingresos/gastos de lo que queda visible tras los filtros
  /// activos. Solo muestra el total que tiene sentido según el filtro de
  /// tipo elegido — ver "Gastos: $0" cuando ya filtraste por Ingresos sería
  /// ruido, no información.
  Widget _buildSummaryBar(List<TransactionModel> filtered) {
    final showIncome = _filter != 'Gastos';
    final showExpenses = _filter != 'Ingresos';
    final income = showIncome ? _txService.calculateIncome(filtered) : 0.0;
    final expenses =
        showExpenses ? _txService.calculateExpenses(filtered) : 0.0;

    return Row(
      children: [
        if (showIncome)
          Expanded(
            child: _summaryStat(
              label: 'Ingresos',
              amount: income,
              color: AppTheme.secondary,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
        if (showIncome && showExpenses) const SizedBox(width: 10),
        if (showExpenses)
          Expanded(
            child: _summaryStat(
              label: 'Gastos',
              amount: expenses,
              color: AppTheme.errorRed,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
      ],
    );
  }

  Widget _summaryStat({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
          ),
        ],
      ),
    );
  }

  /// Píldora de filtro genérica (Categoría, Cuenta): mismo look que la de
  /// Fecha (icono + etiqueta, fondo oscuro cuando está activa, "x" para
  /// limpiar), para que todos los filtros se sientan como el mismo control.
  Widget _filterPill({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppTheme.navyFixed : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: active ? Colors.white : AppTheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: active ? Colors.white : AppTheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 6),
              PressableScale(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 15, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Barra de búsqueda por título o nota — píldora persistente arriba de
  /// los chips de filtro, siempre visible (no una hoja aparte) porque es la
  /// acción que más se usa y más rápido debe sentirse.
  Widget _buildSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 19, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primary, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Buscar por descripción o nota…',
                hintStyle: GoogleFonts.beVietnamPro(
                    color: AppTheme.outline, fontSize: 14),
              ),
              onChanged: (v) => setState(() {
                _searchQuery = v.trim();
                _currentPage = 0;
              }),
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                _searchCtrl.clear();
                _searchQuery = '';
                _currentPage = 0;
              }),
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppTheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return StreamBuilder<List<TransactionModel>>(
      stream: _txStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: BrandedInlineLoader());
        }

        final rawAll = snapshot.data ?? [];
        // Catálogo de categorías para la hoja de filtro: se calcula sobre
        // TODOS los movimientos (sin filtrar), para que la lista de opciones
        // no se vaya encogiendo a medida que el usuario combina filtros.
        final availableCategories = <String>{for (final t in rawAll) t.category}
            .toList()
          ..sort();

        var all = rawAll;
        if (_filter == 'Ingresos') {
          all = all.where((t) => t.isIncome).toList();
        } else if (_filter == 'Gastos') {
          all = all.where((t) => !t.isIncome).toList();
        }
        if (_dateFilterActive) {
          all = all.where(_matchesDateFilter).toList();
        }
        if (_searchQuery.isNotEmpty) {
          all = all.where(_matchesSearch).toList();
        }
        if (_selectedCategories.isNotEmpty) {
          all = all.where(_matchesCategoryFilter).toList();
        }
        if (_selectedAccountIds.isNotEmpty) {
          all = all.where(_matchesAccountFilter).toList();
        }

        final totalPages = (all.length / _pageSize).ceil().clamp(1, 9999);
        final safePage = _currentPage.clamp(0, totalPages - 1);
        final pageItems = all.skip(safePage * _pageSize).take(_pageSize).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              color: AppTheme.background,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildSearchBar(),
            ),
            // Filter pills
            Container(
              color: AppTheme.background,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _filterChipsContainer(isDesktop, [
                        ..._filters.map((f) {
                          final isSelected = _filter == f;
                          return PressableScale(
                            onTap: () => _setFilter(f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.navyFixed
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
                        PressableScale(
                          onTap: _showDateFilterSheet,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: _dateFilterActive
                                  ? AppTheme.navyFixed
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
                                  PressableScale(
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
                        if (availableCategories.isNotEmpty)
                          _filterPill(
                            icon: Icons.category_outlined,
                            label: _selectedCategories.isEmpty
                                ? 'Categoría'
                                : _selectedCategories.length == 1
                                    ? _selectedCategories.first
                                    : 'Categoría (${_selectedCategories.length})',
                            active: _selectedCategories.isNotEmpty,
                            onTap: () =>
                                _showCategoryFilterSheet(availableCategories),
                            onClear: () => setState(() {
                              _selectedCategories = {};
                              _currentPage = 0;
                            }),
                          ),
                        StreamBuilder<List<AccountModel>>(
                          stream: _accountsStream,
                          builder: (context, accSnap) {
                            final accounts = accSnap.data ?? [];
                            if (accounts.length < 2) {
                              return const SizedBox.shrink();
                            }
                            String accountLabel;
                            if (_selectedAccountIds.isEmpty) {
                              accountLabel = 'Cuenta';
                            } else if (_selectedAccountIds.length == 1) {
                              final match = accounts
                                  .where((a) => a.id == _selectedAccountIds.first);
                              accountLabel =
                                  match.isEmpty ? 'Cuenta' : match.first.name;
                            } else {
                              accountLabel = 'Cuenta (${_selectedAccountIds.length})';
                            }
                            return _filterPill(
                              icon: Icons.account_balance_wallet_outlined,
                              label: accountLabel,
                              active: _selectedAccountIds.isNotEmpty,
                              onTap: () => _showAccountFilterSheet(accounts),
                              onClear: () => setState(() {
                                _selectedAccountIds = {};
                                _currentPage = 0;
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isDesktop)
                    InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () => openRecurringTransactionsScreen(context),
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
                            Icon(Icons.repeat_rounded,
                                size: 17, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Recurrentes',
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
                      message: 'Movimientos recurrentes',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: () => openRecurringTransactionsScreen(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceContainer,
                            border: Border.all(color: AppTheme.outlineVariant),
                          ),
                          child: Icon(Icons.repeat_rounded,
                              size: 17, color: AppTheme.primary),
                        ),
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
                            Icon(Icons.ios_share_rounded,
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
                          child: Icon(Icons.ios_share_rounded,
                              size: 17, color: AppTheme.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Summary bar — acumulado de lo que queda visible tras aplicar
            // todos los filtros activos (tipo, fecha, categoría, cuenta,
            // búsqueda), no solo el total general.
            if (all.isNotEmpty)
              Container(
                color: AppTheme.background,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                child: _buildSummaryBar(all),
              ),

            // Transaction list
            Expanded(
              child: all.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.receipt_long_outlined,
                                size: 36, color: AppTheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            !_hasActiveFilters
                                ? 'Aún no hay movimientos'
                                : 'Nada que coincida con estos filtros',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            !_hasActiveFilters
                                ? 'Tus ingresos y gastos aparecerán aquí'
                                : 'Prueba con otra búsqueda o quita algún filtro',
                            style: GoogleFonts.beVietnamPro(
                                color: AppTheme.onSurfaceVariant, fontSize: 13),
                          ),
                          if (!_hasActiveFilters) ...[
                            const SizedBox(height: 20),
                            PressableScale(
                              onTap: () => openAddTransaction(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_rounded,
                                        size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Agregar movimiento',
                                      style: GoogleFonts.beVietnamPro(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      itemCount: pageItems.length,
                      itemBuilder: (ctx, i) {
                        final t = pageItems[i];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: i * 35),
                          child: TransactionTile(
                            transaction: t,
                            onEdit: () =>
                                openAddTransaction(context, transaction: t),
                            onDelete: () => _delete(t),
                          ),
                        );
                      },
                    ),
            ),

            // Pagination bar
            if (all.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
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
    return PressableScale(
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
    return PressableScale(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navyFixed : Colors.transparent,
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
