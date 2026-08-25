import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const String _companyAr = 'شركة مياه اليرموك';
const String _companyEn = 'Yarmouk Water Company';

Future<Uint8List> buildAttendancePdf({
  required String title,
  required String period,
  required List<dynamic> rows,
  List<dynamic>? incentiveRows,
  pw.Font? regularFont,
  pw.Font? boldFont,
}) async {
  final regular =
      regularFont ?? pw.Font.ttf(await rootBundle.load('assets/fonts/tajawal_regular.ttf'));
  final bold =
      boldFont ?? pw.Font.ttf(await rootBundle.load('assets/fonts/tajawal_bold.ttf'));

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  pdf.addPage(
    pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      build: (context) => [
        pw.Center(child: pw.Text(_companyAr, style: pw.TextStyle(font: bold, fontSize: 20))),
        pw.Center(
          child: pw.Text(_companyEn,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
        ),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text('$title  —  $period',
              style: pw.TextStyle(font: bold, fontSize: 14)),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: const [
            'رقم الموظف',
            'الاسم',
            'القسم',
            'الدخول',
            'الخروج',
            'حالة الثقة',
            'ساعات إضافي',
          ],
          data: rows
              .map((r) => [
                    '${r['employee_number']}',
                    '${r['full_name']}',
                    '${r['department']}',
                    _fmt(r['check_in_time']),
                    _fmt(r['check_out_time']),
                    '${r['trust_status']}',
                    '${r['overtime_hours']}',
                  ])
              .toList(),
          cellStyle: pw.TextStyle(font: regular, fontSize: 10),
          headerStyle: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
          tableDirection: pw.TextDirection.rtl,
          headerDirection: pw.TextDirection.rtl,
          border: pw.TableBorder.all(color: PdfColors.grey400),
          cellAlignment: pw.Alignment.center,
        ),
        if (incentiveRows != null) ...[
          pw.SizedBox(height: 20),
          pw.Text('تقرير الحوافز',
              style: pw.TextStyle(font: bold, fontSize: 14)),
          pw.TableHelper.fromTextArray(
            headers: const [
              'رقم الموظف',
              'الفترة',
              'متوسط السرعة',
              'متوسط الدقة',
              'درجة الأداء',
              'قيمة الحافز',
              'الحالة',
            ],
            data: incentiveRows
                .map((r) => [
                      '${r['employee_id']}',
                      '${r['period_start']} → ${r['period_end']}',
                      '${r['avg_speed']}',
                      '${r['avg_accuracy']}',
                      '${r['performance_score']}',
                      '${r['incentive_amount'] ?? '-'}',
                      '${r['status']}',
                    ])
                .toList(),
            cellStyle: pw.TextStyle(font: regular, fontSize: 10),
            headerStyle: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            tableDirection: pw.TextDirection.rtl,
            headerDirection: pw.TextDirection.rtl,
            border: pw.TableBorder.all(color: PdfColors.grey400),
            cellAlignment: pw.Alignment.center,
          ),
        ],
        pw.SizedBox(height: 40),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('توقيع مدير الموارد البشرية: ______________________',
                style: pw.TextStyle(font: regular, fontSize: 11)),
            pw.Text('توقيع المدير العام: ______________________',
                style: pw.TextStyle(font: regular, fontSize: 11)),
          ],
        ),
      ],
    ),
  );

  return await pdf.save();
}

String _fmt(dynamic v) {
  if (v == null) return '-';
  final s = v.toString();
  if (s.contains('T')) {
    final clean = s.replaceFirst('T', ' ');
    return clean.length > 16 ? clean.substring(0, 16) : clean;
  }
  return s;
}
