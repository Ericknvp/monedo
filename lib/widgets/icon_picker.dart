import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/category_icons.dart';

Future<IconData?> showIconPicker(BuildContext context, {IconData? selected}) {
  return showModalBottomSheet<IconData>(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _IconPickerSheet(selected: selected),
  );
}

class _IconPickerSheet extends StatefulWidget {
  final IconData? selected;
  const _IconPickerSheet({this.selected});

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? kCategoryIconChoices
        : kCategoryIconChoices
            .where((e) => e.key.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elige un ícono',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      autofocus: false,
                      onChanged: (v) => setState(() => _query = v),
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.primary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar ícono (ej: comida, viaje...)',
                        hintStyle: GoogleFonts.beVietnamPro(
                            color: AppTheme.outline, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.onSurfaceVariant, size: 20),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Sin resultados',
                          style: GoogleFonts.beVietnamPro(
                              color: AppTheme.onSurfaceVariant),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final entry = filtered[i];
                          final isSelected =
                              widget.selected?.codePoint == entry.value.codePoint;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(context, entry.value),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.secondary
                                        : AppTheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: AppTheme.outlineVariant),
                                  ),
                                  child: Icon(
                                    entry.value,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.onSurfaceVariant,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.key,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 9.5,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
