import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../utils/category_icons.dart';
import '../widgets/icon_picker.dart';

/// Abre la hoja para crear una categoría propia. Devuelve el nombre de la
/// categoría creada (para poder seleccionarla al instante donde se llamó),
/// o null si se canceló.
Future<String?> showAddCategorySheet(
  BuildContext context, {
  required String userId,
  required Set<String> existingNames,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _AddCategorySheet(
      userId: userId,
      existingNames: existingNames,
      categoryService: CategoryService(),
    ),
  );
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _categoryService = CategoryService();

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar categoría?',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w700)),
        content: Text(
          'Se eliminará "${category.name}". Los movimientos que ya la usan conservarán el nombre, pero sin ícono personalizado.',
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _categoryService.deleteCategory(category.id);
    }
  }

  void _openAddCategory(List<CategoryModel> existing) {
    showAddCategorySheet(
      context,
      userId: _userId,
      existingNames: {
        ...kDefaultCategoryIcons.keys,
        ...existing.map((c) => c.name),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
          'Mis categorías',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _categoryService.getCategories(_userId),
        builder: (context, snap) {
          final custom = snap.data ?? [];
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 640 : 700),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 32 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Crea tus propias categorías con el ícono que quieras, para clasificar tus movimientos a tu manera.',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openAddCategory(custom),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Nueva categoría'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Mis categorías',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (custom.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.surfaceVariant),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.category_outlined,
                                size: 40, color: AppTheme.outlineVariant),
                            const SizedBox(height: 10),
                            Text(
                              'Todavía no has creado categorías propias',
                              style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      ...custom.map((c) => _categoryTile(
                            icon: c.icon,
                            name: c.name,
                            onDelete: () => _confirmDelete(c),
                          )),
                    const SizedBox(height: 32),
                    Text(
                      'Categorías predeterminadas',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...kDefaultCategoryIcons.entries
                        .map((e) => _categoryTile(icon: e.value, name: e.key)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryTile({
    required IconData icon,
    required String name,
    VoidCallback? onDelete,
  }) {
    return Container(
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
              color: AppTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.secondary, size: 20),
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
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.errorRed, size: 20),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _AddCategorySheet extends StatefulWidget {
  final String userId;
  final Set<String> existingNames;
  final CategoryService categoryService;

  const _AddCategorySheet({
    required this.userId,
    required this.existingNames,
    required this.categoryService,
  });

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  IconData? _selectedIcon;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final icon = await showIconPicker(context, selected: _selectedIcon);
    if (icon != null) setState(() => _selectedIcon = icon);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Ponle un nombre a la categoría');
      return;
    }
    if (widget.existingNames.any((e) => e.toLowerCase() == name.toLowerCase())) {
      setState(() => _error = 'Ya existe una categoría con ese nombre');
      return;
    }
    if (_selectedIcon == null) {
      setState(() => _error = 'Elige un ícono para la categoría');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await widget.categoryService.addCategory(
      userId: widget.userId,
      name: name,
      iconCodePoint: _selectedIcon!.codePoint,
    );
    if (mounted) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
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
            'Nueva categoría',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickIcon,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: _selectedIcon == null
                      ? const Icon(Icons.add_photo_alternate_outlined,
                          color: AppTheme.onSurfaceVariant)
                      : Icon(_selectedIcon, color: AppTheme.secondary, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: GoogleFonts.beVietnamPro(
                      color: AppTheme.primary, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Nombre de la categoría',
                    hintText: 'Ej: Suscripciones',
                    labelStyle: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.errorRed, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : Text('Crear categoría',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
