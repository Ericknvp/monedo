import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Selector de fecha propio (calendario mensual), con el mismo lenguaje
/// visual del resto de la app: reemplaza el `showDatePicker` nativo de
/// Material, que está en inglés y no combina con el tema de Monedo.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => _AppDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _AppDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _AppDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<_AppDatePickerDialog> {
  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  late DateTime _displayedMonth;
  late DateTime _selected;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool _inRange(DateTime d) =>
      !d.isBefore(_dateOnly(widget.firstDate)) &&
      !d.isAfter(_dateOnly(widget.lastDate));

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _selected = _dateOnly(widget.initialDate);
    _displayedMonth = DateTime(_selected.year, _selected.month, 1);
  }

  bool get _canGoPrevMonth {
    final prevMonthEnd =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1)
            .subtract(const Duration(days: 1));
    return !prevMonthEnd.isBefore(_dateOnly(widget.firstDate));
  }

  bool get _canGoNextMonth {
    final nextMonthStart =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    return !nextMonthStart.isAfter(_dateOnly(widget.lastDate));
  }

  void _prevMonth() => setState(() => _displayedMonth =
      DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1));

  void _nextMonth() => setState(() => _displayedMonth =
      DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1));

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = _displayedMonth.weekday; // 1 = lunes ... 7 = domingo
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona una fecha',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_months[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _canGoPrevMonth ? _prevMonth : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppTheme.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: _canGoNextMonth ? _nextMonth : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: AppTheme.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: _weekdayLabels
                    .map((l) => Expanded(
                          child: Center(
                            child: Text(
                              l,
                              style: GoogleFonts.beVietnamPro(
                                color: AppTheme.outline,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 4),
              for (var r = 0; r < rows; r++)
                Row(
                  children: List.generate(7, (c) {
                    final cellIndex = r * 7 + c;
                    final day = cellIndex - leadingBlanks + 1;
                    if (day < 1 || day > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 40));
                    }
                    final date = DateTime(
                        _displayedMonth.year, _displayedMonth.month, day);
                    final isSelected = date == _selected;
                    final isToday = date == _today;
                    final enabled = _inRange(date);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Material(
                            color: isSelected
                                ? AppTheme.secondary
                                : Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: enabled
                                  ? () => setState(() => _selected = date)
                                  : null,
                              child: Center(
                                child: Container(
                                  decoration: isToday && !isSelected
                                      ? BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppTheme.secondary,
                                              width: 1.4),
                                        )
                                      : null,
                                  padding: EdgeInsets.all(
                                      isToday && !isSelected ? 6 : 8),
                                  child: Text(
                                    '$day',
                                    style: GoogleFonts.beVietnamPro(
                                      color: isSelected
                                          ? Colors.white
                                          : (enabled
                                              ? AppTheme.primary
                                              : AppTheme.outlineVariant),
                                      fontSize: 13.5,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar',
                        style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
