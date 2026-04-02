// ============================================================
// add_transaction_screen.dart
// Pantalla para agregar o editar un movimiento (ingreso o gasto).
// Si se pasa una transacción existente, entra en modo edición.
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _transactionService = TransactionService();

  bool _isIncome = false;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Otros';

  final List<String> _categories = [
    'Alimentación',
    'Transporte',
    'Entretenimiento',
    'Salud',
    'Educación',
    'Ropa',
    'Hogar',
    'Trabajo',
    'Inversión',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _titleController.text = t.title;
      _amountController.text = t.amount.toString();
      _noteController.text = t.note ?? '';
      _isIncome = t.isIncome;
      _selectedDate = t.date;
      _selectedCategory = t.category;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryPurple,
              surface: AppTheme.cardDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: AppTheme.expense,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto debe ser un número válido mayor a 0'),
          backgroundColor: AppTheme.expense,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final transaction = TransactionModel(
      id: widget.transaction?.id ?? '',
      userId: userId,
      title: _titleController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      isIncome: _isIncome,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (widget.transaction != null) {
      await _transactionService.updateTransaction(transaction);
    } else {
      await _transactionService.addTransaction(transaction);
    }

    setState(() => _isLoading = false);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: Text(
          isEditing ? 'Editar movimiento' : 'Nuevo movimiento',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Selector ingreso/gasto ----
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isIncome = false),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isIncome
                              ? AppTheme.expense
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '💸 Gasto',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isIncome = true),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isIncome
                              ? AppTheme.income
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '💰 Ingreso',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ---- Campo de título ----
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Descripción',
                prefixIcon: Icon(Icons.description_outlined,
                    color: AppTheme.accentPurple),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Campo de monto ----
            TextField(
              controller: _amountController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixIcon: Icon(Icons.attach_money,
                    color: AppTheme.accentPurple),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Selector de categoría ----
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: AppTheme.cardDark,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined,
                    color: AppTheme.accentPurple),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            const SizedBox(height: 16),

            // ---- Selector de fecha ----
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardMedium,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppTheme.accentPurple),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style:
                      const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Campo de nota opcional ----
            TextField(
              controller: _noteController,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                prefixIcon: Icon(Icons.note_outlined,
                    color: AppTheme.accentPurple),
              ),
            ),
            const SizedBox(height: 32),

            // ---- Botón guardar ----
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator(
                    color: AppTheme.textPrimary)
                    : Text(
                  isEditing
                      ? 'Guardar cambios'
                      : 'Agregar movimiento',
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