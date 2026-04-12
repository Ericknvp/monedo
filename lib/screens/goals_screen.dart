
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: StreamBuilder<List<GoalModel>>(
        stream: goalService.getGoals(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPurple),
            );
          }

          final goals = snapshot.data ?? [];

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined,
                      size: 72, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no tienes metas',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea tu primera meta de ahorro',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showGoalSheet(context, userId, goalService),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva meta'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              return _GoalCard(
                goal: goals[index],
                goalService: goalService,
                userId: userId,
              );
            },
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton(
          backgroundColor: AppTheme.primaryPurple,
          onPressed: () => _showGoalSheet(ctx, userId, goalService),
          child: const Icon(Icons.add, color: AppTheme.textPrimary),
        ),
      ),
    );
  }

  // ---- Abre el sheet para crear o editar meta ----
  static void _showGoalSheet(
      BuildContext context,
      String userId,
      GoalService goalService, {
        GoalModel? existing,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
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

// ============================================================
// Tarjeta de meta individual
// ============================================================
class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final GoalService goalService;
  final String userId;

  const _GoalCard({
    required this.goal,
    required this.goalService,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final percent = goal.progressPercent;
    final color = goal.isCompleted ? AppTheme.income : AppTheme.primaryPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Imagen ----
          if (goal.imageUrl != null && goal.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                goal.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              ),
            )
          else
            _imagePlaceholder(rounded: true),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Título + badge + botones ----
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (goal.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.income.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '✅ Completada',
                          style: TextStyle(
                            color: AppTheme.income,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // ---- Botón editar ----
                    IconButton(
                      onPressed: () => GoalsScreen._showGoalSheet(
                        context,
                        userId,
                        goalService,
                        existing: goal,
                      ),
                      icon: const Icon(Icons.edit_outlined,
                          color: AppTheme.accentPurple, size: 20),
                      tooltip: 'Editar meta',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    // ---- Botón eliminar ----
                    IconButton(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.expense, size: 20),
                      tooltip: 'Eliminar meta',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                if (goal.note != null && goal.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    goal.note!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),

                // ---- Montos ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ahorrado',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(goal.savedAmount),
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Meta',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(goal.targetAmount),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ---- Barra de progreso ----
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(percent * 100).toStringAsFixed(1)}% completado',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Falta: ${CurrencyFormatter.format(goal.remaining)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // ---- Botón ahorrar ----
                if (!goal.isCompleted) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddSavingsDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar ahorro'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder({bool rounded = false}) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: rounded
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : null,
      ),
      child: const Center(
        child: Icon(Icons.flag, color: Colors.white54, size: 36),
      ),
    );
  }

  void _showAddSavingsDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Agregar ahorro',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meta: ${goal.title}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
              Text(
                'Falta: ${CurrencyFormatter.format(goal.remaining)}',
                style: const TextStyle(
                    color: AppTheme.accentPurple, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Monto a ahorrar',
                  prefixIcon: Icon(Icons.attach_money,
                      color: AppTheme.accentPurple),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un monto';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(controller.text.trim());
                await goalService.addSavingsToGoal(
                    goal: goal, amount: amount);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${CurrencyFormatter.format(amount)} ahorrado 🎯'),
                      backgroundColor: AppTheme.income,
                    ),
                  );
                }
              }
            },
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
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar meta?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Se eliminará "${goal.title}". El dinero ahorrado no se devolverá al balance.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await goalService.deleteGoal(goal.id);
    }
  }
}

// ============================================================
// Sheet para crear O editar una meta
// ============================================================
class _GoalSheet extends StatefulWidget {
  final String userId;
  final GoalService goalService;
  final GoalModel? existing; // null = crear, not null = editar

  const _GoalSheet({
    required this.userId,
    required this.goalService,
    this.existing,
  });

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _imageController;
  late final TextEditingController _noteController;
  bool _isLoading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _titleController = TextEditingController(text: g?.title ?? '');
    _targetController = TextEditingController(
        text: g != null ? g.targetAmount.toStringAsFixed(0) : '');
    _imageController = TextEditingController(text: g?.imageUrl ?? '');
    _noteController = TextEditingController(text: g?.note ?? '');
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _targetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos obligatorios'),
          backgroundColor: AppTheme.expense,
        ),
      );
      return;
    }

    final target = double.tryParse(_targetController.text.trim());
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El precio de la meta debe ser mayor a 0'),
          backgroundColor: AppTheme.expense,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_isEditing) {
      // ---- Modo edición: conserva savedAmount y createdAt ----
      final updated = widget.existing!.copyWith(
        title: _titleController.text.trim(),
        targetAmount: target,
        imageUrl: _imageController.text.trim().isEmpty
            ? null
            : _imageController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      await widget.goalService.updateGoal(updated);
    } else {
      // ---- Modo creación ----
      final goal = GoalModel(
        id: '',
        userId: widget.userId,
        title: _titleController.text.trim(),
        targetAmount: target,
        savedAmount: 0,
        imageUrl: _imageController.text.trim().isEmpty
            ? null
            : _imageController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: DateTime.now(),
      );
      await widget.goalService.addGoal(goal);
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _imageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---- Handle ----
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _isEditing ? '✏️ Editar meta' : '🎯 Nueva meta de ahorro',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nombre de la meta',
                prefixIcon:
                Icon(Icons.flag_outlined, color: AppTheme.accentPurple),
                hintText: 'Ej: Moto, Viaje, Computador...',
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _targetController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Precio de la meta',
                prefixIcon: Icon(Icons.attach_money,
                    color: AppTheme.accentPurple),
                hintText: 'Ej: 7000000',
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _imageController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'URL de imagen (opcional)',
                prefixIcon:
                Icon(Icons.image_outlined, color: AppTheme.accentPurple),
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                prefixIcon: Icon(Icons.note_outlined,
                    color: AppTheme.accentPurple),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator(
                    color: AppTheme.textPrimary)
                    : Text(
                  _isEditing ? 'Guardar cambios' : 'Crear meta',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
