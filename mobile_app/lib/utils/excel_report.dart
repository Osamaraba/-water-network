import 'package:excel/excel.dart';

const String _companyAr = 'شركة مياه اليرموك';

/// Builds a branded attendance Excel workbook.
/// [incentiveRows] (optional) adds a second sheet for the individual monthly report.
Excel buildAttendanceExcel({
  required String title,
  required String period,
  required List<dynamic> rows,
  List<dynamic>? incentiveRows,
}) {
  final excel = Excel.createExcel();
  excel.rename(excel.sheets.keys.first, 'الحضور والانصراف');
  final sheet = excel.sheets['الحضور والانصراف']!;
  sheet.isRTL = true;
  _writeAttendance(sheet, title, period, rows);

  if (incentiveRows != null) {
    excel.copy('الحضور والانصراف', 'الحوافز');
    final inc = excel.sheets['الحوافز']!;
    inc.isRTL = true;
    _writeIncentives(inc, title, period, incentiveRows);
  }
  return excel;
}

void _writeAttendance(Sheet sheet, String title, String period, List<dynamic> rows) {
  const cols = 7;
  _titleBlock(sheet, title, period, cols);

  final headers = [
    'رقم الموظف',
    'الاسم',
    'القسم',
    'وقت الدخول',
    'وقت الخروج',
    'حالة الثقة',
    'ساعات إضافي',
  ];
  for (var c = 0; c < cols; c++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
    cell.value = TextCellValue(headers[c]);
    cell.cellStyle = _headerStyle();
  }

  var r = 4;
  for (final row in rows) {
    final values = [
      '${row['employee_number']}',
      '${row['full_name']}',
      '${row['department']}',
      _fmt(row['check_in_time']),
      _fmt(row['check_out_time']),
      '${row['trust_status']}',
      '${row['overtime_hours']}',
    ];
    for (var c = 0; c < cols; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
      cell.value = TextCellValue(values[c]);
      cell.cellStyle = _cellStyle();
    }
    r++;
  }
  _signatures(sheet, r);
}

void _writeIncentives(Sheet sheet, String title, String period, List<dynamic> rows) {
  const cols = 7;
  _titleBlock(sheet, 'تقرير الحوافز - $title', period, cols);

  final headers = [
    'رقم الموظف',
    'الفترة',
    'متوسط السرعة',
    'متوسط الدقة',
    'درجة الأداء',
    'قيمة الحافز',
    'الحالة',
  ];
  for (var c = 0; c < cols; c++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
    cell.value = TextCellValue(headers[c]);
    cell.cellStyle = _headerStyle();
  }

  var r = 4;
  for (final row in rows) {
    final values = [
      '${row['employee_id']}',
      '${row['period_start']} → ${row['period_end']}',
      '${row['avg_speed']}',
      '${row['avg_accuracy']}',
      '${row['performance_score']}',
      '${row['incentive_amount'] ?? '-'}',
      '${row['status']}',
    ];
    for (var c = 0; c < cols; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
      cell.value = TextCellValue(values[c]);
      cell.cellStyle = _cellStyle();
    }
    r++;
  }
  _signatures(sheet, r);
}

void _titleBlock(Sheet sheet, String title, String period, int cols) {
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    CellIndex.indexByColumnRow(columnIndex: cols - 1, rowIndex: 0),
  );
  final c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
  c1.value = TextCellValue(_companyAr);
  c1.cellStyle = CellStyle(
    bold: true,
    fontSize: 18,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    fontFamily: 'Arial',
  );

  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
    CellIndex.indexByColumnRow(columnIndex: cols - 1, rowIndex: 1),
  );
  final c2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
  c2.value = TextCellValue('$title  —  $period');
  c2.cellStyle = CellStyle(
    bold: true,
    fontSize: 13,
    horizontalAlign: HorizontalAlign.Center,
    fontFamily: 'Arial',
  );
}

void _signatures(Sheet sheet, int afterRow) {
  final r1 = afterRow + 2;
  final r2 = afterRow + 3;
  final s1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r1));
  s1.value = TextCellValue('توقيع مدير الموارد البشرية: ______________________');
  s1.cellStyle = _cellStyle();
  final s2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r2));
  s2.value = TextCellValue('توقيع المدير العام: ______________________');
  s2.cellStyle = _cellStyle();
}

CellStyle _headerStyle() => CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      fontFamily: 'Arial',
      backgroundColorHex: ExcelColor.fromHexString('FF1F6FB2'),
      fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
    );

CellStyle _cellStyle() => CellStyle(
      fontSize: 10,
      fontFamily: 'Arial',
      horizontalAlign: HorizontalAlign.Center,
    );

String _fmt(dynamic v) {
  if (v == null) return '-';
  final s = v.toString();
  if (s.contains('T')) {
    final clean = s.replaceFirst('T', ' ');
    return clean.length > 16 ? clean.substring(0, 16) : clean;
  }
  return s;
}
