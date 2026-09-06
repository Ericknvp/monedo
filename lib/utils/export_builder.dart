import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction.dart';
import 'currency_formatter.dart';

const _brandPrimary = PdfColor.fromInt(0xFF001F2D);
const _brandSecondary = PdfColor.fromInt(0xFF006C4B);

String _dateStr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Genera un archivo .xlsx con los movimientos dados, ordenados por fecha
/// descendente, con un resumen de ingresos/gastos al final.
Uint8List buildExcelBytes(List<TransactionModel> transactions) {
  final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
  final workbook = xls.Excel.createExcel();
  final defaultSheetName = workbook.getDefaultSheet()!;
  final sheet = workbook[defaultSheetName];

  sheet.appendRow([
    xls.TextCellValue('Fecha'),
    xls.TextCellValue('Título'),
    xls.TextCellValue('Categoría'),
    xls.TextCellValue('Tipo'),
    xls.TextCellValue('Monto'),
    xls.TextCellValue('Nota'),
  ]);

  double income = 0;
  double expenses = 0;
  for (final t in sorted) {
    if (t.isIncome) {
      income += t.amount;
    } else {
      expenses += t.amount;
    }
    sheet.appendRow([
      xls.TextCellValue(_dateStr(t.date)),
      xls.TextCellValue(t.title),
      xls.TextCellValue(t.category),
      xls.TextCellValue(t.isIncome ? 'Ingreso' : 'Gasto'),
      xls.DoubleCellValue(t.amount),
      xls.TextCellValue(t.note ?? ''),
    ]);
  }

  sheet.appendRow([xls.TextCellValue('')]);
  sheet.appendRow([
    xls.TextCellValue('Total ingresos'),
    xls.TextCellValue(CurrencyFormatter.format(income)),
  ]);
  sheet.appendRow([
    xls.TextCellValue('Total gastos'),
    xls.TextCellValue(CurrencyFormatter.format(expenses)),
  ]);
  sheet.appendRow([
    xls.TextCellValue('Balance'),
    xls.TextCellValue(CurrencyFormatter.format(income - expenses)),
  ]);

  final bytes = workbook.encode()!;
  return Uint8List.fromList(bytes);
}

/// Genera un PDF con el reporte de movimientos para el período indicado.
Future<Uint8List> buildPdfBytes({
  required List<TransactionModel> transactions,
  required String periodLabel,
}) async {
  final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
  final income =
      sorted.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
  final expenses =
      sorted.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

  final logoBytes = await rootBundle.load('assets/images/logomonedo_new.png');
  final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logo, width: 32, height: 32),
              pw.SizedBox(width: 10),
              pw.Text('Monedo',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _brandPrimary,
                  )),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text('Reporte de movimientos · $periodLabel',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),
          pw.Container(height: 2, color: _brandSecondary),
          pw.SizedBox(height: 14),
        ],
      ),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Generado con Monedo · Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ),
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Ingresos: ${CurrencyFormatter.format(income)}',
                style: pw.TextStyle(
                    color: _brandSecondary, fontWeight: pw.FontWeight.bold)),
            pw.Text('Gastos: ${CurrencyFormatter.format(expenses)}',
                style: const pw.TextStyle(color: PdfColors.red800)),
            pw.Text(
                'Balance: ${CurrencyFormatter.format(income - expenses)}',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: _brandPrimary)),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: ['Fecha', 'Título', 'Categoría', 'Tipo', 'Monto'],
          data: sorted
              .map((t) => [
                    _dateStr(t.date),
                    t.title,
                    t.category,
                    t.isIncome ? 'Ingreso' : 'Gasto',
                    CurrencyFormatter.format(t.amount),
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: {
            0: const pw.FlexColumnWidth(1.4),
            1: const pw.FlexColumnWidth(2.6),
            2: const pw.FlexColumnWidth(1.8),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.4),
          },
        ),
      ],
    ),
  );

  return doc.save();
}
