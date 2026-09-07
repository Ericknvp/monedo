import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/goal_service.dart';
import '../services/account_service.dart';
import '../services/transaction_service.dart';
import '../services/image_upload_service.dart';
import '../models/goal.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/amount_input_formatter.dart';
import '../widgets/app_toast.dart';
import '../widgets/branded_loading_screen.dart';
import '../widgets/blurred_image_frame.dart';
import 'add_transaction_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final goalService = GoalService();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return StreamBuilder<List<GoalModel>>(
      stream: goalService.getGoals(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: BrandedInlineLoader());
        }

        final goals = snap.data ?? [];

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: goals.isEmpty
              ? _buildEmptyState(context, userId, goalService)
              : _buildGoalsList(context, goals, userId, goalService, isDesktop),
          floatingActionButton: goals.isNotEmpty
              ? FloatingActionButton.extended(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  onPressed: () =>
                      _showGoalSheet(context, userId, goalService),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Crear meta',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(
      BuildContext context, String userId, GoalService goalService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(Icons.savings_outlined,
                size: 40, color: AppTheme.outlineVariant),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin metas aún',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera meta de ahorro',
            style: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _showGoalSheet(context, userId, goalService),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('Crear meta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(
    BuildContext context,
    List<GoalModel> goals,
    String userId,
    GoalService goalService,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 40 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metas de ahorro',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.56,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pequeños pasos llevan a grandes destinos.',
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showGoalSheet(context, userId, goalService),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Crear meta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
          isDesktop
              ? _buildDesktopGrid(context, goals, userId, goalService)
              : _buildMobileList(context, goals, userId, goalService),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(
    BuildContext context,
    List<GoalModel> goals,
    String userId,
    GoalService goalService,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200 ? 3 : 2;
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            ...goals.map((g) => SizedBox(
                  width: (constraints.maxWidth - (columns - 1) * 24) / columns,
                  child: _GoalCard(
                    goal: g,
                    goalService: goalService,
                    userId: userId,
                    onEdit: () =>
                        _showGoalSheet(context, userId, goalService, existing: g),
                  ),
                )),
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 24) / columns,
              height: 200,
              child: GestureDetector(
                onTap: () => _showGoalSheet(context, userId, goalService),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.outlineVariant,
                        width: 2,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Icon(Icons.add_circle_outline_rounded,
                            size: 28, color: AppTheme.outlineVariant),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Agregar meta',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    List<GoalModel> goals,
    String userId,
    GoalService goalService,
  ) {
    return Column(
      children: goals
          .map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _GoalCard(
                  goal: g,
                  goalService: goalService,
                  userId: userId,
                  onEdit: () =>
                      _showGoalSheet(context, userId, goalService, existing: g),
                ),
              ))
          .toList(),
    );
  }

  static void _showGoalSheet(
    BuildContext context,
    String userId,
    GoalService goalService, {
    GoalModel? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _GoalSheet(
        userId: userId,
        goalService: goalService,
        existing: existing,
      ),
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────
class _GoalCard extends StatefulWidget {
  final GoalModel goal;
  final GoalService goalService;
  final String userId;
  final VoidCallback onEdit;

  const _GoalCard({
    required this.goal,
    required this.goalService,
    required this.userId,
    required this.onEdit,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _hovered = false;
  final _txService = TransactionService();

  Future<bool> _confirmInsufficientFunds(
      BuildContext context, String accountName, double balance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Fondos insuficientes',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w700)),
        content: Text(
          '"$accountName" tiene ${CurrencyFormatter.format(balance)}. Este ahorro dejaría la cuenta en negativo. ¿Quieres continuar de todas formas?',
          style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              shape: const StadiumBorder(),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  // Hoja de detalle completa de la meta: imagen grande, datos, acciones
  // (editar/eliminar/agregar ahorro) e historial de aportes, todo junto.
  void _showDetail(BuildContext context) {
    final g = widget.goal;
    final percent = g.progressPercent;
    final isComplete = g.isCompleted;
    final accentColor = isComplete ? AppTheme.secondary : AppTheme.primary;
    final hasImage = g.imageUrl != null && g.imageUrl!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: hasImage
                      ? BlurredImageFrame(url: g.imageUrl)
                      : _banner(accentColor),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              g.title,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primary,
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isComplete)
                            Container(
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryContainer
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: AppTheme.onSecondaryContainer,
                                      size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completada',
                                    style: GoogleFonts.beVietnamPro(
                                      color: AppTheme.onSecondaryContainer,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (g.note != null && g.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          g.note!,
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ahorrado',
                                  style: GoogleFonts.beVietnamPro(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize: 11)),
                              Text(
                                CurrencyFormatter.format(g.savedAmount),
                                style: GoogleFonts.plusJakartaSans(
                                  color: accentColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Meta',
                                  style: GoogleFonts.beVietnamPro(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize: 11)),
                              Text(
                                CurrencyFormatter.format(g.targetAmount),
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: accentColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(percent * 100).toStringAsFixed(1)}% completado',
                            style: GoogleFonts.beVietnamPro(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Falta: ${CurrencyFormatter.format(g.remaining)}',
                            style: GoogleFonts.beVietnamPro(
                                color: AppTheme.onSurfaceVariant, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetCtx);
                                widget.onEdit();
                              },
                              icon: const Icon(Icons.edit_outlined, size: 17),
                              label: const Text('Editar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(
                                    color: AppTheme.outlineVariant),
                                shape: const StadiumBorder(),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetCtx);
                                _confirmDelete(context);
                              },
                              icon: Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.errorRed, size: 17),
                              label: Text('Eliminar',
                                  style:
                                      TextStyle(color: AppTheme.errorRed)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: AppTheme.errorRed.withOpacity(0.4)),
                                shape: const StadiumBorder(),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isComplete) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showAddSavings(sheetCtx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryFixed,
                              foregroundColor: AppTheme.onSecondaryFixed,
                              shape: const StadiumBorder(),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: Text(
                              'Agregar ahorro',
                              style: GoogleFonts.beVietnamPro(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      const Divider(color: AppTheme.surfaceVariant),
                      const SizedBox(height: 20),
                      Text(
                        'Historial de aportes',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      StreamBuilder<List<TransactionModel>>(
                        stream: _txService.getGoalContributions(
                            widget.userId, widget.goal.id),
                        builder: (context, snap) {
                          final contributions = snap.data ?? [];
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: BrandedInlineLoader(size: 32)),
                            );
                          }
                          if (contributions.isEmpty) {
                            return Text(
                              'Todavía no has agregado ahorros a esta meta.',
                              style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.onSurfaceVariant),
                            );
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < contributions.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                      height: 1,
                                      color: AppTheme.surfaceVariant),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      Navigator.pop(sheetCtx);
                                      openAddTransaction(context,
                                          transaction: contributions[i]);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: AppTheme.secondary
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.savings_rounded,
                                                color: AppTheme.secondary,
                                                size: 16),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '${contributions[i].date.day}/${contributions[i].date.month}/${contributions[i].date.year}',
                                              style: GoogleFonts.beVietnamPro(
                                                color:
                                                    AppTheme.onSurfaceVariant,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(
                                                contributions[i].amount),
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppTheme.primary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppTheme.onSurfaceVariant,
                                              size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.goal;
    final percent = g.progressPercent;
    final isComplete = g.isCompleted;
    final accentColor = isComplete ? AppTheme.secondary : AppTheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary
                  .withOpacity(_hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 40 : 20,
              offset: Offset(0, _hovered ? 16 : 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDetail(context),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            SizedBox(
              height: 140,
              width: double.infinity,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: g.imageUrl != null && g.imageUrl!.isNotEmpty
                    ? BlurredImageFrame(url: g.imageUrl)
                    : _banner(accentColor),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          g.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: AppTheme.onSecondaryContainer,
                                  size: 13),
                              const SizedBox(width: 4),
                              Text(
                                'Completada',
                                style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.onSecondaryContainer,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Creada el ${g.createdAt.day}/${g.createdAt.month}/${g.createdAt.year}',
                    style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant, fontSize: 11),
                  ),
                  if (g.note != null && g.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      g.note!,
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Amounts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ahorrado',
                              style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 11)),
                          Text(
                            CurrencyFormatter.format(g.savedAmount),
                            style: GoogleFonts.plusJakartaSans(
                              color: accentColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Meta',
                              style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 11)),
                          Text(
                            CurrencyFormatter.format(g.targetAmount),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: accentColor.withOpacity(0.1),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(percent * 100).toStringAsFixed(1)}% completado',
                        style: GoogleFonts.beVietnamPro(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Falta: ${CurrencyFormatter.format(g.remaining)}',
                        style: GoogleFonts.beVietnamPro(
                            color: AppTheme.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),

                  // Add savings button
                  if (!isComplete) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showAddSavings(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryFixed,
                          foregroundColor: AppTheme.onSecondaryFixed,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          'Agregar ahorro',
                          style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _banner(Color color) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryContainer, color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.savings_rounded,
            color: Colors.white54, size: 36),
      ),
    );
  }

  void _showAddSavings(BuildContext context) {
    final ctrl = TextEditingController();
    final accountService = AccountService();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String? selectedAccountId;
    List<AccountModel> accountsCache = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Agregar ahorro',
              style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Meta: ${widget.goal.title}  •  Falta: ${CurrencyFormatter.format(widget.goal.remaining)}',
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AmountInputFormatter()],
                style: GoogleFonts.beVietnamPro(color: AppTheme.primary),
                decoration: InputDecoration(
                  labelText: 'Monto a ahorrar',
                  labelStyle: GoogleFonts.beVietnamPro(
                      color: AppTheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<AccountModel>>(
                stream: accountService.getAccounts(userId),
                builder: (context, snap) {
                  final accounts = snap.data ?? [];
                  accountsCache = accounts;
                  return DropdownButtonFormField<String>(
                    value: selectedAccountId,
                    dropdownColor: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 3,
                    style: GoogleFonts.beVietnamPro(color: AppTheme.primary),
                    hint: Text('¿De qué cuenta sale?',
                        style: GoogleFonts.beVietnamPro(
                            color: AppTheme.outline, fontSize: 14)),
                    decoration: InputDecoration(
                      labelText: 'Cuenta',
                      labelStyle: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant),
                    ),
                    items: accounts
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedAccountId = v),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppTheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = CurrencyFormatter.parse(ctrl.text.trim());
                if (amount != null && amount > 0 && selectedAccountId != null) {
                  AccountModel? account;
                  for (final a in accountsCache) {
                    if (a.id == selectedAccountId) {
                      account = a;
                      break;
                    }
                  }
                  if (account != null && amount > account.balance) {
                    final proceed = await _confirmInsufficientFunds(
                        context, account.name, account.balance);
                    if (!proceed) return;
                  }
                  await widget.goalService.addSavingsToGoal(
                    goal: widget.goal,
                    amount: amount,
                    accountId: selectedAccountId!,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    showAppToast(
                      context,
                      message:
                          '${CurrencyFormatter.format(amount)} ahorrado',
                      icon: Icons.savings_rounded,
                      accentColor: AppTheme.secondary,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                shape: const StadiumBorder(),
              ),
              child: const Text('Ahorrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Eliminar meta?',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
        content: Text(
          'Se eliminará "${widget.goal.title}". El dinero ahorrado no se devolverá al balance.',
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
    if (confirm == true) {
      await widget.goalService.deleteGoal(widget.goal.id);
    }
  }
}

// ── Goal Sheet ────────────────────────────────────────────────
class _GoalSheet extends StatefulWidget {
  final String userId;
  final GoalService goalService;
  final GoalModel? existing;

  const _GoalSheet({
    required this.userId,
    required this.goalService,
    this.existing,
  });

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _initialSavedCtrl;
  bool _isLoading = false;
  // Solo aplica al crear una meta nueva: si ya tenía ahorros previos (fuera
  // de la app) para esto, ese monto inicial se guarda tal cual en la meta
  // SIN descontarlo de ninguna cuenta ni registrar un movimiento, porque no
  // es dinero que esté saliendo ahora del balance.
  bool _hasExistingSavings = false;

  // Imagen: _existingImageUrl es la que ya tenía la meta (al editar);
  // _pickedImage/_pickedBytes son la foto nueva elegida en esta sesión, que
  // se sube a Cloudinary recién al guardar. _pickedBytes se guarda aparte
  // para previsualizar con Image.memory sin depender de dart:io (necesario
  // para que funcione también en web).
  String? _existingImageUrl;
  XFile? _pickedImage;
  Uint8List? _pickedBytes;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _titleCtrl = TextEditingController(text: g?.title ?? '');
    _targetCtrl = TextEditingController(
        text: g != null ? CurrencyFormatter.formatNumber(g.targetAmount) : '');
    _existingImageUrl = g?.imageUrl;
    _noteCtrl = TextEditingController(text: g?.note ?? '');
    _initialSavedCtrl = TextEditingController();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImage = picked;
      _pickedBytes = bytes;
    });
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _pickedBytes = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _targetCtrl.text.trim().isEmpty) {
      showAppToast(
        context,
        message: 'Por favor completa los campos obligatorios',
        icon: Icons.error_outline_rounded,
        accentColor: AppTheme.errorRed,
      );
      return;
    }
    final target = CurrencyFormatter.parse(_targetCtrl.text.trim());
    if (target == null || target <= 0) {
      showAppToast(
        context,
        message: 'El monto debe ser mayor a 0',
        icon: Icons.error_outline_rounded,
        accentColor: AppTheme.errorRed,
      );
      return;
    }
    setState(() => _isLoading = true);

    // Si se eligió una foto nueva, se sube recién ahora (no en cuanto se
    // elige) para no gastar cupo de Cloudinary si al final no se guarda.
    String? imageUrl = _existingImageUrl;
    if (_pickedImage != null) {
      imageUrl = await ImageUploadService().uploadImage(_pickedImage!);
      if (imageUrl == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          showAppToast(
            context,
            message: 'No se pudo subir la foto, intenta de nuevo',
            icon: Icons.error_outline_rounded,
            accentColor: AppTheme.errorRed,
          );
        }
        return;
      }
    }

    if (_isEditing) {
      await widget.goalService.updateGoal(widget.existing!.copyWith(
        title: _titleCtrl.text.trim(),
        targetAmount: target,
        imageUrl: imageUrl,
        removeImage: imageUrl == null,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ));
    } else {
      final initialSaved = _hasExistingSavings
          ? (CurrencyFormatter.parse(_initialSavedCtrl.text.trim()) ?? 0)
          : 0.0;
      await widget.goalService.addGoal(GoalModel(
        id: '',
        userId: widget.userId,
        title: _titleCtrl.text.trim(),
        targetAmount: target,
        savedAmount: initialSaved,
        imageUrl: imageUrl,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: DateTime.now(),
      ));
    }
    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _noteCtrl.dispose();
    _initialSavedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 28, right: 28, top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
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
              _isEditing ? 'Editar meta' : 'Nueva meta de ahorro',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _field(_titleCtrl, 'Nombre de la meta',
                hint: 'Ej: Moto, Viaje, Computador...'),
            const SizedBox(height: 20),
            _field(_targetCtrl, 'Precio de la meta',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AmountInputFormatter()],
                hint: 'Ej: 7000000'),
            if (!_isEditing) ...[
              const SizedBox(height: 20),
              Text(
                '¿Ya tienes algo ahorrado para esto, o es una meta nueva?',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _savingsChoiceChip(
                      label: 'Meta nueva',
                      selected: !_hasExistingSavings,
                      onTap: () => setState(() => _hasExistingSavings = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _savingsChoiceChip(
                      label: 'Ya tengo ahorros',
                      selected: _hasExistingSavings,
                      onTap: () => setState(() => _hasExistingSavings = true),
                    ),
                  ),
                ],
              ),
              if (_hasExistingSavings) ...[
                const SizedBox(height: 16),
                _field(_initialSavedCtrl, 'Cuánto ya tienes ahorrado',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    hint: 'Ej: 500000'),
                const SizedBox(height: 8),
                Text(
                  'Este monto se suma a la meta directamente, sin descontarse de ninguna cuenta.',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            _buildImagePicker(),
            const SizedBox(height: 20),
            _field(_noteCtrl, 'Nota (opcional)', maxLines: 2),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditing ? 'Guardar cambios' : 'Crear meta',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _pickedBytes != null ||
        (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto de la meta (opcional)',
          style: GoogleFonts.beVietnamPro(
              color: AppTheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 140,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_pickedBytes != null)
                    BlurredImageFrame(bytes: _pickedBytes)
                  else if (_existingImageUrl != null &&
                      _existingImageUrl!.isNotEmpty)
                    BlurredImageFrame(url: _existingImageUrl)
                  else
                    _imagePickerEmptyState(),
                  if (hasImage) ...[
                    Positioned(
                      top: 8,
                      right: 8,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text('Cambiar',
                                style: GoogleFonts.beVietnamPro(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePickerEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              color: AppTheme.onSurfaceVariant, size: 28),
          const SizedBox(height: 6),
          Text(
            'Agregar foto',
            style: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _savingsChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
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

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: TextCapitalization.sentences,
      style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.beVietnamPro(
            color: AppTheme.onSurfaceVariant, fontSize: 13),
        hintStyle: GoogleFonts.beVietnamPro(
            color: AppTheme.outlineVariant, fontSize: 14),
      ),
    );
  }
}
