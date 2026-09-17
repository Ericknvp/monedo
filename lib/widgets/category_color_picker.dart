import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_color_service.dart';
import '../theme/app_theme.dart';
import '../utils/category_colors.dart';

/// Hoja para elegir el color de una categoría, de una paleta curada.
/// Funciona igual para categorías predeterminadas y propias: el color se
/// guarda por nombre de categoría, no por id.
///
/// Tocar un color solo lo previsualiza (en memoria, al instante) para poder
/// probar varios sin esperar a la base de datos en cada toque. El color solo
/// se guarda en Firestore una sola vez, cuando el usuario baja la pestaña
/// (al deslizarla, tocar fuera o volver atrás), con el último que haya
/// quedado seleccionado.
Future<void> showCategoryColorPicker(
  BuildContext context, {
  required String userId,
  required String category,
}) async {
  final service = CategoryColorService();
  final original = CategoryColors.forCategory(category);
  final originalIsDefault =
      CategoryColorRegistry.customColors.value[category] == null;

  Color selected = original;
  bool selectedIsDefault = originalIsDefault;

  void previewColor(Color? color) {
    final updated = Map<String, Color>.of(CategoryColorRegistry.customColors.value);
    if (color == null) {
      updated.remove(category);
    } else {
      updated[category] = color;
    }
    CategoryColorRegistry.customColors.value = updated;
  }

  await showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
              'Color de "$category"',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: CategoryColors.swatches.map((color) {
                final isSelected = !selectedIsDefault && color.value == selected.value;
                return InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () {
                    setState(() {
                      selected = color;
                      selectedIsDefault = false;
                    });
                    previewColor(color);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
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
                            color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: selectedIsDefault
                    ? null
                    : () {
                        setState(() {
                          selected = original;
                          selectedIsDefault = true;
                        });
                        previewColor(null);
                      },
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Restablecer color por defecto'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  final changed = selectedIsDefault != originalIsDefault ||
      (!selectedIsDefault && selected.value != original.value);
  if (!changed) return;

  if (selectedIsDefault) {
    await service.resetColor(userId: userId, category: category);
  } else {
    await service.setColor(userId: userId, category: category, color: selected);
  }
}
