import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';
import '../screens/accounts_screen.dart';
import '../screens/categories_screen.dart';
import '../services/account_service.dart';
import '../theme/app_theme.dart';
import '../utils/account_colors.dart';
import '../utils/category_colors.dart';
import '../utils/category_icons.dart';
import '../utils/category_visibility.dart';
import 'app_text_field.dart';

/// Piezas compartidas del formulario "nuevo estilo" introducido en
/// add_transaction_screen.dart (campo con halo de foco, selector de
/// categoría en grilla, selector de bolsillo, botón píldora flotante), para
/// que el resto de formularios de la app (recurrentes, presupuestos, metas,
/// bolsillos...) usen exactamente los mismos componentes en vez de reinventar
/// cada campo con su propio `TextField`/`DropdownButtonFormField`.

/// Etiqueta pequeña sobre un campo (Be Vietnam Pro, w600, onSurfaceVariant).
class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(this.text, {super.key, this.dense = false});

  final String text;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 6 : 8, left: 2),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          color: AppTheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Botón tipo píldora con sombra propia, para que "flote" sobre el
/// contenido en vez de aparecer dentro de una barra sólida — usado en el
/// footer de los diálogos de escritorio.
class FloatingPillButton extends StatelessWidget {
  const FloatingPillButton({
    super.key,
    required this.color,
    required this.onTap,
    required this.child,
    this.width,
  });

  final Color color;
  final VoidCallback? onTap;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
            child: Center(widthFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}

/// Botón primario a todo el ancho para el footer fijo de móvil (fuera del
/// scroll), con spinner mientras `isLoading`.
class FullWidthPrimaryButton extends StatelessWidget {
  const FullWidthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successFixed,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.4),
              )
            : Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

/// Texto de acción discreto en rojo (usado para "Eliminar X" bajo el botón
/// primario, tanto en el footer de móvil como en el de escritorio).
class DangerTextAction extends StatelessWidget {
  const DangerTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.delete_outline_rounded,
          color: AppTheme.errorRed, size: dense ? 17 : 16),
      label: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          color: AppTheme.errorRed,
          fontWeight: dense ? FontWeight.w700 : FontWeight.w600,
          fontSize: dense ? 13 : 12.5,
        ),
      ),
    );
  }
}

