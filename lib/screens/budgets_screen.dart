import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../services/category_service.dart';
import '../services/budget_service.dart';
import '../theme/app_theme.dart';
import '../utils/category_icons.dart';
import '../utils/category_colors.dart';
import '../utils/category_visibility.dart';
import '../utils/currency_formatter.dart';
import '../widgets/budget_editor.dart';

/// Abre "Presupuestos": como una ventana modal centrada (con fondo
/// oscurecido) en escritorio, o a pantalla completa en móvil.
Future<void> openBudgetsScreen(BuildContext context) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const BudgetsScreen(isDialog: true),
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
    MaterialPageRoute(builder: (_) => const BudgetsScreen()),
  );
}

class BudgetsScreen extends StatefulWidget {
  final bool isDialog;
  // Incrustada como sección propia del menú lateral de escritorio: sin
  // AppBar ni botón de volver (el encabezado ya lo pone el panel principal).
  final bool embedded;

  const BudgetsScreen({
    super.key,
    this.isDialog = false,
    this.embedded = false,
  });

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _categoryService = CategoryService();
  final _budgetService = BudgetService();

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) return _buildDialog();
    if (widget.embedded) return _buildBody();

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
          'Presupuestos',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
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
                          color: AppTheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.pie_chart_outline_rounded,
                            color: AppTheme.secondary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Presupuestos',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontSize: 19,
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
                ),
                Expanded(child: _buildBody(isDialog: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({bool isDialog = false}) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return StreamBuilder<List<CategoryModel>>(
      stream: _categoryService.getCategories(_userId),
      builder: (context, customSnap) {
        final custom = customSnap.data ?? [];
        return ValueListenableBuilder<Set<String>>(
          valueListenable: CategoryVisibilityRegistry.disabled,
          builder: (context, disabledDefaults, __) {
            final categories = <String>[
              ...kDefaultCategoryIcons.keys
                  .where((n) => n != 'Transferencia' && !disabledDefaults.contains(n)),
              ...custom.map((c) => c.name),
            ];

            return StreamBuilder<List<BudgetModel>>(
              stream: _budgetService.getBudgets(_userId),
              builder: (context, budgetSnap) {
                final budgets = {
                  for (final b in (budgetSnap.data ?? [])) b.category: b,
                };

                final content = SingleChildScrollView(
                  padding: EdgeInsets.all(isDialog ? 24 : (isDesktop ? 32 : 20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fija un límite mensual por categoría. Lo verás como una barra de progreso en Estadísticas, comparado contra lo que llevas gastado ese mes.',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...categories.map((name) => _categoryRow(
                            name: name,
                            icon: CategoryIconRegistry.iconFor(name),
                            budget: budgets[name],
                          )),
                    ],
                  ),
                );

                if (isDialog) return content;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 640 : 700),
                    child: content,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _categoryRow({
    required String name,
    required IconData icon,
    BudgetModel? budget,
  }) {
    final color = CategoryColors.forCategory(name);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showBudgetEditor(
        context,
        userId: _userId,
        category: name,
        current: budget,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surfaceVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              budget != null
                  ? CurrencyFormatter.format(budget.monthlyLimit)
                  : 'Sin límite',
              style: GoogleFonts.beVietnamPro(
                color: budget != null
                    ? AppTheme.primary
                    : AppTheme.outline,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
