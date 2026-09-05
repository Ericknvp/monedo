import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

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
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondary),
          );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: g.imageUrl != null && g.imageUrl!.isNotEmpty
                  ? Image.network(
                      g.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _banner(accentColor),
                    )
                  : _banner(accentColor),
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
                      IconButton(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined,
                            color: AppTheme.onSurfaceVariant, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _confirmDelete(context),
                        icon: Icon(Icons.delete_outline,
                            color: AppTheme.errorRed, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              style: GoogleFonts.beVietnamPro(color: AppTheme.primary),
              decoration: InputDecoration(
                labelText: 'Monto a ahorrar',
                labelStyle: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant),
              ),
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
              final amount = double.tryParse(ctrl.text.trim());
              if (amount != null && amount > 0) {
                await widget.goalService.addSavingsToGoal(
                    goal: widget.goal, amount: amount);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.savings_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                              '${CurrencyFormatter.format(amount)} ahorrado'),
                        ],
                      ),
                      backgroundColor: AppTheme.secondary,
                    ),
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
  late final TextEditingController _imageCtrl;
  late final TextEditingController _noteCtrl;
  bool _isLoading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _titleCtrl = TextEditingController(text: g?.title ?? '');
    _targetCtrl = TextEditingController(
        text: g != null ? g.targetAmount.toStringAsFixed(0) : '');
    _imageCtrl = TextEditingController(text: g?.imageUrl ?? '');
    _noteCtrl = TextEditingController(text: g?.note ?? '');
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _targetCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos obligatorios'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    final target = double.tryParse(_targetCtrl.text.trim());
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto debe ser mayor a 0'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    if (_isEditing) {
      await widget.goalService.updateGoal(widget.existing!.copyWith(
        title: _titleCtrl.text.trim(),
        targetAmount: target,
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ));
    } else {
      await widget.goalService.addGoal(GoalModel(
        id: '',
        userId: widget.userId,
        title: _titleCtrl.text.trim(),
        targetAmount: target,
        savedAmount: 0,
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
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
    _imageCtrl.dispose();
    _noteCtrl.dispose();
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
                hint: 'Ej: 7000000'),
            const SizedBox(height: 20),
            _field(_imageCtrl, 'URL de imagen (opcional)',
                hint: 'https://...'),
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

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