/// Confirmación estándar antes de una acción destructiva (eliminar regla,
/// meta, presupuesto...) — mismo `AlertDialog` en toda la app.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Eliminar',
}) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primary, fontWeight: FontWeight.w700)),
      content: Text(
        message,
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
          child: Text(confirmLabel,
              style: TextStyle(
                  color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return confirm == true;
}

/// Chip compacto usado dentro del selector de bolsillo (ícono coloreado +
/// nombre), tanto colapsado como dentro de la lista desplegable.
Widget _accountChip(AccountModel account) {
  final color = AccountColors.forAccount(account);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
        child: const Icon(Icons.account_balance_wallet_rounded,
            size: 11, color: Colors.white),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          account.name,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.beVietnamPro(
              color: AppTheme.primary, fontSize: 14.5, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}

/// Selector de bolsillo: `AppFieldShell` + `DropdownButton` nativo, con un
/// link "Agregar bolsillo" debajo — mismo componente que usa el formulario de
/// movimientos, para que cualquier form que necesite elegir bolsillo se vea
/// igual.
class AccountPickerField extends StatelessWidget {
  const AccountPickerField({
    super.key,
    required this.selectedAccountId,
    required this.onChanged,
    this.label = 'Bolsillo',
    this.dense = false,
    this.showAddAccount = true,
  });

  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool dense;
  final bool showAddAccount;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<AccountModel>>(
      stream: AccountService().getAccounts(userId),
      builder: (context, snap) {
        final accounts = snap.data ?? [];
        final hasSelection = accounts.any((a) => a.id == selectedAccountId);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(label, dense: dense),
            AppFieldShell(
              icon: Icons.account_balance_wallet_outlined,
              dense: dense,
              trailing: Icon(Icons.expand_more_rounded,
                  color: AppTheme.onSurfaceVariant, size: 18),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: hasSelection ? selectedAccountId : null,
                  isExpanded: true,
                  isDense: true,
                  icon: const SizedBox.shrink(),
                  dropdownColor: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  hint: Text('Selecciona un bolsillo',
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.outline, fontSize: 14)),
                  selectedItemBuilder: (context) => accounts
                      .map((a) => Align(
                          alignment: Alignment.centerLeft,
                          child: _accountChip(a)))
                      .toList(),
                  items: accounts
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: _accountChip(a),
                          ))
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
            if (showAddAccount) ...[
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final created =
                      await showAddAccountSheet(context, userId: userId);
                  if (created != null) onChanged(created);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          size: 15, color: AppTheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        'Agregar bolsillo',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.secondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Selector de categoría en grilla (tarjetas 52px con ícono + nombre en
/// móvil, chips compactos en fila en escritorio), con "mostrar más" cuando
/// hay muchas categorías — mismo componente que usa el formulario de
/// movimientos. Siempre incluye las categorías predeterminadas visibles
/// más las personalizadas del usuario, y la seleccionada va primero.
class CategoryPickerField extends StatefulWidget {
  const CategoryPickerField({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    this.compact = false,
    this.showQuickLinks = true,
  });

  final String selectedCategory;
  final ValueChanged<String> onChanged;
  final bool compact;
  /// Muestra "Agregar categoría" / "Mis categorías" bajo la grilla.
  final bool showQuickLinks;

  @override
  State<CategoryPickerField> createState() => _CategoryPickerFieldState();
}

class _CategoryPickerFieldState extends State<CategoryPickerField> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    return ValueListenableBuilder<Map<String, IconData>>(
      valueListenable: CategoryIconRegistry.customIcons,
      builder: (context, customIcons, _) {
        return ValueListenableBuilder<Set<String>>(
          valueListenable: CategoryVisibilityRegistry.disabled,
          builder: (context, disabledDefaults, __) {
            final customNames = customIcons.keys
                .where((n) => !kDefaultCategoryIcons.containsKey(n))
                .toList()
              ..sort();
            // "Transferencia" es una categoría de sistema (la asigna la app
            // al mover dinero entre bolsillos propios), nunca elegible a mano.
            final visibleDefaults = kDefaultCategoryIcons.keys.where((n) =>
                n != 'Transferencia' && !disabledDefaults.contains(n));
            final allNames = <String>{
              ...visibleDefaults,
              ...customNames,
              widget.selectedCategory,
            }.toList();
            final orderedNames = [
              widget.selectedCategory,
              ...allNames.where((c) => c != widget.selectedCategory),
            ];
            final collapsedCount = compact ? 8 : 5;
            final hasMore = orderedNames.length > collapsedCount;
            final visibleNames = _showAll
                ? orderedNames
                : orderedNames.take(collapsedCount).toList();

            Widget compactTile({
              required Widget icon,
              required String label,
              required bool isSelected,
              required Color color,
              required VoidCallback onTap,
            }) {
              return HoverBuilder(
                builder: (context, hovered) => InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.fromLTRB(6, 6, 11, 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.navyFixed
                          : AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.navyFixed
                            : (hovered
                                ? AppTheme.outline
                                : AppTheme.surfaceContainerHigh),
                      ),
                      boxShadow: hovered && !isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    transform: hovered && !isSelected
                        ? Matrix4.translationValues(0, -1, 0)
                        : Matrix4.identity(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: icon,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          label,
                          style: GoogleFonts.beVietnamPro(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            Widget tile({
              required Widget icon,
              required String label,
              required bool isSelected,
              required Color color,
              required VoidCallback onTap,
            }) {
              if (compact) {
                return compactTile(
                  icon: icon,
                  label: label,
                  isSelected: isSelected,
                  color: color,
                  onTap: onTap,
                );
              }
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: SizedBox(
                  width: 68,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? null
                              : Border.all(color: color.withOpacity(0.25)),
                        ),
                        child: icon,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                compact
                    ? FormFieldLabel('Categoría', dense: true)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Categoría',
                          style: GoogleFonts.beVietnamPro(
                              color: AppTheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topLeft,
                  child: Wrap(
                    spacing: compact ? 8 : 12,
                    runSpacing: compact ? 8 : 14,
                    children: [
                      for (final name in visibleNames)
                        tile(
                          // En compacto el fondo del ícono siempre es un
                          // color sólido, así que el ícono va blanco encima
                          // sin importar la selección; en la tarjeta grande
                          // el fondo es translúcido cuando no está elegida.
                          icon: Icon(
                            CategoryIconRegistry.iconFor(name),
                            color: (widget.selectedCategory == name || compact)
                                ? Colors.white
                                : CategoryColors.forCategory(name),
                            size: compact ? 13 : 22,
                          ),
                          label: name,
                          isSelected: widget.selectedCategory == name,
                          color: CategoryColors.forCategory(name),
                          onTap: () => widget.onChanged(name),
                        ),
                      if (hasMore)
                        tile(
                          icon: AnimatedRotation(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            turns: _showAll ? 0.5 : 0,
                            child: Icon(Icons.expand_more_rounded,
                                color: compact
                                    ? Colors.white
                                    : AppTheme.onSurfaceVariant,
                                size: compact ? 13 : 22),
                          ),
                          label: _showAll ? 'Ver menos' : 'Ver todas',
                          isSelected: false,
                          color: AppTheme.outline,
                          onTap: () => setState(() => _showAll = !_showAll),
                        ),
                    ],
                  ),
                ),
                if (widget.showQuickLinks) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 18,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Builder(builder: (context) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final userId =
                                FirebaseAuth.instance.currentUser?.uid ?? '';
                            final created = await showAddCategorySheet(
                              context,
                              userId: userId,
                              existingNames: {...orderedNames, ...customNames},
                            );
                            if (created != null) widget.onChanged(created);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline_rounded,
                                    size: 15, color: AppTheme.secondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Agregar categoría',
                                  style: GoogleFonts.beVietnamPro(
                                    color: AppTheme.secondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      Builder(builder: (context) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => openCategoriesScreen(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tune_rounded,
                                    size: 15, color: AppTheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  'Mis categorías',
                                  style: GoogleFonts.beVietnamPro(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
