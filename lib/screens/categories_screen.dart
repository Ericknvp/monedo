import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/category_color_service.dart';
import '../services/category_visibility_service.dart';
import '../theme/app_theme.dart';
import '../utils/category_icons.dart';
import '../utils/category_colors.dart';
import '../utils/category_visibility.dart';
import '../widgets/icon_picker.dart';
import '../widgets/category_color_picker.dart';

/// Abre la hoja para crear (o editar, si se pasa [existing]) una categoría
/// propia. Devuelve el nombre de la categoría creada/editada (para poder
/// seleccionarla al instante donde se llamó), o null si se canceló.
Future<String?> showAddCategorySheet(
  BuildContext context, {
  required String userId,
  required Set<String> existingNames,
  CategoryModel? existing,
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
      existing: existing,
    ),
  );
}

/// Abre "Mis categorías": como una ventana modal centrada (con fondo
/// oscurecido) en escritorio, o a pantalla completa en móvil.
Future<void> openCategoriesScreen(BuildContext context) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const CategoriesScreen(isDialog: true),
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
    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
  );
}

class CategoriesScreen extends StatefulWidget {
  final bool isDialog;
  // Incrustada como sección propia del menú lateral de escritorio: sin
  // AppBar ni botón de volver (el encabezado ya lo pone el panel principal).
  final bool embedded;

  const CategoriesScreen({
    super.key,
    this.isDialog = false,
    this.embedded = false,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _categoryService = CategoryService();
  final _visibilityService = CategoryVisibilityService();

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

  void _openEditCategory(CategoryModel category, List<CategoryModel> existing) {
    showAddCategorySheet(
      context,
      userId: _userId,
      existingNames: {
        ...kDefaultCategoryIcons.keys,
        ...existing.map((c) => c.name),
      },
      existing: category,
    );
  }

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
          'Mis categorías',
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

  /// Ventana modal centrada (escritorio).
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
                        child: const Icon(Icons.category_outlined,
                            color: AppTheme.secondary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Mis categorías',
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
        builder: (context, snap) {
          final custom = snap.data ?? [];
          final content = SingleChildScrollView(
                padding: EdgeInsets.all(isDialog ? 24 : (isDesktop ? 32 : 20)),
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
                            onEdit: () => _openEditCategory(c, custom),
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
                    const SizedBox(height: 4),
                    Text(
                      'Deshabilita las que no uses para que no te estorben al registrar un movimiento.',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<Set<String>>(
                      valueListenable: CategoryVisibilityRegistry.disabled,
                      builder: (context, disabledSet, __) => Column(
                        children: kDefaultCategoryIcons.entries
                            .map((e) => _categoryTile(
                                  icon: e.value,
                                  name: e.key,
                                  isDefault: true,
                                  disabled: disabledSet.contains(e.key),
                                  onToggle: (v) => _visibilityService.setDisabled(
                                    userId: _userId,
                                    category: e.key,
                                    disabled: v,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
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
  }

  Widget _categoryTile({
    required IconData icon,
    required String name,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    bool isDefault = false,
    bool disabled = false,
    ValueChanged<bool>? onToggle,
  }) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
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
            ValueListenableBuilder<Map<String, Color>>(
              valueListenable: CategoryColorRegistry.customColors,
              builder: (context, _, __) {
                final color = CategoryColors.forCategory(name);
                return Tooltip(
                  message: 'Cambiar color',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => showCategoryColorPicker(
                      context,
                      userId: _userId,
                      category: name,
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                  ),
                );
              },
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
            if (isDefault)
              Switch(
                value: !disabled,
                activeThumbColor: AppTheme.secondary,
                onChanged: onToggle == null
                    ? null
                    : (v) => onToggle(!v),
              )
            else ...[
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppTheme.onSurfaceVariant, size: 20),
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.errorRed, size: 20),
                  onPressed: onDelete,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddCategorySheet extends StatefulWidget {
  final String userId;
  final Set<String> existingNames;
  final CategoryService categoryService;
  final CategoryModel? existing;

  const _AddCategorySheet({
    required this.userId,
    required this.existingNames,
    required this.categoryService,
    this.existing,
  });

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _colorService = CategoryColorService();
  final _nameCtrl = TextEditingController();
  IconData? _selectedIcon;
  Color? _selectedColor;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _selectedIcon = e.icon;
      _selectedColor = CategoryColorRegistry.customColors.value[e.name];
    }
  }

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
    final renamed =
        !_isEditing || name.toLowerCase() != widget.existing!.name.toLowerCase();
    if (renamed &&
        widget.existingNames.any((e) => e.toLowerCase() == name.toLowerCase())) {
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
    if (_isEditing) {
      await widget.categoryService.updateCategory(
        id: widget.existing!.id,
        userId: widget.userId,
        oldName: widget.existing!.name,
        newName: name,
        iconCodePoint: _selectedIcon!.codePoint,
      );
    } else {
      await widget.categoryService.addCategory(
        userId: widget.userId,
        name: name,
        iconCodePoint: _selectedIcon!.codePoint,
      );
    }
    if (_selectedColor != null) {
      await _colorService.setColor(
        userId: widget.userId,
        category: name,
        color: _selectedColor!,
      );
    }
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
            _isEditing ? 'Editar categoría' : 'Nueva categoría',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Builder(builder: (context) {
            final previewColor = _selectedColor ??
                (_nameCtrl.text.trim().isEmpty
                    ? AppTheme.secondary
                    : CategoryColors.forCategory(_nameCtrl.text.trim()));
            return Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickIcon,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: previewColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: _selectedIcon == null
                        ? const Icon(Icons.add_photo_alternate_outlined,
                            color: AppTheme.onSurfaceVariant)
                        : Icon(_selectedIcon, color: previewColor, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.sentences,
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
            );
          }),
          const SizedBox(height: 20),
          Text(
            'Color',
            style: GoogleFonts.beVietnamPro(
              color: AppTheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: CategoryColors.swatches.map((color) {
              final isSelected = _selectedColor?.value == color.value;
              return InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
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
