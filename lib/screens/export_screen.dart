import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../theme/app_theme.dart';
import '../utils/export_builder.dart';
import '../utils/file_export.dart'
    if (dart.library.io) '../utils/file_export_stub.dart';
import '../widgets/app_toast.dart';

enum _ExportScope { all, year, month }

/// Abre "Exportar datos": como una ventana modal centrada (con fondo
/// oscurecido) en escritorio, o a pantalla completa en móvil.
Future<void> openExportScreen(BuildContext context) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const ExportScreen(isDialog: true),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
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
    MaterialPageRoute(builder: (_) => const ExportScreen()),
  );
}

class ExportScreen extends StatefulWidget {
  final bool isDialog;

  const ExportScreen({super.key, this.isDialog = false});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _txService = TransactionService();

  _ExportScope _scope = _ExportScope.all;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _exportingExcel = false;
  bool _exportingPdf = false;

  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  String get _periodLabel {
    switch (_scope) {
      case _ExportScope.all:
        return 'Todo el historial';
      case _ExportScope.year:
        return 'Año $_selectedYear';
      case _ExportScope.month:
        return '${_months[_selectedMonth - 1]} $_selectedYear';
    }
  }

  List<TransactionModel> _filter(List<TransactionModel> all) {
    switch (_scope) {
      case _ExportScope.all:
        return all;
      case _ExportScope.year:
        return all.where((t) => t.date.year == _selectedYear).toList();
      case _ExportScope.month:
        return all
            .where((t) =>
                t.date.year == _selectedYear && t.date.month == _selectedMonth)
            .toList();
    }
  }

  String _slug(String periodLabel) => periodLabel
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  Future<void> _export({required bool asExcel}) async {
    setState(() {
      if (asExcel) {
        _exportingExcel = true;
      } else {
        _exportingPdf = true;
      }
    });

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final all = await _txService.getTransactions(userId).first;
    final filtered = _filter(all);

    if (filtered.isEmpty) {
      setState(() {
        _exportingExcel = false;
        _exportingPdf = false;
      });
      if (mounted) {
        showAppToast(
          context,
          message: 'No hay movimientos para exportar en ese período',
          icon: Icons.info_outline_rounded,
          accentColor: AppTheme.onSurfaceVariant,
        );
      }
      return;
    }

    final slug = _slug(_periodLabel);
    if (asExcel) {
      final bytes = buildExcelBytes(filtered);
      await saveExportedFile(
        filename: 'monedo-$slug.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } else {
      final bytes = await buildPdfBytes(
        transactions: filtered,
        periodLabel: _periodLabel,
      );
      await saveExportedFile(
        filename: 'monedo-$slug.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );
    }

    if (mounted) {
      setState(() {
        _exportingExcel = false;
        _exportingPdf = false;
      });
      showAppToast(
        context,
        message: asExcel ? 'Excel generado' : 'PDF generado',
        icon: Icons.check_circle_rounded,
        accentColor: AppTheme.secondary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) return _buildDialog();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Exportar datos',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildFields(),
      ),
    );
  }

  /// Ventana modal centrada (escritorio).
  Widget _buildDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Material(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            elevation: 24,
            shadowColor: Colors.black.withOpacity(0.4),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.ios_share_rounded,
                            color: AppTheme.secondary, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Exportar datos',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.onSurfaceVariant),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildFields(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFields() {
    final years = List.generate(6, (i) => DateTime.now().year - i);

    return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elige qué período de tus movimientos quieres exportar, y en qué formato.',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Período',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _scopeChip('Todo', _ExportScope.all),
                    _scopeChip('Por año', _ExportScope.year),
                    _scopeChip('Por mes', _ExportScope.month),
                  ],
                ),

                if (_scope != _ExportScope.all) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_scope == _ExportScope.month) ...[
                        Expanded(
                          flex: 3,
                          child: _dropdownCard<int>(
                            value: _selectedMonth,
                            items: List.generate(12, (i) => i + 1),
                            labelBuilder: (m) => _months[m - 1],
                            onChanged: (v) =>
                                setState(() => _selectedMonth = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: _dropdownCard<int>(
                          value: _selectedYear,
                          items: years,
                          labelBuilder: (y) => '$y',
                          onChanged: (v) => setState(() => _selectedYear = v!),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),
                Text(
                  'Formato',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _formatButton(
                        label: 'Exportar a Excel',
                        icon: Icons.grid_on_rounded,
                        color: const Color(0xFF1D6F42),
                        loading: _exportingExcel,
                        onTap: () => _export(asExcel: true),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _formatButton(
                        label: 'Exportar a PDF',
                        icon: Icons.picture_as_pdf_rounded,
                        color: const Color(0xFFC0392B),
                        loading: _exportingPdf,
                        onTap: () => _export(asExcel: false),
                      ),
                    ),
                  ],
                ),
      ],
    );
  }

  Widget _scopeChip(String label, _ExportScope value) {
    final isSelected = _scope == value;
    return GestureDetector(
      onTap: () => setState(() => _scope = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondary : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppTheme.secondary : AppTheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _dropdownCard<T>({
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

  Widget _formatButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            if (loading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: color, strokeWidth: 2.6),
              )
            else
              Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
