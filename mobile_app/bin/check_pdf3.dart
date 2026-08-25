import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  final regBytes = File('assets/fonts/tajawal_regular.ttf').readAsBytesSync();
  final boldBytes = File('assets/fonts/tajawal_bold.ttf').readAsBytesSync();
  final regular = pw.Font.ttf(ByteData.sublistView(regBytes));
  final bold = pw.Font.ttf(ByteData.sublistView(boldBytes));
  final pdf = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
  final rows = <Map<String, dynamic>>[
    {'employee_number':'admin','full_name':'???? ??????','department':'???????','check_in_time':'2026-08-25T08:05:00','check_out_time':'2026-08-25T16:10:00','trust_status':'valid','overtime_hours':0},
  ];
  pdf.addPage(pw.MultiPage(
    textDirection: pw.TextDirection.rtl,
    build: (c) => [
      pw.TableHelper.fromTextArray(
        headers: const ['??? ??????','?????','?????','??????','??????','???? ?????','????? ?????'],
        data: rows.map((r) => ['${r['employee_number']}','${r['full_name']}','${r['department']}','x','y','${r['trust_status']}','${r['overtime_hours']}']).toList(),
        cellStyle: pw.TextStyle(font: regular, fontSize: 10),
        headerStyle: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
        tableDirection: pw.TextDirection.rtl,
        headerDirection: pw.TextDirection.rtl,
        border: pw.TableBorder.all(color: PdfColors.grey400),
        cellAlignment: pw.Alignment.center,
      ),
    ],
  ));
  final bytes = await pdf.save();
  print('PDF bytes: ${bytes.length}');
}
